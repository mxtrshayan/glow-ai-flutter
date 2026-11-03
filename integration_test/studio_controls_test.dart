import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:glow_ai/features/studio/studio_screen.dart';
import '../test/flow_checks.dart';
import 'portrait_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'effect toggles, intensity and full colour selection reach the native portrait preview',
    (tester) async {
      final path = await portraitFixture();
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'Poppins'),
            home: Studio(photo: XFile(path), onPhoto: (_) {}),
          ),
        ),
      );
      final painted = find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is MakeupPainter,
      );
      for (var i = 0; i < 60 && painted.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(painted, findsOneWidget);
      MakeupPainter current() =>
          tester.widget<CustomPaint>(painted).painter! as MakeupPainter;
      for (final label in ['Eyeliner', 'Mascara', 'Highlighter']) {
        final row = find
            .ancestor(of: find.text(label), matching: find.byType(Row))
            .first;
        final toggle = find.descendant(of: row, matching: find.byType(Switch));
        await tester.ensureVisible(toggle);
        await tester.pumpAndSettle();
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        final controls = find
            .ancestor(of: find.text(label), matching: find.byType(Column))
            .first;
        final slider = find.descendant(
          of: controls,
          matching: find.byType(Slider),
        );
        await tester.ensureVisible(slider);
        await tester.pumpAndSettle();
        await tester.drag(slider, const Offset(50, 0));
        await tester.pumpAndSettle();
      }
      expect(current().eyeliner, isTrue);
      expect(current().mascara, isTrue);
      expect(current().highlighter, isTrue);
      expect(current().eyelinerIntensity, greaterThan(.55));
      expect(current().mascaraIntensity, greaterThan(.55));
      expect(current().highlighterIntensity, greaterThan(.55));
      await tapLabel(tester, 'Choose any mascara colour');
      await tester.enterText(
        find.byKey(const ValueKey('colour-hex')),
        '12ABEF',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapLabel(tester, 'Apply colour');
      expect(current().mascaraColor, const Color(0xFF12ABEF));
      final image =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        Platform.isIOS
            ? '/tmp/glow-controls-preview.png'
            : '${Directory.systemTemp.path}/glow-controls-preview.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
