import 'dart:math' as math;
import "dart:ui" as ui;
import "../../core/theme.dart";
import "../../core/widgets.dart";
import "../../core/color_picker.dart";
import "../../services/makeup_export_service.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "dart:io";
import "../../services/face_detection_service.dart";
import "../../models/recommendation.dart";

class Studio extends StatefulWidget {
  final XFile? photo;
  final ValueChanged<XFile> onPhoto;
  final Recommendation? recommendation;
  const Studio({
    super.key,
    required this.photo,
    required this.onPhoto,
    this.recommendation,
  });
  @override
  State<Studio> createState() => _StudioState();
}

class _StudioState extends State<Studio> {
  bool overlay = true;
  bool lipstick = true, blush = true, eyes = true;
  bool eyeliner = false, mascara = false, highlighter = false;
  double lipIntensity = .7, blushIntensity = .45, eyeIntensity = .45;
  double eyelinerIntensity = .55, mascaraIntensity = .55;
  double highlighterIntensity = .55;
  XFile? portrait;
  int detectionRequest = 0;
  bool picking = false;
  bool exporting = false;
  Color eyelinerColor = const Color(0xFF241A22);
  Color mascaraColor = const Color(0xFF120E12);
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
    portrait = widget.photo;
    final sections = widget.recommendation?.sections;
    Color shade(String? value, Color fallback) {
      final hex = value?.replaceFirst('#', '');
      final parsed = hex != null && hex.length == 6
          ? int.tryParse(hex, radix: 16)
          : null;
      return parsed == null ? fallback : Color(0xFF000000 | parsed);
    }

    lipColor = shade(sections?['lips']?['hex'], lipColor);
    blushColor = shade(sections?['face']?['blush_hex'], blushColor);
    eyeColor = shade(sections?['eyes']?['eyeshadow_hex'], eyeColor);
    eyelinerColor = shade(sections?['eyes']?['eyeliner_hex'], eyelinerColor);
    mascaraColor = shade(sections?['eyes']?['mascara_hex'], mascaraColor);
    highlighterColor = shade(
      sections?['face']?['highlighter_hex'] ??
          sections?['face']?['highlight_hex'],
      highlighterColor,
    );
    eyeliner = sections?['eyes']?['eyeliner']?.trim().isNotEmpty ?? false;
    mascara = sections?['eyes']?['mascara']?.trim().isNotEmpty ?? false;
    highlighter = sections?['face']?['highlight']?.trim().isNotEmpty ?? false;

