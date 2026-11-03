import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'widgets.dart';

Future<Color?> showMakeupColorPicker(
  BuildContext context, {
  required String label,
  required Color initialColor,
}) => showDialog<Color>(
  context: context,
  builder: (_) => _ColorPicker(label: label, initialColor: initialColor),
);

String colorHex(Color color) =>
    color.toARGB32().toRadixString(16).substring(2).toUpperCase();

class _ColorPicker extends StatefulWidget {
  final String label;
  final Color initialColor;
  const _ColorPicker({required this.label, required this.initialColor});
  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  late HSVColor selected;
  late TextEditingController hex;
  @override
  void initState() {
    super.initState();
    selected = HSVColor.fromColor(widget.initialColor);
    hex = TextEditingController(text: colorHex(widget.initialColor));
  }

  @override
  void dispose() {
    hex.dispose();
    super.dispose();
  }

  void update(HSVColor value) => setState(() {
    selected = value;
    hex.text = colorHex(value.toColor());
  });
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    insetPadding: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            title(widget.label, size: 24),
            const SizedBox(height: 8),
            copy('Choose a shade or enter its colour code.', size: 12),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.6,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  void choose(Offset point) => update(
                    selected
                        .withSaturation(
                          (point.dx / constraints.maxWidth).clamp(0.0, 1.0),
                        )
                        .withValue(
                          (1 - point.dy / constraints.maxHeight).clamp(
                            0.0,
                            1.0,
                          ),
                        ),
                  );
                  return GestureDetector(
                    key: const ValueKey('colour-square'),
                    onPanDown: (event) => choose(event.localPosition),
                    onPanUpdate: (event) => choose(event.localPosition),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomPaint(
                        painter: _ShadePainter(selected),
                        size: Size.infinite,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            copy('Hue', size: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [
                        for (var hue = 0; hue <= 360; hue += 60)
                          HSVColor.fromAHSV(1, hue.toDouble(), 1, 1).toColor(),
                      ],
                    ),
                  ),
                ),
                Slider(
                  value: selected.hue,
                  max: 360,
                  label: '${selected.hue.round()}°',
                  semanticFormatterCallback: (v) => '${v.round()} degrees hue',
                  activeColor: Colors.transparent,
                  inactiveColor: Colors.transparent,
                  thumbColor: HSVColor.fromAHSV(
                    1,
                    selected.hue,
                    1,
                    1,
                  ).toColor(),
                  onChanged: (value) => update(selected.withHue(value)),
                ),
              ],
            ),
            copy('Saturation', size: 12),
            Slider(
              value: selected.saturation,
              onChanged: (v) => update(selected.withSaturation(v)),
            ),
            copy('Brightness', size: 12),
            Slider(
              value: selected.value,
              onChanged: (v) => update(selected.withValue(v)),
            ),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected.toColor(),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const ValueKey('colour-hex'),
                    controller: hex,
                    maxLength: 6,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Colour code',
                      prefixText: '#',
                      counterText: '',
                      filled: true,
                      fillColor: surfaceOf(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) => setState(() {
                      final rgb = int.tryParse(value, radix: 16);
                      if (value.length == 6 && rgb != null) {
                        selected = HSVColor.fromColor(Color(0xFF000000 | rgb));
                      }
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            action(
              'Apply colour',
              hex.text.length == 6
                  ? () => Navigator.pop(context, selected.toColor())
                  : null,
              icon: Icons.check,
            ),
            const SizedBox(height: 8),
            action(
              'Cancel',
              () => Navigator.pop(context),
              secondary: true,
              icon: Icons.close,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ShadePainter extends CustomPainter {
  final HSVColor selected;
  const _ShadePainter(this.selected);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..color = HSVColor.fromAHSV(1, selected.hue, 1, 1).toColor(),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Colors.transparent],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    final center = Offset(
      selected.saturation * size.width,
      (1 - selected.value) * size.height,
    );
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_ShadePainter oldDelegate) =>
      oldDelegate.selected != selected;
}
