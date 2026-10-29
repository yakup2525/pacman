import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_pacing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MonetizationService extends ChangeNotifier {
  static final instance = MonetizationService();
  final pacing = AdPacing();
  // Non-release modes always use Google's official Android interstitial unit.
  static const _unit = kReleaseMode
      ? 'ca-app-pub-9384489712257906/4889485627'
      : 'ca-app-pub-3940256099942544/1033173712';
  InterstitialAd? _ad;
  DateTime? _loadedAt;
  bool _loading = false;
  bool _initialized = false;
  bool _consentBusy = false;
  bool _allowed = false;
  bool fullscreen = false;
  bool privacyRequired = false;
  bool foreground = true;
  bool _blocked = false;
  set blocked(bool value) {
    _blocked = value;
    if (value) _invalidateAds();
  }

  void _invalidateAds() {
    _adGeneration++;
    _allowed = false;
    _ad?.dispose();
    _ad = null;
    _loadedAt = null;
  }

  bool privacyUiActive = false;
  bool _historyLoaded = false;
  bool _legacyAgeCleared = false;
  int _consentGeneration = 0;
  int _adGeneration = 0;

  void _privacyUi(bool active) {
    privacyUiActive = active;
    notifyListeners();
  }

  Future<void> _restoreHistory() async {
    if (_historyLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    pacing.impressions.addAll(
      (prefs.getStringList('ad_impressions') ?? [])
          .map(DateTime.tryParse)
          .whereType<DateTime>()
          .where((t) => now.difference(t) < const Duration(hours: 1)),
    );
    if (pacing.impressions.isNotEmpty) {
      pacing.lastShown = pacing.impressions.last;
    }
    _historyLoaded = true;
  }

  Future<void> _recordImpression() async {
    pacing.record(DateTime.now());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'ad_impressions',
        pacing.impressions
            .where(
              (t) => DateTime.now().difference(t) < const Duration(hours: 1),
            )
            .map((t) => t.toIso8601String())
            .toList(),
      );
    } catch (_) {
      /* Session caps still apply if storage fails. */
    }
  }

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> start() async {
    if (!supported || _blocked || !foreground || _consentBusy || fullscreen) {
      return;
    }
    _consentBusy = true;
    // Discard legacy local age routing; this release does not ask or store age.
    if (!_legacyAgeCleared) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('age_group');
        _legacyAgeCleared = true;
      } catch (_) {
        // Storage failure never blocks gameplay or regional consent.
      }
    }
    _invalidateAds();
    final generation = ++_consentGeneration;
    // An unanswered network request cannot disable ads/retries forever.
    Timer(const Duration(seconds: 15), () {
      if (_consentGeneration == generation && !privacyUiActive) {
        _consentGeneration++;
        _consentBusy = false;
      }
    });
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          if (generation != _consentGeneration) return;
          if (!foreground || _blocked) {
            _consentBusy = false;
            return;
          }
          _consentBusy = true;
          _privacyUi(true);
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((error) async {
              if (generation != _consentGeneration) return;
              _privacyUi(false);
              await _refresh(generation);
              if (generation != _consentGeneration) return;
              _consentBusy = false;
              preload();
            });
          } catch (_) {
            if (generation != _consentGeneration) return;
            _privacyUi(false);
            await _refresh(generation);
            _consentBusy = false;
            preload();
          }
        },
        (_) async {
          if (generation != _consentGeneration) return;
          await _refresh(generation);
          if (generation != _consentGeneration) return;
          _consentBusy = false;
          preload();
        },
      );
    } catch (_) {
      _consentBusy = false;
    }
  }

  Future<void> _refresh(int generation) async {
    bool current() => generation == _consentGeneration;
    try {
      if (!current()) return;
      final requirement =
          await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      final allowed = await ConsentInformation.instance.canRequestAds();
      if (!current()) return;
      privacyRequired = requirement;
      notifyListeners();
      if (!allowed || _blocked) {
        _ad?.dispose();
        _ad = null;
        return;
      }
      await _restoreHistory();
      if (!current() || _blocked || !foreground) return;
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.g,
          ageRestrictedTreatment: AgeRestrictedTreatment.unspecified,
        ),
      );
      if (!current() || _blocked || !foreground) return;
      if (!_initialized) {
        await MobileAds.instance.initialize();
        _initialized = true;
      }
      if (current() && !_blocked) _allowed = true;
    } catch (_) {
      // Consent/network failures never prevent playing.
      if (current()) _invalidateAds();
    }
  }

  Future<bool> privacyChoices() async {
    if (!supported || fullscreen || _consentBusy || !foreground) {
      return false;
    }
    _consentBusy = true;
    final generation = ++_consentGeneration;
    _invalidateAds();
    _privacyUi(true);
    final done = Completer<bool>();
    try {
      unawaited(
        ConsentForm.showPrivacyOptionsForm((error) async {
          if (generation != _consentGeneration) return;
          _privacyUi(false);
          await _refresh(generation);
          if (generation != _consentGeneration) return;
          _consentBusy = false;
          preload();
          if (!done.isCompleted) done.complete(error == null);
        }).catchError((Object error) {
          if (generation == _consentGeneration) {
            _consentBusy = false;
            _privacyUi(false);
          }
          if (!done.isCompleted) done.complete(false);
        }),
      );
      return await done.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          // A timeout cannot prove that native UI has closed. Keep ads and
          // subsequent forms blocked until its actual dismissal callback.
          return false;
        },
      );
    } catch (_) {
      _consentBusy = false;
      _privacyUi(false);
      return false;
    }
  }

  void retryConsentIfNeeded() {
    if (!_allowed && !_consentBusy) start();
  }

  void preload() {
    if (!_initialized ||
        _blocked ||
        !_allowed ||
        _consentBusy ||
        _loading ||
        _ad != null ||
        !foreground) {
      return;
    }
    _loading = true;
    final generation = _adGeneration;
    try {
      InterstitialAd.load(
        adUnitId: _unit,
        request: const AdRequest(nonPersonalizedAds: true),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loading = false;
            if (generation != _adGeneration ||
                _blocked ||
                !_allowed ||
                _consentBusy) {
              ad.dispose();
              return;
            }
            _ad = ad;
            _loadedAt = DateTime.now();
          },
          onAdFailedToLoad: (_) {
            _loading = false;
          },
        ),
      );
    } catch (_) {
      _loading = false;
    }
  }

  /// Called only by the restart action, while gameplay timers are stopped.
  Future<void> postRun(Duration active) async {
    pacing.completeRun(active);
    final now = DateTime.now();
    if (_loadedAt != null &&
        now.difference(_loadedAt!) >= const Duration(minutes: 55)) {
      _ad?.dispose();
      _ad = null;
    }
    final ad = _ad;
    if (!foreground ||
        fullscreen ||
        _consentBusy ||
        !_allowed ||
        ad == null ||
        !pacing.eligible(now)) {
      preload();
      return;
    }
    final generation = _adGeneration;
    // Re-check SDK permission immediately before showing a previously loaded ad.
    if (!await ConsentInformation.instance.canRequestAds() ||
        generation != _adGeneration ||
        !identical(ad, _ad) ||
        _blocked ||
        !_allowed ||
        _consentBusy ||
        !foreground ||
        fullscreen) {
      return;
    }
    fullscreen = true;
    _ad = null;
    final done = Completer<void>();
    var recorded = false;
    void finish() {
      if (done.isCompleted) return;
      ad.dispose();
      fullscreen = false;
      if (!done.isCompleted) done.complete();
      preload();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        if (!recorded) {
          recorded = true;
          unawaited(_recordImpression());
        }
      },
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, _) => finish(),
    );
    try {
      await ad.show();
    } catch (_) {
      finish();
    }
    await done.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () {
        // Broken SDK callbacks must not deadlock navigation. Disable further ads
        // for this process after an ambiguous fullscreen result.
        _allowed = false;
        finish();
      },
    );
  }
}
