import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glow_ai/features/studio/studio_screen.dart';
import 'package:glow_ai/services/face_detection_service.dart';

const contours = <String, List<Offset>>{
  'upperLipTop': [Offset(.3, .65), Offset(.5, .60), Offset(.7, .65)],
  'upperLipBottom': [Offset(.3, .65), Offset(.5, .67), Offset(.7, .65)],
  'lowerLipTop': [Offset(.3, .72), Offset(.5, .70), Offset(.7, .72)],
  'lowerLipBottom': [Offset(.3, .72), Offset(.5, .80), Offset(.7, .72)],
  'leftEye': [
    Offset(.2, .4),
    Offset(.21, .38),
    Offset(.23, .36),
    Offset(.26, .35),
    Offset(.3, .35),
    Offset(.34, .35),
    Offset(.37, .36),
    Offset(.39, .38),
    Offset(.4, .4),
    Offset(.38, .42),
    Offset(.35, .44),
    Offset(.32, .45),
    Offset(.3, .45),
    Offset(.26, .44),
    Offset(.23, .43),
    Offset(.21, .42),
  ],
};

MakeupPainter painter({
  bool lips = false,
  bool eyes = false,
  bool highlight = false,
  bool blush = false,
  bool liner = false,
  bool lashes = false,
  Color lineColor = Colors.black,
  double intensity = 0,
}) => MakeupPainter(
  face: const FaceGeometry(
    left: .1,
    top: .1,
    width: .8,
    height: .8,
    imageAspect: 1,
    landmarks: {'leftCheek': Offset(.3, .4), 'rightCheek': Offset(.7, .4)},
    contours: contours,
  ),
  lipstick: lips,
  blush: blush,
  eyes: eyes,
  lipColor: Colors.red,
  blushColor: Colors.pink,
  eyeColor: Colors.purple,
  lipIntensity: 1,
  blushIntensity: 1,
  eyeIntensity: 1,
  contours: contours,
  eyeliner: liner,
  mascara: lashes,
  eyelinerColor: lineColor,
  mascaraColor: lineColor,
  highlighter: highlight,
  eyelinerIntensity: intensity,
  mascaraIntensity: intensity,
  highlighterColor: Colors.yellow,
  highlighterIntensity: intensity,
);

Future<List<int>> render(
  MakeupPainter painter, {
  Size size = const Size(200, 200),
  Color background = Colors.white,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(background, BlendMode.src);
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final pixels = bytes!.buffer.asUint8List().toList();
  image.dispose();
  picture.dispose();
  return pixels;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  List<int> pixel(List<int> bytes, int x, int y, {int width = 200}) =>
      bytes.sublist((y * width + x) * 4, (y * width + x) * 4 + 3);
  test(
    'lipstick covers the lip tissue and leaves the mouth opening clear',
    () async {
      final bytes = await render(painter(lips: true));
      expect(pixel(bytes, 100, 128), isNot([255, 255, 255]));
      expect(pixel(bytes, 100, 150), isNot([255, 255, 255]));
      expect(pixel(bytes, 100, 137), [255, 255, 255]);
    },
  );
  test('eyeshadow stays outside the eye opening', () async {
    final bytes = await render(painter(eyes: true));
    expect(pixel(bytes, 60, 80), [255, 255, 255]);
    expect(pixel(bytes, 60, 60), isNot([255, 255, 255]));
  });
  test(
    'letterboxing keeps lipstick aligned with a contained portrait',
    () async {
      final bytes = await render(
        painter(lips: true),
        size: const Size(300, 200),
      );
      expect(pixel(bytes, 150, 128, width: 300), isNot([255, 255, 255]));
      expect(pixel(bytes, 20, 128, width: 300), [255, 255, 255]);
    },
  );
  test('highlighter intensity changes the rendered pixels', () async {
    expect(
      await render(
        painter(highlight: true, intensity: 1),
        background: Colors.grey,
      ),
      isNot(
        await render(
          painter(highlight: true, intensity: 0),
          background: Colors.grey,
        ),
      ),
    );
  });
  test(
    'skin cosmetics leave an eye opening unchanged even when gradients overlap it',
    () async {
      final bytes = await render(
        painter(blush: true, highlight: true, intensity: 1),
        background: Colors.grey,
      );
      expect(pixel(bytes, 60, 80), [158, 158, 158]);
    },
  );
  test(
    'eyeliner and mascara visibly respond to intensity without colouring the eye',
    () async {
      final baseline = await render(painter(), background: Colors.grey);
      int difference(List<int> value) => List.generate(
        value.length,
        (i) => (value[i] - baseline[i]).abs(),
      ).fold(0, (a, b) => a + b);
      for (final liner in [true, false]) {
        final zero = await render(
          painter(liner: liner, lashes: !liner, intensity: 0),
          background: Colors.grey,
        );
        final light = await render(
          painter(liner: liner, lashes: !liner, intensity: .25),
          background: Colors.grey,
        );
        final strong = await render(
          painter(liner: liner, lashes: !liner, intensity: 1),
          background: Colors.grey,
        );
        expect(zero, baseline);
        expect(difference(light), greaterThan(50));
        expect(difference(strong), greaterThan(difference(light)));
        expect(pixel(strong, 60, 80), [158, 158, 158]);
      }
    },
  );
  test('custom eyeliner and mascara colours change the image', () async {
    for (final liner in [true, false]) {
      expect(
        await render(
          painter(
            liner: liner,
            lashes: !liner,
            intensity: 1,
            lineColor: Colors.blue,
          ),
        ),
        isNot(
          await render(
            painter(
              liner: liner,
              lashes: !liner,
              intensity: 1,
              lineColor: Colors.red,
            ),
          ),
        ),
      );
    }
  });
}
