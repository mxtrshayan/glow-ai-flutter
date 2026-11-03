import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

class MakeupExportService {
  static const channel = MethodChannel('glow_ai/media');

  /// Render the source-sized photo and the same makeup painter used by preview.
  /// The system file picker owns destination access; no broad storage permission.
  Future<bool> save(String sourcePath, CustomPainter painter) async {
    final codec = await ui.instantiateImageCodec(
      await File(sourcePath).readAsBytes(),
    );
    ui.Image? source;
    ui.Image? output;
    ui.Picture? picture;
    Directory? temporary;
    try {
      source = (await codec.getNextFrame()).image;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)
        ..drawImage(source, ui.Offset.zero, ui.Paint());
      painter.paint(
        canvas,
        ui.Size(source.width.toDouble(), source.height.toDouble()),
      );
      picture = recorder.endRecording();
      output = await picture.toImage(source.width, source.height);
      final bytes = await output.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Image encoding failed');
      temporary = await Directory.systemTemp.createTemp('glow-export-');
      final name = 'Glow-AI-${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${temporary.path}/$name');
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      return await channel.invokeMethod<bool>('saveImage', {
            'path': file.path,
            'name': name,
          }) ??
          false;
    } finally {
      codec.dispose();
      source?.dispose();
      output?.dispose();
      picture?.dispose();
      if (temporary != null) await temporary.delete(recursive: true);
    }
  }
}
