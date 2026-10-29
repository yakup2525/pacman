import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';
import 'package:pacman/core/monetization/monetization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeConsent extends ConsentInformation {
  final updates = <OnConsentInfoUpdateSuccessListener>[];
  Completer<bool>? permission;
  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener success,
    OnConsentInfoUpdateFailureListener failure,
  ) {
    expect(params.consentDebugSettings, isNull);
    expect(params.tagForUnderAgeOfConsent, isNull);
    updates.add(success);
  }

  @override
  Future<bool> canRequestAds() async => permission?.future ?? true;
  @override
  Future<PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async =>
      PrivacyOptionsRequirementStatus.required;
  @override
  Future<ConsentStatus> getConsentStatus() async => ConsentStatus.obtained;
  @override
  Future<bool> isConsentFormAvailable() async => true;
  @override
  Future<void> reset() async {}
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final original = ConsentInformation.instance;
  late FakeConsent consent;
  late List<MethodCall> ads;
  late List<MethodCall> ump;
  final adChannel = MethodChannel(
    'plugins.flutter.io/google_mobile_ads',
    StandardMethodCodec(AdMessageCodec()),
  );
  const umpChannel = MethodChannel('plugins.flutter.io/google_mobile_ads/ump');
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    consent = FakeConsent();
    ConsentInformation.instance = consent;
    ads = [];
    ump = [];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(adChannel, (
      call,
    ) async {
      ads.add(call);
      if (call.method == 'MobileAds#initialize') {
        return InitializationStatus({});
      }
      return null;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(umpChannel, (
      call,
    ) async {
      ump.add(call);
      return null;
    });
  });
  tearDown(() {
    ConsentInformation.instance = original;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(adChannel, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(umpChannel, null);
  });

  testWidgets('general requests retain G rating and NPA without stored age', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'age_group': 'under16'});
    final service = MonetizationService();
    await service.start();
    expect(
      (await SharedPreferences.getInstance()).containsKey('age_group'),
      isFalse,
    );
    consent.updates.single();
    await tester.pump();
    final load = ads.singleWhere((call) => call.method == 'loadInterstitialAd');
    expect((load.arguments['request'] as AdRequest).nonPersonalizedAds, isTrue);
    await tester.pump(const Duration(seconds: 16));
  });

  testWidgets('timed-out request cannot open form after a retry', (
    tester,
  ) async {
    final service = MonetizationService();
    await service.start();
    await tester.pump(const Duration(seconds: 16));
    service.retryConsentIfNeeded();
    await tester.pump();
    expect(consent.updates, hasLength(2));
    consent.updates.first();
    await tester.pump();
    expect(ump, isEmpty);
    consent.updates.last();
    await tester.pump();
    expect(ump, hasLength(1));
    final configuration = ads.singleWhere(
      (c) => c.method == 'MobileAds#updateRequestConfiguration',
    );
    expect(
      configuration.arguments['ageRestrictedTreatment'],
      AgeRestrictedTreatment.unspecified.index,
    );
    expect(configuration.arguments['maxAdContentRating'], MaxAdContentRating.g);
    final load = ads.singleWhere((c) => c.method == 'loadInterstitialAd');
    expect(
      load.arguments['adUnitId'],
      'ca-app-pub-3940256099942544/1033173712',
    );
    expect((load.arguments['request'] as AdRequest).nonPersonalizedAds, isTrue);
    await tester.pump(const Duration(seconds: 16));
  });

  testWidgets('background update response cannot display consent UI', (
    tester,
  ) async {
    final service = MonetizationService();
    await service.start();
    service.foreground = false;
    consent.updates.single();
    await tester.pump();
    expect(ump, isEmpty);
    expect(ads, isEmpty);
    service.foreground = true;
    service.retryConsentIfNeeded();
    await tester.pump();
    expect(consent.updates, hasLength(2));
    await tester.pump(const Duration(seconds: 16));
  });

  testWidgets(
    'mandatory update during permission check prevents initialization',
    (tester) async {
      final service = MonetizationService();
      consent.permission = Completer<bool>();
      await service.start();
      consent.updates.single();
      await tester.pump();
      service.blocked = true;
      consent.permission!.complete(true);
      await tester.pump();
      expect(ads, isEmpty);
      await tester.pump(const Duration(seconds: 16));
    },
  );
  testWidgets(
    'revoking privacy while final show permission is pending prevents fullscreen',
    (tester) async {
      final service = MonetizationService();
      await service.start();
      consent.updates.single();
      await tester.pump();
      final load = ads.singleWhere((c) => c.method == 'loadInterstitialAd');
      final ad =
          instanceManager.adFor(load.arguments['adId'])! as InterstitialAd;
      ad.adLoadCallback.onAdLoaded(ad);
      service.pacing.completeRun(const Duration(seconds: 40));
      service.pacing.completeRun(const Duration(seconds: 40));
      consent.permission = Completer<bool>();
      final restart = service.postRun(const Duration(seconds: 40));
      await tester.pump();
      final privacy = service.privacyChoices();
      await tester.pump();
      consent.permission!.complete(true);
      await tester.pump();
      await restart;
      await privacy;
      expect(ads.where((c) => c.method == 'showAdWithoutView'), isEmpty);
      expect(service.fullscreen, isFalse);
      await tester.pump(const Duration(seconds: 16));
    },
  );

  testWidgets(
    'an ad loaded before privacy revocation is discarded after callback',
    (tester) async {
      final service = MonetizationService();
      await service.start();
      consent.updates.single();
      await tester.pump();
      final load = ads.singleWhere((c) => c.method == 'loadInterstitialAd');
      final ad =
          instanceManager.adFor(load.arguments['adId'])! as InterstitialAd;
      service.blocked = true;
      ad.adLoadCallback.onAdLoaded(ad);
      await tester.pump();
      expect(ads.where((c) => c.method == 'disposeAd'), hasLength(1));
      expect(ads.where((c) => c.method == 'showAdWithoutView'), isEmpty);
      await tester.pump(const Duration(seconds: 16));
    },
  );
  testWidgets(
    'privacy timeout never unlocks another form while native UI may remain',
    (tester) async {
      final service = MonetizationService();
      await service.start();
      consent.updates.single();
      await tester.pump();
      final nativeDismissal = Completer<void>();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(umpChannel, (
        call,
      ) async {
        await nativeDismissal.future;
        return null;
      });
      final privacy = service.privacyChoices();
      await tester.pump();
      await tester.pump(const Duration(seconds: 61));
      expect(await privacy, isFalse);
      expect(service.privacyUiActive, isTrue);
      expect(await service.privacyChoices(), isFalse);
      nativeDismissal.complete();
      await tester.pump();
      expect(service.privacyUiActive, isFalse);
    },
  );
}
