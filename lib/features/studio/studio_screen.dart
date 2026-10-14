import "dart:ui" as ui;
import "../../core/theme.dart";
import "../../core/widgets.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "dart:io";
import "../../services/face_detection_service.dart";

class Studio extends StatefulWidget {
  final XFile? photo;
  final ValueChanged<XFile> onPhoto;
  const Studio({super.key, required this.photo, required this.onPhoto});
  @override
  State<Studio> createState() => _StudioState();
}

class _StudioState extends State<Studio> {
  bool overlay = true;
  bool lipstick = true, blush = true, eyes = true;
  bool eyeliner = false, mascara = false, highlighter = false;
  double lipIntensity = .7, blushIntensity = .45, eyeIntensity = .45;
  double eyelinerIntensity = .55, mascaraIntensity = .55;
  Color lipColor = const Color(0xFFAC3B56);
  Color blushColor = const Color(0xFFD4707F);
  Color eyeColor = const Color(0xFF9E784F);
  Color highlighterColor = const Color(0xFFFFD9A8);
  FaceGeometry? face;
  bool detecting = false;
  String? faceError;

  @override
  void initState() {
    super.initState();
    _detectFace(widget.photo);
  }

  @override
  void didUpdateWidget(covariant Studio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo?.path != widget.photo?.path) {
      _detectFace(widget.photo);
    }
  }

  Future<void> _detectFace(XFile? portrait) async {
    if (portrait == null) {
      setState(() {
        face = null;
        faceError = null;
        detecting = false;
      });
      return;
    }
    setState(() {
      detecting = true;
      faceError = null;
    });
    try {
      final detected = await FaceDetectionService().detect(portrait.path);
      if (!mounted) return;
      setState(() {
        face = detected;
        detecting = false;
        faceError = detected == null
            ? 'Use a clear portrait with exactly one front-facing face.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        detecting = false;
        faceError = 'Face detection could not start. Try another portrait.';
      });
    }
  }

  Future<void> pick(ImageSource source) async {
    final p = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (p != null) widget.onPhoto(p);
    setState(() {});
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: copy('Virtual makeup', color: ink)),
    body: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        title('The makeup studio'),
        copy('Local face landmark verification'),
        const SizedBox(height: 20),
        if (widget.photo == null) ...[
          card(
            Column(
              children: [
                const Icon(
                  Icons.face_retouching_natural,
                  size: 48,
                  color: primary,
                ),
                title('Your portrait', size: 24),
                copy(
                  'Choose a clear, front-facing portrait to explore your shades.',
                ),
              ],
            ),
          ),
        ],
        if (widget.photo != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.file(
                  File(widget.photo!.path),
                  width: double.infinity,
                  height: 360,
                  fit: BoxFit.contain,
                ),
                if (overlay && face != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: MakeupPainter(
                        face: face!,
                        lipstick: lipstick,
                        blush: blush,
                        eyes: eyes,
                        lipColor: lipColor,
                        blushColor: blushColor,
                        eyeColor: eyeColor,
                        lipIntensity: lipIntensity,
                        blushIntensity: blushIntensity,
                        eyeIntensity: eyeIntensity,
                        contours: face!.contours,
                        eyeliner: eyeliner,
                        mascara: mascara,
                        highlighter: highlighter,
                        eyelinerIntensity: eyelinerIntensity,
                        mascaraIntensity: mascaraIntensity,
                        highlighterColor: highlighterColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    copy('Local makeup overlay'),
                    Switch(
                      value: overlay,
                      onChanged: (v) => setState(() => overlay = v),
                      activeColor: primary,
                    ),
                  ],
                ),
                _makeupControl(
                  'Lipstick',
                  lipstick,
                  lipIntensity,
                  lipColor,
                  (v) => setState(() => lipstick = v),
                  (v) => setState(() => lipIntensity = v),
                ),
                _colorChoices(lipColor, const [
                  Color(0xFFAC3B56),
                  Color(0xFF8B1E3F),
                  Color(0xFFC95B72),
                  Color(0xFFD84F5F),
                  Color(0xFFB85C70),
                  Color(0xFFE0412B),
                ], (color) => setState(() => lipColor = color)),
                _makeupControl(
                  'Blush',
                  blush,
                  blushIntensity,
                  blushColor,
                  (v) => setState(() => blush = v),
                  (v) => setState(() => blushIntensity = v),
                ),
                _colorChoices(blushColor, const [
                  Color(0xFFD4707F),
                  Color(0xFFE5827D),
                  Color(0xFFEB9884),
                  Color(0xFFE86F58),
                  Color(0xFFC2526E),
                  Color(0xFFF4A6B6),
                ], (color) => setState(() => blushColor = color)),
                _makeupControl(
                  'Eyeshadow',
                  eyes,
                  eyeIntensity,
                  eyeColor,
                  (v) => setState(() => eyes = v),
                  (v) => setState(() => eyeIntensity = v),
                ),
                _colorChoices(eyeColor, const [
                  Color(0xFF9E784F),
                  Color(0xFFA46643),
                  Color(0xFF99827B),
                  Color(0xFF8E4A7D),
                  Color(0xFF3D3835),
                  Color(0xFFCBB2A3),
                ], (color) => setState(() => eyeColor = color)),
                _makeupControl(
                  'Eyeliner',
                  eyeliner,
                  eyelinerIntensity,
                  const Color(0xFF30232B),
                  (v) => setState(() => eyeliner = v),
                  (v) => setState(() => eyelinerIntensity = v),
                ),
                _makeupControl(
                  'Mascara',
                  mascara,
                  mascaraIntensity,
                  const Color(0xFF17131A),
                  (v) => setState(() => mascara = v),
                  (v) => setState(() => mascaraIntensity = v),
                ),
                _makeupControl(
                  'Highlighter',
                  highlighter,
                  .55,
                  highlighterColor,
                  (v) => setState(() => highlighter = v),
                  (_) {},
                ),
              ],
            ),
          ),
          notice(
            detecting
                ? 'Detecting facial features on this device…'
                : faceError ??
                      'Face detected. Makeup is anchored to your eyes, cheeks and lips and rendered locally.',
            error: faceError != null,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: action(
                'Take photo',
                () => pick(ImageSource.camera),
                icon: Icons.camera_alt_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: action(
                'Choose from gallery',
                () => pick(ImageSource.gallery),
                secondary: true,
                icon: Icons.photo_library_outlined,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _makeupControl(
  String label,
  bool enabled,
  double value,
  Color color,
  ValueChanged<bool> onEnabled,
  ValueChanged<double> onIntensity,
) => Column(
  children: [
    Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: copy(label)),
        Switch(value: enabled, onChanged: onEnabled, activeColor: primary),
      ],
    ),
    Slider(
      value: value,
      onChanged: enabled ? onIntensity : null,
      activeColor: primary,
    ),
  ],
);

