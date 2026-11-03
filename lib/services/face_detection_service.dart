import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'dense_face_mesh_service.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceGeometry {
  final double left, top, width, height;
  final double imageAspect;
  final bool denseMesh;
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
    this.denseMesh = false,
  });

  ui.Offset point(String name, double fallbackX, double fallbackY) =>
      landmarks[name] ??
      ui.Offset(left + width * fallbackX, top + height * fallbackY);
}

class FaceDetectionService {
  Future<FaceGeometry?> detect(String path) async {
    if (Platform.isAndroid || Platform.isIOS) {
      // A missing native runtime may use ML Kit; a rejected mesh must not be
      // replaced with an approximate face on a different subject or pose.
      try {
        return await DenseFaceMeshService().detect(path);
      } on UnsupportedError {
        /* legacy runtime fallback */
      } on ArgumentError {
        /* unavailable FFI library fallback */
      }
    }
    return _detectLegacy(path);
  }

  Future<FaceGeometry?> _detectLegacy(String path) async {
    // Contour mode only returns the most prominent face on Android. Count
    // faces separately so group photos cannot accidentally pass validation.
    final counter = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: .1,
      ),
    );
    final input = InputImage.fromFilePath(path);
    try {
      if ((await counter.processImage(input)).length != 1) return null;
    } finally {
      await counter.close();
    }
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableContours: true,
        enableClassification: false,
        minFaceSize: 0.15,
      ),
    );
    try {
      final faces = await detector.processImage(input);
      if (faces.length != 1) return null;
      final face = faces.single;
      final image = await _decode(await File(path).readAsBytes());
      final imageWidth = image.width;
      final imageHeight = image.height;
      image.dispose();
      final bounds = face.boundingBox;
      ui.Offset normalize(double x, double y) =>
          ui.Offset(x / imageWidth, y / imageHeight);
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
      add('leftCheek', FaceLandmarkType.leftCheek);
      add('rightCheek', FaceLandmarkType.rightCheek);
      void addContour(String key, FaceContourType type) {
        final points = face.contours[type]?.points;
        if (points != null && points.length >= 3) {
          contours[key] = points
              .map((point) => normalize(point.x.toDouble(), point.y.toDouble()))
              .toList();
        }
      }

      addContour('face', FaceContourType.face);
      addContour('leftEye', FaceContourType.leftEye);
      addContour('rightEye', FaceContourType.rightEye);
      addContour('upperLipTop', FaceContourType.upperLipTop);
      addContour('upperLipBottom', FaceContourType.upperLipBottom);
      addContour('lowerLipTop', FaceContourType.lowerLipTop);
      addContour('lowerLipBottom', FaceContourType.lowerLipBottom);
      addContour('leftCheek', FaceContourType.leftCheek);
      addContour('rightCheek', FaceContourType.rightCheek);
      if (![
        'leftEye',
        'rightEye',
        'upperLipTop',
        'upperLipBottom',
        'lowerLipTop',
        'lowerLipBottom',
      ].every(contours.containsKey)) {
        return null;
      }
      return FaceGeometry(
        left: bounds.left / imageWidth,
        top: bounds.top / imageHeight,
        width: bounds.width / imageWidth,
        height: bounds.height / imageHeight,
        imageAspect: imageWidth / imageHeight,
        landmarks: landmarks,
        contours: contours,
      );
    } finally {
      await detector.close();
    }
  }

  Future<ui.Image> _decode(List<int> bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      Uint8List.fromList(bytes),
    );
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        final codec = await descriptor.instantiateCodec();
        try {
          return (await codec.getNextFrame()).image;
        } finally {
          codec.dispose();
        }
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  }
}
