import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceGeometry {
  final double left, top, width, height;
  final double imageAspect;
  final Map<String, ui.Offset> landmarks;
  final Map<String, List<ui.Offset>> contours;

  const FaceGeometry({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.imageAspect,
    required this.landmarks,
    required this.contours,
  });

  ui.Offset point(String name, double fallbackX, double fallbackY) =>
      landmarks[name] ??
      ui.Offset(left + width * fallbackX, top + height * fallbackY);
}

class FaceDetectionService {
  Future<FaceGeometry?> detect(String path) async {
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableContours: true,
        enableClassification: true,
        minFaceSize: 0.15,
      ),
    );
    try {
      final input = InputImage.fromFilePath(path);
      final faces = await detector.processImage(input);
      if (faces.length != 1) return null;
      final face = faces.single;
      final image = await _decode(await File(path).readAsBytes());
      final bounds = face.boundingBox;
      ui.Offset normalize(double x, double y) =>
          ui.Offset(x / image.width, y / image.height);
      final landmarks = <String, ui.Offset>{};
      final contours = <String, List<ui.Offset>>{};
      void add(String key, FaceLandmarkType type) {
        final point = face.landmarks[type]?.position;
        if (point != null) {
          landmarks[key] = normalize(point.x.toDouble(), point.y.toDouble());
        }
      }

      add('leftEye', FaceLandmarkType.leftEye);
      add('rightEye', FaceLandmarkType.rightEye);
      add('mouthLeft', FaceLandmarkType.leftMouth);
      add('mouthRight', FaceLandmarkType.rightMouth);
      add('mouthBottom', FaceLandmarkType.bottomMouth);
      void addContour(String key, FaceContourType type) {
        final points = face.contours[type]?.points;
        if (points != null && points.length >= 3) {
          contours[key] = points
              .map((point) => normalize(point.x.toDouble(), point.y.toDouble()))
              .toList();
        }
      }

      addContour('leftEye', FaceContourType.leftEye);
      addContour('rightEye', FaceContourType.rightEye);
      addContour('upperLipTop', FaceContourType.upperLipTop);
      addContour('upperLipBottom', FaceContourType.upperLipBottom);
      addContour('lowerLipTop', FaceContourType.lowerLipTop);
      addContour('lowerLipBottom', FaceContourType.lowerLipBottom);
      addContour('leftCheek', FaceContourType.leftCheek);
      addContour('rightCheek', FaceContourType.rightCheek);
      return FaceGeometry(
        left: bounds.left / image.width,
        top: bounds.top / image.height,
        width: bounds.width / image.width,
        height: bounds.height / image.height,
        imageAspect: image.width / image.height,
        landmarks: landmarks,
        contours: contours,
      );
    } finally {
      await detector.close();
    }
  }

  Future<ui.Image> _decode(List<int> bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(Uint8List.fromList(bytes), completer.complete);
    return completer.future;
  }
}
