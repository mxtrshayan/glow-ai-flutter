import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

/// A disposable, non-photographic input for image I/O and layout tests.
/// Face detection is mocked in these tests; native tests supply their own photo.
Future<File> createTemporaryInputImage() async {
  final directory = await Directory.systemTemp.createTemp('glow-test-image-');
  addTearDown(() => directory.delete(recursive: true));
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(const ui.Color(0xFFE8D5DA), ui.BlendMode.src);
  canvas.drawRect(
    const ui.Rect.fromLTWH(64, 64, 384, 384),
    ui.Paint()..color = const ui.Color(0xFFB47A8C),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(512, 512);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return File('${directory.path}/input.png')
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  } finally {
    image.dispose();
    picture.dispose();
  }
}