    _detectFace(portrait);
  }

  @override
  void didUpdateWidget(covariant Studio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo?.path != widget.photo?.path) {
      portrait = widget.photo;
      _detectFace(portrait);
    }
  }

  Future<void> _detectFace(XFile? portrait) async {
    final request = ++detectionRequest;
    if (portrait == null) {
      setState(() {
        face = null;
        faceError = null;
        detecting = false;
      });
      return;
    }
    setState(() {
      face = null;
      detecting = true;
      faceError = null;
    });
    try {
      final detected = await FaceDetectionService()
          .detect(portrait.path)
          .timeout(const Duration(seconds: 20));
      if (!mounted || request != detectionRequest) return;
      setState(() {
        face = detected;
        detecting = false;
        faceError = detected == null
            ? 'Use a clear portrait with exactly one front-facing face.'
            : null;
      });
    } catch (_) {
      if (!mounted || request != detectionRequest) return;
      setState(() {
        detecting = false;
        faceError = 'Face detection could not start. Try another portrait.';
      });
    }
  }

  Future<void> pick(ImageSource source) async {
    if (picking) return;
    setState(() => picking = true);
    try {
      final selected = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );
      if (!mounted || selected == null) return;
      setState(() => portrait = selected);
      widget.onPhoto(selected);
      await _detectFace(selected);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the camera or gallery. Check permissions and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  MakeupPainter _painter() => MakeupPainter(
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
    eyelinerColor: eyelinerColor,
    mascaraColor: mascaraColor,
    highlighterColor: highlighterColor,
    highlighterIntensity: highlighterIntensity,
  );

  Future<void> _download() async {
    if (face == null || portrait == null || detecting || exporting) return;
    setState(() => exporting = true);
    try {
      final saved = await MakeupExportService().save(
        portrait!.path,
        _painter(),
      );
      if (mounted && saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your makeup photo has been saved.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your photo. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Widget _palette(
    String label,
    Color selected,
    List<Color> colors,
    ValueChanged<Color> onSelected,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _colorChoices(selected, colors, (color) {
        onSelected(color);
        setState(() => overlay = true);
      }),
      TextButton.icon(
        onPressed: () async {
          final color = await showMakeupColorPicker(
            context,
            label: '$label colour',
            initialColor: selected,
          );
          if (mounted && color != null) {
            onSelected(color);
            setState(() => overlay = true);
          }
        },
        icon: const Icon(Icons.palette_outlined),
        label: Text('Choose any $label colour'),
        style: TextButton.styleFrom(
          foregroundColor: accentOf(context),
          minimumSize: const Size(0, 48),
        ),
      ),
    ],
  );

  Widget _preview(double height) => SizedBox(
    height: height,
    child: InteractiveViewer(
      minScale: 1,
      maxScale: 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.file(
              File(portrait!.path),
              width: double.infinity,
              height: height,
              fit: BoxFit.contain,
              errorBuilder: (_, error, stackTrace) => SizedBox(
                height: height,
                child: Center(
                  child: notice(
                    'This photo could not be opened. Choose another image.',
                    error: true,
                  ),
                ),
              ),
            ),
            if (overlay && !detecting && face != null)
              Positioned.fill(child: CustomPaint(painter: _painter())),
          ],
        ),
      ),
    ),
  );

  Widget _controls() => card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: copy('Show makeup')),
            Switch(
              value: overlay,
              onChanged: (v) => setState(() => overlay = v),
            ),
          ],
        ),
        _makeupControl(
          'Lipstick',
          lipstick,
          lipIntensity,
          lipColor,
          (v) => setState(() => lipstick = v),
          (v) => setState(() {
            lipIntensity = v;
            overlay = true;
          }),
        ),
        _palette(
          'lipstick',
          lipColor,
          const [
            Color(0xFFAC3B56),
            Color(0xFF8B1E3F),
            Color(0xFFC95B72),
            Color(0xFFD84F5F),
            Color(0xFFB85C70),
            Color(0xFFE0412B),
          ],
          (color) => setState(() {
            lipColor = color;
            lipstick = true;
          }),
        ),
        _makeupControl(
          'Blush',
          blush,
          blushIntensity,
          blushColor,
          (v) => setState(() => blush = v),
          (v) => setState(() {
            blushIntensity = v;
            overlay = true;
          }),
        ),
        _palette(
          'blush',
          blushColor,
          const [
            Color(0xFFD4707F),
            Color(0xFFE5827D),
            Color(0xFFEB9884),
            Color(0xFFE86F58),
            Color(0xFFC2526E),
            Color(0xFFF4A6B6),
          ],
          (color) => setState(() {
            blushColor = color;
            blush = true;
          }),
        ),
        _makeupControl(
          'Eyeshadow',
          eyes,
          eyeIntensity,
          eyeColor,
          (v) => setState(() => eyes = v),
          (v) => setState(() {
            eyeIntensity = v;
            overlay = true;
          }),
        ),
        _palette(
          'eyeshadow',
          eyeColor,
          const [
            Color(0xFF9E784F),
            Color(0xFFA46643),
            Color(0xFF99827B),
            Color(0xFF8E4A7D),
            Color(0xFF3D3835),
            Color(0xFFCBB2A3),
          ],
          (color) => setState(() {
            eyeColor = color;
            eyes = true;
          }),
        ),
        _makeupControl(
          'Eyeliner',
          eyeliner,
          eyelinerIntensity,
          eyelinerColor,
          (v) => setState(() => eyeliner = v),
          (v) => setState(() {
            eyelinerIntensity = v;
            overlay = true;
          }),
        ),
        _palette(
          'eyeliner',
          eyelinerColor,
          const [Color(0xFF241A22), Color(0xFF60392D), Color(0xFF243D72)],
          (color) => setState(() {
            eyelinerColor = color;
            eyeliner = true;
          }),
        ),
        _makeupControl(
          'Mascara',
          mascara,
          mascaraIntensity,
          mascaraColor,
          (v) => setState(() => mascara = v),
          (v) => setState(() {
            mascaraIntensity = v;
            overlay = true;
          }),
        ),
        _palette(
          'mascara',
          mascaraColor,
          const [Color(0xFF120E12), Color(0xFF60392D), Color(0xFF243D72)],
          (color) => setState(() {
            mascaraColor = color;
            mascara = true;
          }),
        ),
        _makeupControl(
          'Highlighter',
          highlighter,
          highlighterIntensity,
          highlighterColor,
          (v) => setState(() => highlighter = v),
          (v) => setState(() {
            highlighterIntensity = v;
            overlay = true;
          }),
        ),
        _palette(
          'highlighter',
          highlighterColor,
          const [Color(0xFFFFD9A8), Colors.white, Color(0xFFF3B8CA)],
          (color) => setState(() {
            highlighterColor = color;
            highlighter = true;
          }),
        ),
      ],
    ),
  );

  Widget _status() => notice(
    detecting
        ? 'Detecting facial features on this device…'
        : faceError ??
              'Face detected. Makeup is anchored to your eyes, cheeks and lips and rendered locally.',
    error: faceError != null,
  );

  Widget _photoActions() => photoActions(
    onCamera: picking || exporting ? null : () => pick(ImageSource.camera),
    onGallery: picking || exporting ? null : () => pick(ImageSource.gallery),
  );

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: copy('Virtual makeup', color: inkOf(c))),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= 760 && constraints.maxHeight >= 500;
          if (portrait == null) {
            return responsiveBody(
              ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  title('The makeup studio'),
                  copy(
                    'Explore shades on your portrait, privately on this device.',
                  ),
                  const SizedBox(height: 20),
                  card(
                    Column(
                      children: [
                        Icon(
                          Icons.face_retouching_natural,
                          size: 48,
                          color: accentOf(c),
                        ),
                        title('Your portrait', size: 24),
                        copy(
                          'Choose a clear, front-facing portrait to explore your shades.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _photoActions(),
                ],
              ),
            );
          }
          final previewHeight = wide
              ? math.min(
                  (constraints.maxHeight - 270).clamp(200.0, 720.0),
                  (math.min(constraints.maxWidth, 1280) - 68) *
                      6 /
                      11 /
                      (face?.imageAspect ?? 1),
                )
              : (constraints.maxHeight * .40).clamp(150.0, 380.0);
          final preview = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _preview(previewHeight),
              const SizedBox(height: 8),
              copy('Pinch to zoom · Compare using Show makeup', size: 11),
              const SizedBox(height: 8),
              _photoActions(),
              const SizedBox(height: 8),
              action(
                exporting ? 'Saving your look…' : 'Download look',
                face == null || detecting || exporting ? null : _download,
                icon: Icons.download_outlined,
              ),
            ],
          );
          if (wide) {
            return responsiveBody(
              Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            title('The makeup studio', size: 28),
                            const SizedBox(height: 12),
                            preview,
                            const SizedBox(height: 12),
                            _status(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: ListView(children: [_controls()])),
                  ],
                ),
              ),
              maxWidth: 1280,
            );
          }
          if (constraints.maxHeight < 600) {
            return responsiveBody(
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  preview,
                  const SizedBox(height: 12),
                  _status(),
                  const SizedBox(height: 12),
                  _controls(),
                ],
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: preview,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _status(),
                    const SizedBox(height: 12),
                    _controls(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
        copy(enabled ? '${(value * 100).round()}%' : 'Off', size: 12),
        const SizedBox(width: 4),
        Switch(value: enabled, onChanged: onEnabled),
      ],
    ),
    Slider(
      value: value,
      onChanged: (value) {
        if (!enabled) onEnabled(true);
        onIntensity(value);
      },
      label: '${(value * 100).round()}%',
      semanticFormatterCallback: (v) => '${(v * 100).round()} percent',
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
    spacing: 4,
    runSpacing: 4,
    children: [
      for (final color in colors)
        Semantics(
          button: true,
          selected: selected == color,
          label: 'Colour #${colorHex(color)}',
          child: InkWell(
            onTap: () => onSelected(color),
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
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
            ),
          ),
        ),
    ],
  ),
);

