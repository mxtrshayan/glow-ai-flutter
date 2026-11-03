import "../../core/theme.dart";
import "../../core/widgets.dart";
import "../../core/color_picker.dart";
import "../../ai_service.dart";
import "../../app.dart";
import "package:flutter/material.dart";
import "package:image_picker/image_picker.dart";
import "dart:io";

class Consultation extends StatefulWidget {
  final GlowAppState state;
  final VoidCallback onComplete;
  const Consultation({
    super.key,
    required this.state,
    required this.onComplete,
  });
  @override
  State<Consultation> createState() => _ConsultationState();
}

class _ConsultationState extends State<Consultation> {
  int step = 0;
  String error = '';
  bool busy = false;
  final picker = ImagePicker();
  final titles = [
    'Let’s start with you.',
    'Your skin, understood.',
    'What’s the occasion?',
    'Make it your style.',
    'A colour story.',
    'Shop your own collection.',
    'Ready for your look.',
  ];
  final subtitles = [
    'Add a portrait for the makeup studio, or continue without one.',
    'Tell us what you know. We’ll take it from here.',
    'From everyday rituals to unforgettable celebrations.',
    'The details that make this look yours.',
    'We’ll find the shades that belong together.',
    'A beautiful look can begin with what you already own.',
    'Review your choices and create your look.',
  ];
  void setValue(String k, String v) {
    setState(() {
      if (k == 'skinTone') widget.state.profile.skinTone = v;
      if (k == 'undertone') widget.state.profile.undertone = v;
      if (k == 'skinType') widget.state.profile.skinType = v;
      if (k == 'event') widget.state.profile.event = v;
      if (k == 'time') widget.state.profile.time = v;
      if (k == 'style') widget.state.profile.style = v;
      if (k == 'hijab') widget.state.profile.hijab = v;
      if (k == 'outfit') widget.state.profile.outfit = v;
      error = '';
    });
  }

