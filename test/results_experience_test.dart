import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow_ai/features/results/results_screen.dart';
import 'package:glow_ai/models/profile.dart';
import 'package:glow_ai/services/fallback_recommendation_service.dart';
import 'flow_checks.dart';

void main() {
  final look = const FallbackRecommendationService().create(
    Profile()..event = 'eid',
  );
  testWidgets(
    'makeup essentials come first and optional categories require opening more',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Results(result: look, onStudio: () {}, onCreateAnother: () {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lips'), findsOneWidget);
      expect(find.text('Accessories'), findsNothing);
      expect(find.text(look.sections['lips']!['finish']!), findsNothing);
      await tapLabel(tester, 'Lips');
      expect(find.text(look.sections['lips']!['finish']!), findsOneWidget);
      await tapLabel(tester, 'See more categories');
      expect(find.text('More styling ideas'), findsOneWidget);
      expect(
        find.text(look.sections['accessories']!['jewellery']!),
        findsNothing,
      );
      await tapLabel(tester, 'Accessories');
      expect(
        find.text(look.sections['accessories']!['jewellery']!),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Your beauty edit'), findsOneWidget);
      expect(find.text(look.sections['lips']!['finish']!), findsOneWidget);
    },
  );
  testWidgets('primary preview action is available on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Results(
          result: look,
          onStudio: () => opened = true,
          onCreateAnother: () {},
        ),
      ),
    );
    await tapLabel(tester, 'Try this look');
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });
}
