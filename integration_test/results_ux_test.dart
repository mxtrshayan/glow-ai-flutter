import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:glow_ai/features/results/results_screen.dart';
import 'package:glow_ai/models/profile.dart';
import 'package:glow_ai/services/fallback_recommendation_service.dart';
import '../test/flow_checks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('essentials and optional categories on a native phone', (
    tester,
  ) async {
    final boundaryKey = GlobalKey();
    final result = const FallbackRecommendationService().create(
      Profile()..event = 'eid',
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Poppins',
            scaffoldBackgroundColor: const Color(0xFFFDF6F9),
          ),
          home: Results(
            result: result,
            onStudio: () {},
            onCreateAnother: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('/tmp/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    }

    expect(find.text('Accessories'), findsNothing);
    await capture('glow-results-essentials');
    await tapLabel(tester, 'See more categories');
    expect(find.text('More styling ideas'), findsOneWidget);
    await capture('glow-results-more');
    await tapLabel(tester, 'Accessories');
    expect(
      find.text(result.sections['accessories']!['jewellery']!),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