class MakeupPainter extends CustomPainter {
  final FaceGeometry face;
  final bool lipstick, blush, eyes, eyeliner, mascara, highlighter;
  final Color lipColor, blushColor, eyeColor;
  final double lipIntensity, blushIntensity, eyeIntensity;
  final Map<String, List<Offset>> contours;
  final double eyelinerIntensity, mascaraIntensity;
  final double highlighterIntensity;
  final Color highlighterColor;
  final Color eyelinerColor, mascaraColor;

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
    this.highlighterIntensity = .55,
    this.eyelinerColor = const Color(0xFF241A22),
    this.mascaraColor = const Color(0xFF120E12),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final imageWidth = face.imageAspect >= size.aspectRatio
        ? size.width
        : size.height * face.imageAspect;
    final imageHeight = face.imageAspect >= size.aspectRatio
        ? size.width / face.imageAspect
        : size.height;
    final imageLeft = (size.width - imageWidth) / 2;
    final imageTop = (size.height - imageHeight) / 2;
    Offset normalizedPoint(Offset normalized) => Offset(
      imageLeft + normalized.dx * imageWidth,
      imageTop + normalized.dy * imageHeight,
    );

    Paint paint(Color color, double opacity) =>
        Paint()..color = color.withValues(alpha: opacity);
    Offset contourPoint(Offset normalized) => normalizedPoint(normalized);
    Path smooth(List<Offset> points, {bool closed = true}) {
      if (points.length < 3) return Path();
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      Offset at(int i) => closed
          ? points[i % points.length]
          : points[i.clamp(0, points.length - 1)];
      for (var i = 0; i < points.length - (closed ? 0 : 1); i++) {
        final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
        final c1 = p1 + (p2 - p0) / 6;
        final c2 = p2 - (p3 - p1) / 6;
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
      }
      if (closed) path.close();
      return path;
    }

