import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pacman/core/monetization/age_gate.dart';

void main() {
  for (final entry in {
    'Under 16': AgeGroup.under16,
    '16–17': AgeGroup.teen,
    '18 or older': AgeGroup.adult,
  }.entries) {
    testWidgets('neutral choice ${entry.key} is persisted before play', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      AgeGroup? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: AgeGate(
            onSelected: (group) => selected = group,
            child: const Text('game'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(find.text('game'), findsNothing);
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(selected, entry.value);
      expect(find.text('game'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getString('age_group'),
        entry.value.name,
      );
    });
  }
  testWidgets('saved younger-user choice skips prompt without changing band', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'age_group': 'under16'});
    AgeGroup? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: AgeGate(
          onSelected: (group) => selected = group,
          child: const Text('game'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(selected, AgeGroup.under16);
    expect(find.text('Your age group'), findsNothing);
  });
}
