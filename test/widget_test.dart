// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glow_ai/app.dart';
import 'package:glow_ai/models/profile.dart';
import 'package:glow_ai/services/fallback_recommendation_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('GlowAI opens the home experience', (WidgetTester tester) async {
    await tester.pumpWidget(const GlowApp());
    await tester.pumpAndSettle();
    expect(find.text('Glow'), findsOneWidget);
    expect(find.text('AI recommendations'), findsOneWidget);
  });

  test('fallback catalogue creates deterministic profile variations', () {
    const service = FallbackRecommendationService();
    final first = Profile()
      ..event = 'eid'
      ..undertone = 'warm'
      ..skinTone = 'medium';
    final second = Profile()
      ..event = 'party'
      ..undertone = 'cool'
      ..skinTone = 'deep'
      ..time = 'night'
      ..style = 'western';
    final firstResult = service.create(first);
    final secondResult = service.create(second);
    expect(firstResult.overall, isNot(secondResult.overall));
    expect(
      firstResult.sections['lips']!['hex'],
      isNot(secondResult.sections['lips']!['hex']),
    );
    expect(firstResult.sections, hasLength(9));
  });
  test('every selectable occasion produces an appropriate complete look', () {
    const service = FallbackRecommendationService();
    for (final event in [
      'wedding',
      'mehndi',
      'dholki',
      'eid',
      'valima',
      'everyday',
      'university',
      'office',
      'shopping',
      'party',
      'date',
      'photoshoot',
      'festival',
    ]) {
      final result = service.create(Profile()..event = event);
      expect(result.sections, hasLength(9));
      expect(result.overall.toLowerCase(), contains(event));
      expect(
        result.sections.values.every((section) => section.isNotEmpty),
        isTrue,
      );
    }
  });
}