    Path region(String name) =>
        smooth((contours[name] ?? []).map(contourPoint).toList());
    final facePath = region('face');
    canvas.save();
    if (!facePath.getBounds().isEmpty) canvas.clipPath(facePath);

    // Lip contours are open curves. Join each outer edge to its inner
    // edge, preserving the unpainted mouth opening and teeth.
    void drawLip(String outerName, String innerName) {
      final outer = contours[outerName]?.map(contourPoint).toList();
      final inner = contours[innerName]?.map(contourPoint).toList();
      if (outer == null ||
          inner == null ||
          outer.length < 3 ||
          inner.length < 3) {
        return;
      }
      final orderedInner =
          (outer.last - inner.first).distanceSquared <=
              (outer.last - inner.last).distanceSquared
          ? inner
          : inner.reversed.toList();
      final path = smooth([...outer, ...orderedInner]);
      canvas.save();
      canvas.clipPath(path);
      final innerTop = contours['upperLipBottom'];
      final innerBottom = contours['lowerLipTop'];
      if (innerTop != null && innerBottom != null) {
        final opening = smooth([
          ...innerTop.map(contourPoint),
          ...innerBottom.reversed.map(contourPoint),
        ]);
        canvas.clipPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(Offset.zero & size),
            opening,
          ),
        );
      }
      canvas.drawPath(
        path,
        paint(lipColor, .80 * lipIntensity)
          ..blendMode = BlendMode.color
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            imageWidth * face.width * .002,
          ),
      );
      canvas.drawPath(path, paint(lipColor, .20 * lipIntensity));
      canvas.restore();
    }

    void drawEye(String name) {
      final points = contours[name]?.map(contourPoint).toList();
      if (points == null || points.length < 12) return;
      final upper = points.take(9).toList();
      canvas.save();
      canvas.clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Offset.zero & size),
          smooth(points),
        ),
      );
      final start = upper.first;
      final end = upper.last;
      final eyeWidth = (end - start).distance;
      if (eyeWidth <= 0) {
        canvas.restore();
        return;
      }
      // The normal points above the eyelid even when the portrait is tilted.
      var normal = Offset((end - start).dy, -(end - start).dx) / eyeWidth;
      if (normal.dy > 0) normal = -normal;
      if (eyes && eyeIntensity > 0) {
        final crease =
            contours[name == 'leftEye' ? 'leftCrease' : 'rightCrease']
                ?.map(contourPoint)
                .toList();
        final lid = smooth([
          ...upper,
          ...(crease?.reversed ??
              upper.reversed.map((p) => p + normal * eyeWidth * .30)),
        ]);
        final eye = Path()..addPolygon(points, true);
        canvas.save();
        canvas.clipPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(Offset.zero & size),
            eye,
          ),
        );
        canvas.drawPath(
          lid,
          paint(eyeColor, .48 * eyeIntensity)
            ..blendMode = BlendMode.multiply
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, eyeWidth * .06),
        );
        canvas.restore();
      }
      final tangent = (end - start) / eyeWidth;
      final lineWidth =
          math.max(.7, eyeWidth * .055) * (.35 + 1.2 * eyelinerIntensity);
      final lashLine = smooth(
        upper.map((point) => point + normal * lineWidth * .45).toList(),
        closed: false,
      );
      if (eyeliner && eyelinerIntensity > 0) {
        canvas.drawPath(
          lashLine,
          paint(eyelinerColor, .45 + .50 * eyelinerIntensity)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = lineWidth,
        );
        final wing =
            start -
            tangent * eyeWidth * .16 * eyelinerIntensity +
            normal * eyeWidth * .08;
        canvas.drawPath(
          Path()
            ..moveTo(start.dx, start.dy)
            ..lineTo(wing.dx, wing.dy)
            ..lineTo(
              (start + normal * lineWidth).dx,
              (start + normal * lineWidth).dy,
            )
            ..close(),
          paint(eyelinerColor, .45 + .50 * eyelinerIntensity),
        );
      }
      if (mascara && mascaraIntensity > 0) {
        final lashPaint = paint(mascaraColor, .45 + .55 * mascaraIntensity)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(.6, eyeWidth * .018);
        final metrics = smooth(upper, closed: false).computeMetrics().first;
        for (var i = 1; i <= 11; i++) {
          final t = i / 12;
          final base = metrics
              .getTangentForOffset(metrics.length * t)!
              .position;
          final length =
              eyeWidth *
              (.11 + .14 * mascaraIntensity) *
              (.5 + .5 * math.sin(math.pi * t));
          final tip =
              base + normal * length + tangent * ((t - .5) * length * .7);
          canvas.drawPath(
            Path()
              ..moveTo(base.dx, base.dy)
              ..quadraticBezierTo(
                (base + normal * length * .65).dx,
                (base + normal * length * .65).dy,
                tip.dx,
                tip.dy,
              ),
            lashPaint,
          );
        }
      }
      canvas.restore();
    }

    Offset cheekCenter(String eyeName, String mouthName, double fallbackX) {
      final cheek =
          face.landmarks[eyeName == 'leftEye' ? 'leftCheek' : 'rightCheek'];
      if (cheek != null) return normalizedPoint(cheek);
      final eye = face.point(eyeName, fallbackX, .43);
      final mouth = face.point(mouthName, fallbackX, .70);
      return normalizedPoint(
        Offset(
          eye.dx + (mouth.dx - eye.dx) * .45,
          eye.dy + (mouth.dy - eye.dy) * .62,
        ),
      );
    }

    final leftEye = normalizedPoint(face.point('leftEye', .32, .43));
    final rightEye = normalizedPoint(face.point('rightEye', .68, .43));
    final angle = math.atan2(
      rightEye.dy - leftEye.dy,
      rightEye.dx - leftEye.dx,
    );
    void glow(
      Offset center,
      Color color,
      double radius,
      double alpha,
      BlendMode mode,
    ) {
      // Composite a separate transparent cosmetic layer. Explicitly clearing
      // feature holes also protects them on GPU renderers using advanced blends.
      canvas.saveLayer(Offset.zero & size, Paint()..blendMode = mode);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.scale(1.25, .72);
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            radius,
            [
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * .4),
              color.withValues(alpha: 0),
            ],
            [0, .55, 1],
          ),
      );
      canvas.restore();
      final clear = Paint()..blendMode = BlendMode.clear;
      for (final name in ['leftEye', 'rightEye', 'leftBrow', 'rightBrow']) {
        canvas.drawPath(region(name), clear);
      }
      final lips = <Offset>[
        ...(contours['upperLipTop'] ?? <Offset>[]),
        ...(contours['lowerLipBottom'] ?? <Offset>[]).reversed,
      ];
      if (lips.length > 5) {
        canvas.drawPath(smooth(lips.map(contourPoint).toList()), clear);
      }
      canvas.restore();
    }

    void drawBlush(Offset center) => glow(
      center,
      blushColor,
      imageWidth * face.width * .15,
      .40 * blushIntensity,
      BlendMode.softLight,
    );

    if (blush) {
      drawBlush(cheekCenter('leftEye', 'mouthLeft', .32));
      drawBlush(cheekCenter('rightEye', 'mouthRight', .68));
    }
    drawEye('leftEye');
    drawEye('rightEye');
    if (highlighter && highlighterIntensity > 0) {
      final radius = imageWidth * face.width * .10;
      final lift = Offset(math.sin(angle), -math.cos(angle)) * radius * .9;
      for (final center in [
        cheekCenter('leftEye', 'mouthLeft', .32),
        cheekCenter('rightEye', 'mouthRight', .68),
      ]) {
        glow(
          center + lift,
          highlighterColor,
          radius,
          .65 * highlighterIntensity,
          BlendMode.screen,
        );
      }
    }
    if (lipstick && lipIntensity > 0) {
      drawLip('upperLipTop', 'upperLipBottom');
      drawLip('lowerLipBottom', 'lowerLipTop');
    }
    canvas.restore();
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
      eyelinerColor != oldDelegate.eyelinerColor ||
      mascaraColor != oldDelegate.mascaraColor ||
      highlighterIntensity != oldDelegate.highlighterIntensity ||
      contours != oldDelegate.contours ||
      face != oldDelegate.face;
}
