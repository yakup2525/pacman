import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pacman/core/monetization/ad_pacing.dart';
import 'package:pacman/core/update/update_gate.dart';
import 'package:pacman/core/update/update_service.dart';

void main() {
  test('interstitial grace, eligible runs, cooldown and session/hour caps', () {
    final pacing = AdPacing();
    final now = DateTime(2026, 10, 27, 12);
    pacing.completeRun(const Duration(seconds: 10));
    expect(pacing.eligibleRuns, 0);
    for (var i = 0; i < 3; i++) {
      pacing.completeRun(const Duration(seconds: 40));
    }
    expect(pacing.eligible(now), isTrue);
    pacing.record(now);
    expect(pacing.eligible(now), isFalse);
    for (var i = 0; i < 3; i++) {
      pacing.completeRun(const Duration(seconds: 40));
    }
    expect(pacing.eligible(now.add(const Duration(seconds: 179))), isFalse);
    expect(pacing.eligible(now.add(const Duration(minutes: 3))), isTrue);
    pacing.record(now.add(const Duration(minutes: 3)));
    for (var i = 0; i < 3; i++) {
      pacing.completeRun(const Duration(seconds: 40));
    }
    expect(pacing.eligible(now.add(const Duration(minutes: 6))), isFalse);
    expect(pacing.eligible(now.add(const Duration(hours: 1))), isTrue);
    pacing.rewardAt = now.add(const Duration(minutes: 59));
    expect(pacing.eligible(now.add(const Duration(hours: 1))), isFalse);
    pacing.record(now.add(const Duration(hours: 2)));
    for (var i = 0; i < 3; i++) {
      pacing.completeRun(const Duration(seconds: 40));
    }
    expect(pacing.eligible(now.add(const Duration(hours: 3))), isFalse);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Ghost Runner',
      packageName: 'com.wolftrail.ghost_runner',
      version: '1.1.4',
      buildNumber: '15',
      buildSignature: '',
    );
  });

  UpdateService serviceFor(int minimum) => UpdateService(
    client: MockClient(
      (_) async => http.Response(
        '{"package":"com.wolftrail.ghost_runner","minimumVersionCode":$minimum}',
        200,
      ),
    ),
  );

  test('minimum policy rejects malformed or wrong-package responses', () {
    expect(() => parseMinimum('{}'), throwsFormatException);
    expect(
      () => parseMinimum('{"package":"other","minimumVersionCode":16}'),
      throwsFormatException,
    );
    expect(
      () => parseMinimum(
        '{"package":"com.wolftrail.ghost_runner","minimumVersionCode":0}',
      ),
      throwsFormatException,
    );
  });

  test('below/equal/above minimum and canonical store link', () async {
    for (final minimum in [14, 15, 16]) {
      final service = serviceFor(minimum);
      await service.check();
      expect(service.mandatory, minimum == 16);
      service.dispose();
    }
    expect(
      Uri.parse(playStoreUrl).queryParameters['id'],
      'com.wolftrail.ghost_runner',
    );
  });

  test(
    'offline first launch allows play, cached mandatory survives failure',
    () async {
      final offline = UpdateService(
        client: MockClient((_) async => throw Exception('offline')),
      );
      await offline.check();
      expect(offline.mandatory, isFalse);
      expect(offline.checking, isFalse);
      final online = serviceFor(16);
      await online.check();
      await offline.check();
      expect(offline.mandatory, isTrue);
      expect(offline.unavailable, isTrue);
    },
  );

  testWidgets('mandatory gate blocks gameplay and system back', (tester) async {
    final service = serviceFor(16);
    await service.check();
    await tester.pumpWidget(
      MaterialApp(
        home: UpdateGate(service: service, child: const Text('gameplay')),
      ),
    );
    expect(find.text('gameplay'), findsNothing);
    expect(find.text('Update on Google Play'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Update on Google Play'), findsOneWidget);
    expect(find.text('gameplay'), findsNothing);
  });
}