Widget _colorChoices(
  Color selected,
  List<Color> colors,
  ValueChanged<Color> onSelected,
) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Wrap(
    spacing: 10,
    children: colors
        .map(
          (color) => GestureDetector(
            onTap: () => onSelected(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: selected == color ? 34 : 28,
              height: selected == color ? 34 : 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == color ? primary : border,
                  width: selected == color ? 3 : 1,
                ),
              ),
            ),
          ),
        )
        .toList(),
  ),
);

class MakeupPainter extends CustomPainter {
  final FaceGeometry face;
  final bool lipstick, blush, eyes, eyeliner, mascara, highlighter;
  final Color lipColor, blushColor, eyeColor;
  final double lipIntensity, blushIntensity, eyeIntensity;
  final Map<String, List<Offset>> contours;
  final double eyelinerIntensity, mascaraIntensity;
  final Color highlighterColor;

  MakeupPainter({
    required this.face,
    required this.lipstick,
    required this.blush,
    required this.eyes,
    required this.lipColor,
    required this.blushColor,
    required this.eyeColor,
    required this.lipIntensity,
    required this.blushIntensity,
    required this.eyeIntensity,
    required this.contours,
    required this.eyeliner,
    required this.mascara,
    required this.highlighter,
    required this.eyelinerIntensity,
    required this.mascaraIntensity,
    required this.highlighterColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final imageWidth = face.imageAspect >= size.aspectRatio
        ? size.width
        : size.height * face.imageAspect;
    final imageHeight = face.imageAspect >= size.aspectRatio
        ? size.width / face.imageAspect
        : size.height;
    final imageLeft = (size.width - imageWidth) / 2;
    final imageTop = (size.height - imageHeight) / 2;
    Offset point(String name, double x, double y) {
      final normalized = face.point(name, x, y);
      return Offset(
        imageLeft + normalized.dx * imageWidth,
        imageTop + normalized.dy * imageHeight,
      );
    }

    Offset normalizedPoint(Offset normalized) => Offset(
      imageLeft + normalized.dx * imageWidth,
      imageTop + normalized.dy * imageHeight,
    );

    Paint paint(Color color, double opacity) =>
        Paint()..color = color.withValues(alpha: opacity);
    Offset contourPoint(Offset normalized) => normalizedPoint(normalized);
    Path contourPath(String name) {
      final points = contours[name];
      if (points == null || points.length < 3) return Path();
      return Path()..addPolygon(points.map(contourPoint).toList(), true);
    }

    void drawContour(String name, Color color, double opacity) {
      final path = contourPath(name);
      if (!path.getBounds().isEmpty) {
        canvas.drawPath(path, paint(color, opacity));
      }
    }

    void drawContourStroke(String name, Color color, double width) {
      final points = contours[name];
      if (points == null || points.length < 2) return;
      final path = Path()
        ..moveTo(contourPoint(points.first).dx, contourPoint(points.first).dy);
      for (final normalized in points.skip(1)) {
        final p = contourPoint(normalized);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width,
      );
    }

    Offset cheekCenter(String eyeName, String mouthName, double fallbackX) {
      final eye = face.point(eyeName, fallbackX, .43);
      final mouth = face.point(mouthName, fallbackX, .70);
      return normalizedPoint(
        Offset(
          eye.dx + (mouth.dx - eye.dx) * .45,
          eye.dy + (mouth.dy - eye.dy) * .62,
        ),
      );
    }

    void drawBlush(Offset center) {
      final radius = imageWidth * face.width * .13;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            center,
            radius,
            [
              blushColor.withValues(alpha: .48 * blushIntensity),
              blushColor.withValues(alpha: .20 * blushIntensity),
              blushColor.withValues(alpha: 0),
            ],
            [0, .62, 1],
          ),
      );
    }

