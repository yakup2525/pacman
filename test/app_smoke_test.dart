import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pacman/main.dart';

void main() {
  testWidgets('game controls remain visible inside Android system insets',
      (tester) async {
    tester.view.physicalSize = const Size(1290, 2400);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = FakeViewPadding(top: 90, bottom: 72);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final play = find.text('P L A Y');
    expect(play, findsOneWidget);
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(tester.getRect(play).top, greaterThanOrEqualTo(30));
    expect(tester.getRect(play).bottom, lessThanOrEqualTo(776));
    expect(tester.takeException(), isNull);
  });
}
