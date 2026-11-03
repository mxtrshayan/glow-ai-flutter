import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:glow_ai/features/studio/studio_screen.dart';
import 'package:glow_ai/services/face_detection_service.dart';
import '../test/flow_checks.dart';
import 'portrait_fixture.dart';
import 'package:glow_ai/models/recommendation.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native consultation and session lifecycle', checkConsultation);
  testWidgets('native ML Kit portrait detection and studio rendering', (
    tester,
  ) async {
    final path = await portraitFixture();
    expect(await File(path).exists(), isTrue);
    final face = await FaceDetectionService().detect(path);
    expect(face, isNotNull);
    expect(
      face!.contours.keys,
      containsAll(['leftEye', 'rightEye', 'upperLipTop', 'lowerLipBottom']),
    );
    final previewKey = GlobalKey();
    final makeup = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is MakeupPainter,
    );
    await tester.pumpWidget(
      RepaintBoundary(
        key: previewKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Poppins'),
          home: Studio(
            photo: XFile(path),
            onPhoto: (_) {},
            recommendation: const Recommendation({
              'lips': {'hex': '#8B1E3F'},
              'face': {
                'blush_hex': '#D4707F',
                'highlight': 'Champagne highlight',
              },
              'eyes': {
                'eyeshadow_hex': '#9E784F',
                'eyeliner': 'Soft definition',
                'mascara': 'Black mascara',
              },
            }, 'Test recommendation'),
          ),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (makeup.evaluate().isNotEmpty) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(makeup, findsOneWidget);
    final applied =
        tester.widget<CustomPaint>(makeup).painter! as MakeupPainter;
    expect(applied.lipColor, const Color(0xFF8B1E3F));
    expect(applied.blushColor, const Color(0xFFD4707F));
    expect(applied.eyeColor, const Color(0xFF9E784F));
    expect(applied.eyeliner, isTrue);
    expect(applied.mascara, isTrue);
    expect(applied.highlighter, isTrue);
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is MakeupPainter,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    final boundary =
        previewKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final screenshot = await boundary.toImage(pixelRatio: 2);
    final png = await screenshot.toByteData(format: ui.ImageByteFormat.png);
    await File(
      Platform.isIOS
          ? '/tmp/glow-native-studio.png'
          : '${Directory.systemTemp.path}/glow-native-studio.png',
    ).writeAsBytes(png!.buffer.asUint8List());
    screenshot.dispose();

    // Exercise the real native detector on a blank image and a group portrait.
    final codec = await ui.instantiateImageCodec(
      await File(path).readAsBytes(),
    );
    final source = (await codec.getNextFrame()).image;
    final dir = await Directory.systemTemp.createTemp('glow-detection-test');
    try {
      for (final group in [false, true]) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawColor(Colors.white, BlendMode.src);
        if (group) {
          canvas.drawImage(source, Offset.zero, Paint());
          canvas.drawImage(source, Offset(source.width.toDouble(), 0), Paint());
        }
        final picture = recorder.endRecording();
        final image = await picture.toImage(source.width * 2, source.height);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('${dir.path}/${group ? 'group' : 'blank'}.png');
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        expect(await FaceDetectionService().detect(file.path), isNull);
        picture.dispose();
        image.dispose();
      }
    } finally {
      source.dispose();
      codec.dispose();
      await dir.delete(recursive: true);
    }
  });
}