  Future<void> photo(ImageSource source) async {
    try {
      final p = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );
      if (!mounted || p == null) return;
      widget.state.setState(() => widget.state.photo = p);
      setState(() => error = '');
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Could not open the camera or gallery. Check permissions and try again.',
        );
      }
    }
  }

  Widget choices(List<List<String>> values, String selected, String key) =>
      DropdownButtonFormField<String>(
        key: ValueKey('choice-$key'),
        value: values.any((value) => value[0] == selected) ? selected : null,
        isExpanded: true,
        itemHeight: null,
        menuMaxHeight: 320,
        borderRadius: BorderRadius.circular(16),
        dropdownColor: surfaceOf(context),
        icon: Icon(Icons.expand_more, color: accentOf(context)),
        decoration: InputDecoration(
          filled: true,
          fillColor: surfaceOf(context),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderOf(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: borderOf(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accentOf(context), width: 1.5),
          ),
        ),
        hint: Text(switch (key) {
          'skinTone' => 'Choose skin tone',
          'undertone' => 'Choose undertone',
          'skinType' => 'Choose skin type',
          'event' => 'Choose occasion',
          _ => 'Choose an option',
        }),
        items: values
            .map(
              (value) => DropdownMenuItem(
                value: value[0],
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(value[1]),
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) setValue(key, value);
        },
      );
  Future<void> next() async {
    if (busy) return;
    final p = widget.state.profile;
    if (step == 1 && widget.state.photo == null && p.skinTone.isEmpty) {
      setState(() => error = 'Choose a skin tone, or go back and add a photo.');
      return;
    }
    if (step == 2 && p.event.isEmpty) {
      setState(() => error = 'Choose an occasion to continue.');
      return;
    }
    if (step < 6) {
      setState(() {
        step++;
        error = '';
      });
      return;
    }
    if (p.event.isEmpty || (widget.state.photo == null && p.skinTone.isEmpty)) {
      setState(() => error = 'Complete the required choices to continue.');
      return;
    }
    setState(() => busy = true);
    final hasAiKey = AiService.isConfigured;
    if (!hasAiKey) {
      widget.state.setState(() {
        widget.state.result = widget.state.fallback.create(p);
      });
      if (mounted) widget.onComplete();
      return;
    }
    final ai = await const AiService().generate(p.toJson());
    if (!mounted) return;
    widget.state.setState(() {
      widget.state.result =
          recommendationFromAi(ai ?? {}) ?? widget.state.fallback.create(p);
    });
    widget.onComplete();
  }

  @override
  Widget build(BuildContext c) {
    if (busy) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  eyebrow('YOUR PERSONAL BEAUTY CONSULTATION'),
                  const SizedBox(height: 30),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 25),
                  title('Creating your Glow AI look…', size: 25),
                  copy('A considered look, created around you.'),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final p = widget.state.profile;
    return Scaffold(
      appBar: AppBar(title: copy('Create your look', color: inkOf(context))),
      body: responsiveBody(
        ListView(
          key: ValueKey(step),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(22),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: eyebrow('YOUR BEAUTY CONSULTATION')),
                copy('${(step + 1).toString().padLeft(2, '0')} / 07'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (step + 1) / 7,
              color: accentOf(context),
              backgroundColor: borderOf(context),
            ),
            const SizedBox(height: 24),
            title(titles[step]),
            const SizedBox(height: 10),
            copy(subtitles[step]),
            const SizedBox(height: 22),
            if (step == 0) ...[
              _PhotoCard(
                photo: widget.state.photo,
                onGallery: () => photo(ImageSource.gallery),
                onCamera: () => photo(ImageSource.camera),
              ),
              const SizedBox(height: 14),
              notice(
                widget.state.photo == null
                    ? 'Choose a clear portrait, or continue without a photo.'
                    : 'Your portrait stays on this device.',
              ),
            ],
            if (step == 1) ...[
              notice(
                widget.state.photo != null
                    ? 'Your portrait stays on this device. These choices are optional.'
                    : 'Choose a skin tone to continue. Undertone and skin type are optional.',
              ),
              const SizedBox(height: 16),
              choices(
                [
                  'Porcelain',
                  'Very Fair',
                  'Fair',
                  'Light',
                  'Light Medium',
                  'Medium / Wheatish',
                  'Tan',
                  'Brown',
                  'Deep',
                  'Rich',
                ].map((x) => [x.toLowerCase(), x]).toList(),
                p.skinTone,
                'skinTone',
              ),
              const SizedBox(height: 18),
              eyebrow('UNDERTONE'),
              choices(
                [
                  'Warm',
                  'Cool',
                  'Neutral',
                  'Olive',
                ].map((x) => [x.toLowerCase(), x]).toList(),
                p.undertone,
                'undertone',
              ),
              const SizedBox(height: 18),
              eyebrow('SKIN TYPE'),
              choices(
                [
                  'Oily',
                  'Dry',
                  'Combination',
                  'Sensitive',
                  'Normal',
                ].map((x) => [x.toLowerCase(), x]).toList(),
                p.skinType,
                'skinType',
              ),
            ],
            if (step == 2)
              choices(
                [
                      'wedding',
                      'mehndi',
                      'dholki',
                      'eid',
                      'valima',
                      'everyday',
                      'university',
                      'office',
                      'shopping',
                      'party',
                      'date',
                      'photoshoot',
                      'festival',
                    ]
                    .map(
                      (x) => [
                        x,
                        x == 'everyday'
                            ? 'Everyday / Casual'
                            : '${x[0].toUpperCase()}${x.substring(1)}',
                      ],
                    )
                    .toList(),
                p.event,
                'event',
              ),
            if (step == 3) ...[
              eyebrow('TIME OF DAY'),
              choices(
                [
                  ['morning', 'Morning'],
                  ['day', 'Daytime'],
                  ['evening', 'Evening'],
                  ['night', 'Night'],
                ],
                p.time,
                'time',
              ),
              const SizedBox(height: 18),
              eyebrow('STYLE PREFERENCE'),
              choices(
                [
                  ['traditional', 'Traditional Pakistani'],
                  ['both', 'A little of both'],
                  ['western', 'Western'],
                ],
                p.style,
                'style',
              ),
              const SizedBox(height: 18),
              eyebrow('DO YOU WEAR HIJAB?'),
              choices(
                [
                  ['yes', 'Yes · hijab styling'],
                  ['no', 'No · hair styling'],
                ],
                p.hijab,
                'hijab',
              ),
            ],
            if (step == 4) ...[
              copy('Choose the colour you are wearing'),
              const SizedBox(height: 12),
              action(
                'Choose outfit colour',
                () async {
                  final selected = await showMakeupColorPicker(
                    context,
                    label: 'Outfit colour',
                    initialColor: Color(
                      int.parse(p.outfit.substring(1), radix: 16) | 0xFF000000,
                    ),
                  );
                  if (mounted && selected != null) {
                    setValue('outfit', '#${colorHex(selected)}');
                  }
                },
                secondary: true,
                icon: Icons.palette_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(p.outfit.substring(1), radix: 16) |
                            0xFF000000,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: border),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: copy('Your selected colour')),
                ],
              ),
            ],
            if (step == 5)
              TextFormField(
                initialValue: p.owned,
                maxLines: 6,
                maxLength: 2000,
                onChanged: (v) => p.owned = v,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: surfaceOf(context),
                  hintText:
                      'My favourite rose lipstick, gold jhumkas, an emerald kurta…',
                  border: const OutlineInputBorder(),
                ),
              ),
            if (step == 6) ...[
              card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title('Ready for your day.', size: 24),
                    copy(
                      'Your ${p.event} look will coordinate with your chosen outfit and preferences.',
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              notice(
                widget.state.photo != null
                    ? 'Your portrait stays on this device. If AI is configured, your preferences are sent to Gemini.'
                    : 'If AI is configured, your preferences are sent to Gemini. No photo will be uploaded.',
              ),
            ],
            if (error.isNotEmpty) ...[
              const SizedBox(height: 14),
              notice(error, error: true),
            ],
            const SizedBox(height: 22),
            action(
              step == 6
                  ? 'Create my look'
                  : (step == 0 && widget.state.photo == null
                        ? 'Continue without photo'
                        : 'Continue'),
              next,
            ),
            if (step > 0) ...[
              const SizedBox(height: 12),
              action(
                'Back',
                () => setState(() {
                  step--;
                  error = '';
                }),
                secondary: true,
                icon: Icons.arrow_back,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final XFile? photo;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  const _PhotoCard({
    this.photo,
    required this.onGallery,
    required this.onCamera,
  });
  @override
  Widget build(BuildContext c) => Column(
    children: [
      if (photo == null)
        card(
          Column(
            children: [
              Icon(Icons.face_retouching_natural, size: 48, color: accentOf(c)),
              title('A little more you.', size: 24),
              copy('Choose a clear, front-facing portrait', size: 13),
            ],
          ),
        )
      else
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.file(
            File(photo!.path),
            height: 280,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (_, error, stackTrace) => notice(
              'This photo could not be opened. Choose another image.',
              error: true,
            ),
          ),
        ),
      const SizedBox(height: 14),
      photoActions(onCamera: onCamera, onGallery: onGallery),
    ],
  );
}
