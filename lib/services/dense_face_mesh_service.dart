import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';
import 'face_detection_service.dart';

Future<FaceMeshInferencePipeline> _createPipeline(int _) async {
  final detector = await FaceDetectorProcessor.create(
    model: FaceDetectionModel.fullRange,
    maxResults: 4,
    minDetectionConfidence: .55,
    threads: 2,
  );
  try {
    return FaceMeshInferencePipeline(
      detector: detector,
      mesh: await FaceMeshProcessor.create(model: FaceMeshModel.v2, threads: 2),
      enableLandmarkTracking: false,
      landmarkSmoothing: null,
    );
  } catch (_) {
    detector.close();
    rethrow;
  }
}

/// Dense, offline inference in a worker isolate. No portrait leaves the device.
class DenseFaceMeshService {
  Future<FaceGeometry?> detect(String path) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      await File(path).readAsBytes(),
    );
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    ui.Image? image;
    FaceMeshIsolatePipeline? pipeline;
    try {
      final scale = math.min(
        1.0,
        1600 / math.max(descriptor.width, descriptor.height),
      );
      final codec = await descriptor.instantiateCodec(
        targetWidth: (descriptor.width * scale).round(),
        targetHeight: (descriptor.height * scale).round(),
      );
      try {
        image = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
      final width = image.width, height = image.height;
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (rgba == null) return null;
      pipeline = await FaceMeshIsolatePipeline.spawn(_createPipeline, 0);
      final result = await pipeline.process(
        FaceMeshImage(
          pixels: rgba.buffer.asUint8List(
            rgba.offsetInBytes,
            rgba.lengthInBytes,
          ),
          width: width,
          height: height,
        ),
      );
      if (result.detectionResult?.detections.length != 1) return null;
      final mesh = result.meshResult;
      if (mesh == null || mesh.landmarks.length < 468) return null;
      final points = mesh.landmarks.map((p) => ui.Offset(p.x, p.y)).toList();
      if (points.any((p) => !p.dx.isFinite || !p.dy.isFinite)) return null;
      final contours = <String, List<ui.Offset>>{
        for (final entry in _regions.entries)
          entry.key: entry.value.map((index) => points[index]).toList(),
      };
      ui.Offset average(List<int> indices) =>
          indices.map((i) => points[i]).reduce((a, b) => a + b) /
          indices.length.toDouble();
      final landmarks = <String, ui.Offset>{
        'leftEye': average([33, 133]),
        'rightEye': average([263, 362]),
        if (points.length >= 478) 'leftIris': points[468],
        if (points.length >= 478) 'rightIris': points[473],
        'mouthLeft': points[61],
        'mouthRight': points[291],
        'mouthBottom': points[17],
        'nose': points[1],
        'leftCheek': average([50, 101, 205]),
        'rightCheek': average([280, 330, 425]),
      };
      final eyeAxis = landmarks['rightEye']! - landmarks['leftEye']!;
      final eyeCenter = (landmarks['leftEye']! + landmarks['rightEye']!) / 2;
      final noseOffset = landmarks['nose']! - eyeCenter;
      final yaw =
          (noseOffset.dx * eyeAxis.dx + noseOffset.dy * eyeAxis.dy).abs() /
          eyeAxis.distanceSquared;
      final leftEyeWidth =
          (contours['leftEye']![0] - contours['leftEye']![8]).distance;
      final rightEyeWidth =
          (contours['rightEye']![0] - contours['rightEye']![8]).distance;
      if (yaw > .65 ||
          math.min(leftEyeWidth, rightEyeWidth) /
                  math.max(leftEyeWidth, rightEyeWidth) <
              .40) {
        return null;
      }
      final oval = contours['face']!;
      final left = oval.map((p) => p.dx).reduce(math.min);
      final top = oval.map((p) => p.dy).reduce(math.min);
      final right = oval.map((p) => p.dx).reduce(math.max);
      final bottom = oval.map((p) => p.dy).reduce(math.max);
      return FaceGeometry(
        left: left,
        top: top,
        width: right - left,
        height: bottom - top,
        imageAspect: width / height,
        landmarks: landmarks,
        contours: contours,
        denseMesh: true,
      );
    } finally {
      await pipeline?.close();
      image?.dispose();
      descriptor.dispose();
      buffer.dispose();
    }
  }
}

// MediaPipe's canonical 468/478 topology. Each lip edge runs corner to corner;
// eye loops start at the outer corner and follow the upper lid first.
const _regions = <String, List<int>>{
  'face': [
    10,
    338,
    297,
    332,
    284,
    251,
    389,
    356,
    454,
    323,
    361,
    288,
    397,
    365,
    379,
    378,
    400,
    377,
    152,
    148,
    176,
    149,
    150,
    136,
    172,
    58,
    132,
    93,
    234,
    127,
    162,
    21,
    54,
    103,
    67,
    109,
  ],
  'leftEye': [
    33,
    246,
    161,
    160,
    159,
    158,
    157,
    173,
    133,
    155,
    154,
    153,
    145,
    144,
    163,
    7,
  ],
  'rightEye': [
    263,
    466,
    388,
    387,
    386,
    385,
    384,
    398,
    362,
    382,
    381,
    380,
    374,
    373,
    390,
    249,
  ],
  'leftCrease': [130, 247, 30, 29, 27, 28, 56, 190, 243],
  'rightCrease': [359, 467, 260, 259, 257, 258, 286, 414, 463],
  'leftBrow': [70, 63, 105, 66, 107, 55, 65, 52, 53, 46],
  'rightBrow': [300, 293, 334, 296, 336, 285, 295, 282, 283, 276],
  'upperLipTop': [61, 185, 40, 39, 37, 0, 267, 269, 270, 409, 291],
  'upperLipBottom': [78, 191, 80, 81, 82, 13, 312, 311, 310, 415, 308],
  'lowerLipTop': [78, 95, 88, 178, 87, 14, 317, 402, 318, 324, 308],
  'lowerLipBottom': [61, 146, 91, 181, 84, 17, 314, 405, 321, 375, 291],
};