    if (blush) {
      drawBlush(cheekCenter('leftEye', 'mouthLeft', .32));
      drawBlush(cheekCenter('rightEye', 'mouthRight', .68));
    }
    if (eyeliner) {
      drawContourStroke(
        'leftEye',
        const Color(0xFF241A22),
        1.2 + 2.2 * eyelinerIntensity,
      );
      drawContourStroke(
        'rightEye',
        const Color(0xFF241A22),
        1.2 + 2.2 * eyelinerIntensity,
      );
    }
    if (mascara) {
      drawContourStroke(
        'leftEye',
        const Color(0xFF120E12),
        .8 + 1.4 * mascaraIntensity,
      );
      drawContourStroke(
        'rightEye',
        const Color(0xFF120E12),
        .8 + 1.4 * mascaraIntensity,
      );
    }
    if (highlighter) {
      final left = cheekCenter('leftEye', 'mouthLeft', .32);
      final right = cheekCenter('rightEye', 'mouthRight', .68);
      final radius = imageWidth * face.width * .045;
      for (final center in [left, right]) {
        canvas.drawCircle(
          center.translate(0, -radius * .35),
          radius,
          Paint()
            ..shader =
                ui.Gradient.radial(center.translate(0, -radius * .35), radius, [
                  highlighterColor.withValues(alpha: .45),
                  highlighterColor.withValues(alpha: 0),
                ]),
        );
      }
    }
    if (eyes) {
      if (contours.containsKey('leftEye') && contours.containsKey('rightEye')) {
        drawContour('leftEye', eyeColor, .55 * eyeIntensity);
        drawContour('rightEye', eyeColor, .55 * eyeIntensity);
      } else {
        canvas.drawOval(
          Rect.fromCenter(
            center: point('leftEye', .35, .43),
            width: w * .18,
            height: h * .045,
          ),
          paint(eyeColor, .45 * eyeIntensity),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: point('rightEye', .65, .43),
            width: w * .18,
            height: h * .045,
          ),
          paint(eyeColor, .45 * eyeIntensity),
        );
      }
    }
    if (lipstick) {
      if (contours.containsKey('upperLipTop') &&
          contours.containsKey('upperLipBottom') &&
          contours.containsKey('lowerLipTop') &&
          contours.containsKey('lowerLipBottom')) {
        drawContour('upperLipTop', lipColor, .88 * lipIntensity);
        drawContour('upperLipBottom', lipColor, .88 * lipIntensity);
        drawContour('lowerLipTop', lipColor, .88 * lipIntensity);
        drawContour('lowerLipBottom', lipColor, .88 * lipIntensity);
      } else {
        canvas.drawOval(
          Rect.fromCenter(
            center: point('mouthBottom', .50, .72),
            width: w * .16,
            height: h * .055,
          ),
          paint(lipColor, .82 * lipIntensity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant MakeupPainter oldDelegate) =>
      lipstick != oldDelegate.lipstick ||
      blush != oldDelegate.blush ||
      eyes != oldDelegate.eyes ||
      lipIntensity != oldDelegate.lipIntensity ||
      blushIntensity != oldDelegate.blushIntensity ||
      eyeIntensity != oldDelegate.eyeIntensity ||
      lipColor != oldDelegate.lipColor ||
      blushColor != oldDelegate.blushColor ||
      eyeColor != oldDelegate.eyeColor ||
      eyeliner != oldDelegate.eyeliner ||
      mascara != oldDelegate.mascara ||
      highlighter != oldDelegate.highlighter ||
      eyelinerIntensity != oldDelegate.eyelinerIntensity ||
      mascaraIntensity != oldDelegate.mascaraIntensity ||
      highlighterColor != oldDelegate.highlighterColor ||
      contours != oldDelegate.contours ||
      face != oldDelegate.face;
}
