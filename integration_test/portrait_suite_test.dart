import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:glow_ai/features/studio/studio_screen.dart';
import 'package:glow_ai/services/face_detection_service.dart';

const portraitIds = [
  '1494790108377-be9c29b29330',
  '1531123897727-8f129e1688ce',
  '1524504388940-b1c1722653e1',
  '1517841905240-472988babdf9',
  '1544005313-94ddf0286df2',
  '1488426862026-3ee34a7d66df',
  '1687360440094-949b8fe71c8c',
];

MakeupPainter look(FaceGeometry face, {String layer = 'all'}) => MakeupPainter(
  face: face,
  lipstick: layer == 'all' || layer == 'lips',
  blush: layer == 'all' || layer == 'blush',
  eyes: layer == 'all' || layer == 'eyes',
  eyeliner: layer == 'all' || layer == 'liner',
  mascara: layer == 'all' || layer == 'mascara',
  highlighter: layer == 'all' || layer == 'highlight',
  lipColor: const Color(0xFFAC3B56),
  blushColor: const Color(0xFFD4707F),
  eyeColor: const Color(0xFF9E784F),
  lipIntensity: .8,
  blushIntensity: .6,
  eyeIntensity: .65,
  eyelinerIntensity: .6,
  mascaraIntensity: .6,
  highlighterIntensity: .6,
  highlighterColor: const Color(0xFFFFD9A8),
  contours: face.contours,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'public portrait suite uses dense offline landmarks and protects eye and mouth interiors',
    (tester) async {
      const localDir = String.fromEnvironment('TEST_PORTRAIT_DIRECTORY');
      final output = Directory(
        Platform.isIOS
            ? '/tmp/glow-portrait-review'
            : '${Directory.systemTemp.path}/glow-portrait-review',
      );
      await output.create(recursive: true);
      final report = <Map<String, dynamic>>[];
      final protectionFailures = <String>[];
      for (var index = 0; index < portraitIds.length; index++) {
        final file = File(
          localDir.isNotEmpty
              ? '$localDir/portrait-${index + 1}.jpg'
              : '${output.path}/source-${index + 1}.jpg',
        );
        if (!await file.exists()) {
          final client = HttpClient();
          try {
            final response = await (await client.getUrl(
              Uri.parse(
                'https://images.unsplash.com/photo-${portraitIds[index]}?w=1000&q=90&fit=max',
              ),
            )).close();
            expect(response.statusCode, 200);
            await response.pipe(file.openWrite());
          } finally {
            client.close();
          }
        }
        final clock = Stopwatch()..start();
        final face = await FaceDetectionService().detect(file.path);
        final entry = <String, dynamic>{
          'portrait': index + 1,
          'source': portraitIds[index],
          'accepted': face != null,
          'denseMesh': face?.denseMesh,
          'milliseconds': clock.elapsedMilliseconds,
        };
        report.add(entry);
        final codec = await ui.instantiateImageCodec(await file.readAsBytes());
        final image = (await codec.getNextFrame()).image;
        final width = image.width, height = image.height;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final baselineRecorder = ui.PictureRecorder();
        Canvas(baselineRecorder).drawImage(image, Offset.zero, Paint());
        final baselinePicture = baselineRecorder.endRecording();
        final baseline = await baselinePicture.toImage(width, height);
        // Same compositing path as the studio, rendered over the actual portrait.
        canvas.drawImage(image, Offset.zero, Paint());
        if (face != null) {
          expect(
            face.denseMesh,
            isTrue,
            reason: 'Portrait ${index + 1} must use the dense mesh',
          );
          look(face).paint(canvas, Size(width.toDouble(), height.toDouble()));
        }
        final picture = recorder.endRecording();
        final after = await picture.toImage(width, height);
        final png = await after.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${output.path}/after-${index + 1}.png',
        ).writeAsBytes(png!.buffer.asUint8List());
        // Capture the mouth and eyes at useful inspection scale, original beside preview.
        final detailRecorder = ui.PictureRecorder();
        final detail = Canvas(detailRecorder);
        final bounds = face == null
            ? Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble())
            : Rect.fromLTWH(
                math.max(0, (face.left - face.width * .1) * width),
                math.max(0, (face.top - face.height * .05) * height),
                math.min(width.toDouble(), face.width * 1.2 * width),
                math.min(height.toDouble(), face.height * 1.1 * height),
              );
        final destination = const Rect.fromLTWH(0, 0, 500, 600);
        detail.drawImageRect(
          image,
          bounds,
          destination,
          Paint()..filterQuality = FilterQuality.high,
        );
        detail.drawImageRect(
          after,
          bounds,
          destination.shift(const Offset(500, 0)),
          Paint()..filterQuality = FilterQuality.high,
        );
        final detailPicture = detailRecorder.endRecording();
        final comparison = await detailPicture.toImage(1000, 600);
        final comparisonBytes = await comparison.toByteData(
          format: ui.ImageByteFormat.png,
        );
        await File(
          '${output.path}/comparison-${index + 1}.png',
        ).writeAsBytes(comparisonBytes!.buffer.asUint8List());
        if (face != null && index == 0) {
          final diagnostics = <String, dynamic>{};
          for (final layer in [
            'none',
            'lips',
            'eyes',
            'liner',
            'mascara',
            'blush',
            'highlight',
          ]) {
            final r = ui.PictureRecorder();
            final c = Canvas(r)..drawImage(image, Offset.zero, Paint());
            look(
              face,
              layer: layer,
            ).paint(c, Size(width.toDouble(), height.toDouble()));
            final p = r.endRecording();
            final img = await p.toImage(width, height);
            final data = (await img.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!.buffer.asUint8List();
            final base = (await baseline.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!.buffer.asUint8List();
            final iris = face.landmarks['leftIris']!;
            final offset =
                ((iris.dy * height).round() * width +
                    (iris.dx * width).round()) *
                4;
            diagnostics[layer] = {
              'iris': data.sublist(offset, offset + 3),
              'baseline': base.sublist(offset, offset + 3),
            };
            img.dispose();
            p.dispose();
          }
          entry['layers'] = diagnostics;
        }
        if (face != null) {
          final beforeBytes = (await baseline.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List();
          final afterBytes = (await after.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List();
          final mouth = [
            ...face.contours['upperLipBottom']!,
            ...face.contours['lowerLipTop']!,
          ];
          final zones = [
            face.contours['leftEye']!,
            face.contours['rightEye']!,
            mouth,
          ];
          for (var zone = 0; zone < zones.length; zone++) {
            final points = zones[zone];
            final center =
                (zone == 0
                    ? face.landmarks['leftIris']
                    : zone == 1
                    ? face.landmarks['rightIris']
                    : null) ??
                points.reduce((a, b) => a + b) / points.length.toDouble();
            final hole = Path()
              ..addPolygon(
                (zone < 2
                        ? zones[zone]
                        : [
                            ...face.contours['upperLipBottom']!,
                            ...face.contours['lowerLipTop']!.reversed,
                          ])
                    .map((p) => Offset(p.dx * width, p.dy * height))
                    .toList(),
                true,
              );
            final pixel = Offset(center.dx * width, center.dy * height);
            if (![
              const Offset(2, 0),
              const Offset(-2, 0),
              const Offset(0, 2),
              const Offset(0, -2),
            ].every((delta) => hole.contains(pixel + delta))) {
              continue;
            }
            final x = (center.dx * width).round().clamp(0, width - 1),
                y = (center.dy * height).round().clamp(0, height - 1);
            final offset = (y * width + x) * 4;
            final difference = List.generate(
              3,
              (c) => (afterBytes[offset + c] - beforeBytes[offset + c]).abs(),
            ).reduce(math.max);
            if (difference > 3) {
              protectionFailures.add(
                'Portrait ${index + 1} zone $zone changed by $difference',
              );
            }
          }
        }
        baseline.dispose();
        baselinePicture.dispose();
        detailPicture.dispose();
        comparison.dispose();
        after.dispose();
        picture.dispose();
        image.dispose();
        codec.dispose();
      }
      await File(
        '${output.path}/report.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
      expect(protectionFailures, isEmpty);
      expect(
        report.singleWhere((entry) => entry['portrait'] == 4)['accepted'],
        isFalse,
        reason: 'Severe side profiles need a front-facing photo',
      );
      // Front-facing examples must work; a severe profile is allowed to request a better photo.
      for (final entry in report.where((e) => e['portrait'] != 4)) {
        expect(
          entry['accepted'],
          isTrue,
          reason: 'Public portrait ${entry['portrait']}',
        );
      }
    },
  );
}
