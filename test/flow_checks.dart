import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow_ai/app.dart';

Future<void> tapLabel(WidgetTester tester, String text) async {
  await tester.pumpAndSettle();
  final target = find.text(text);
  if (target.evaluate().isEmpty) {
    final scrollable = find.byType(Scrollable).last;
    final state = tester.state<ScrollableState>(scrollable);
    state.position.jumpTo(state.position.minScrollExtent);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      target,
      180,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> chooseOption(WidgetTester tester, String key, String label) async {
  final target = find.byKey(ValueKey('choice-$key'));
  if (target.evaluate().isEmpty) {
    final scrollable = find.byType(Scrollable).last;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(target, 120, scrollable: scrollable);
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
  await tapLabel(tester, label);
}

Future<void> checkConsultation(WidgetTester tester) async {
  await tester.pumpWidget(const GlowApp());
  await tester.pumpAndSettle();
  await tapLabel(tester, 'AI recommendations');
  await tapLabel(tester, 'Continue without photo');
  await tapLabel(tester, 'Continue');
  expect(
    find.text('Choose a skin tone, or go back and add a photo.'),
    findsOneWidget,
  );
  await chooseOption(tester, 'skinTone', 'Medium / Wheatish');
  await tapLabel(tester, 'Continue');
  await tapLabel(tester, 'Continue');
  expect(find.text('Choose an occasion to continue.'), findsOneWidget);
  await chooseOption(tester, 'event', 'Eid');
  await tapLabel(tester, 'Continue');
  await tapLabel(tester, 'Continue');
  await tapLabel(tester, 'Continue');
  await tester.enterText(find.byType(TextFormField), 'My rose lipstick');
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tapLabel(tester, 'Continue');
  await tapLabel(tester, 'Back');
  expect(find.text('My rose lipstick'), findsOneWidget);
  await tapLabel(tester, 'Continue');
  await tapLabel(tester, 'Create my look');
  expect(find.text('Your beauty edit'), findsOneWidget);
  await tapLabel(tester, 'Try this look');
  expect(find.text('Your portrait'), findsOneWidget);
  await tester.pageBack();
  await tester.pumpAndSettle();
  await tester.pageBack();
  await tester.pumpAndSettle();
  await tapLabel(tester, 'Revisit my current look');
  expect(find.text('Your beauty edit'), findsOneWidget);
  await tapLabel(tester, 'Create another look');
  expect(find.text('Create your look'), findsOneWidget);
  await tester.pageBack();
  await tester.pumpAndSettle();
  await tapLabel(tester, 'Settings');
  await tapLabel(tester, 'Privacy policy & about');
  await tester.pageBack();
  await tester.pumpAndSettle();
  await tapLabel(tester, 'Clear my data');
  await tapLabel(tester, 'Clear data');
  await tapLabel(tester, 'Home');
  expect(find.text('Revisit my current look'), findsNothing);
  expect(tester.takeException(), isNull);
}
