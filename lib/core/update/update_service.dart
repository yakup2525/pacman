import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.wolftrail.ghost_runner';
const privacyPolicyUrl = 'https://wolftrailstudio.com/privacy/ghost-runner/';
const updatePolicyUrl = 'https://wolftrailstudio.com/updates/ghost-runner.json';

/// Numeric Android build codes are monotonic and avoid version-string ambiguity.
int parseMinimum(String source) {
  final data = jsonDecode(source) as Map<String, dynamic>;
  if (data['package'] != 'com.wolftrail.ghost_runner' ||
      data['minimumVersionCode'] is! int ||
      data['minimumVersionCode'] < 1) {
    throw const FormatException('Invalid Ghost Runner update policy');
  }
  return data['minimumVersionCode'] as int;
}

bool requiresUpdate(int installed, int minimum) => installed < minimum;

class UpdateService extends ChangeNotifier {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _cacheKey = 'ghost_runner_minimum_build';
  bool checking = true;
  bool mandatory = false;
  bool unavailable = false;
  int? _installed;
  int _minimum = 1;
  Future<void>? _pending;

  Future<void> check() =>
      _pending ??= _check().whenComplete(() => _pending = null);

  Future<void> _check() async {
    try {
      _installed ??= int.tryParse(
        (await PackageInfo.fromPlatform()).buildNumber,
      );
      final prefs = await SharedPreferences.getInstance();
      _minimum = prefs.getInt(_cacheKey) ?? _minimum;
      mandatory = _installed != null && requiresUpdate(_installed!, _minimum);
      notifyListeners();
      final response = await _client
          .get(Uri.parse(updatePolicyUrl))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) {
        throw const FormatException('Policy unavailable');
      }
      final minimum = parseMinimum(response.body);
      _minimum = minimum;
      await prefs.setInt(_cacheKey, minimum);
      mandatory = _installed != null && requiresUpdate(_installed!, minimum);
      unavailable = false;
    } catch (_) {
      // Retain a previously verified minimum offline. A first offline launch
      // without a cached policy is allowed; an unknown policy cannot be enforced.
      unavailable = true;
    } finally {
      checking = false;
      notifyListeners();
    }
  }
}
