import "../../core/theme.dart";
import "../../core/widgets.dart";
import "../../ai_service.dart";
import "../../app.dart";
import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
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
    'A little atmosphere.',
  ];
  final subtitles = [
    'A portrait helps us personalise your consultation.',
    'Tell us what you know. We’ll take it from here.',
    'From everyday rituals to unforgettable celebrations.',
    'The details that make this look yours.',
    'We’ll find the shades that belong together.',
    'A beautiful look can begin with what you already own.',
    'Make your look work with the weather.',
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
    final p = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (p != null) setState(() => widget.state.photo = p);
  }

  Widget choices(List<List<String>> values, String selected, String key) =>
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: values
            .map(
              (v) => ChoiceChip(
                label: Text(v[1]),
                selected: selected == v[0],
                selectedColor: primary,
                labelStyle: TextStyle(
                  color: selected == v[0] ? Colors.white : ink,
                ),
                onSelected: (_) => setValue(key, v[0]),
              ),
            )
            .toList(),
      );
  Future<void> next() async {
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
    final hasAiKey = (dotenv.env['GEMINI_API_KEY'] ?? '').trim().isNotEmpty;
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              eyebrow('YOUR PERSONAL BEAUTY CONSULTATION'),
              const SizedBox(height: 30),
              const CircularProgressIndicator(color: primary),
              const SizedBox(height: 25),
              title('Creating your Glow AI look…', size: 25),
              copy('A considered look, created around you.'),
            ],
          ),
        ),
      );
    }
    final p = widget.state.profile;
    return Scaffold(
      appBar: AppBar(title: copy('Create your look', color: ink)),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              eyebrow('YOUR BEAUTY CONSULTATION'),
              copy('${(step + 1).toString().padLeft(2, '0')} / 07'),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (step + 1) / 7,
            color: primary,
            backgroundColor: border,
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
                  : 'Choose your skin tone for a consultation without a photo.',
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
            Wrap(
              spacing: 13,
              runSpacing: 14,
              children:
                  [
                        '#1A1A1A',
                        '#FFFFFF',
                        '#C0392B',
                        '#001F5B',
                        '#27AE60',
                        '#50C878',
                        '#C9A96E',
                        '#E1AD01',
                        '#8E44AD',
                        '#D4A0C0',
                        '#FF00A0',
                        '#008080',
                        '#98FF98',
                        '#800000',
                        '#6B3A5A',
                        '#2980B9',
                      ]
                      .map(
                        (x) => GestureDetector(
                          onTap: () => setValue('outfit', x),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(x.substring(1), radix: 16) |
                                    0xFF000000,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: p.outfit == x ? primary : border,
                                width: p.outfit == x ? 3 : 1,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
          if (step == 5)
            TextField(
              maxLines: 6,
              maxLength: 2000,
              onChanged: (v) => p.owned = v,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText:
                    'My favourite rose lipstick, gold jhumkas, an emerald kurta…',
                border: OutlineInputBorder(),
              ),
            ),
          if (step == 6) ...[
            card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title('Ready for your day.', size: 24),
                  copy(
                    'Weather is unavailable offline. Your look can continue without it.',
                  ),
                  const SizedBox(height: 12),
                  action('Continue without weather', () {}),
                ],
              ),
            ),
            const SizedBox(height: 14),
            notice(
              widget.state.photo != null
                  ? 'Your portrait and preferences stay on this device.'
                  : 'Your preferences stay on this device. No photo will be uploaded.',
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
              const Icon(
                Icons.face_retouching_natural,
                size: 48,
                color: primary,
              ),
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
          ),
        ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: action(
              'Take photo',
              onCamera,
              icon: Icons.camera_alt_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: action(
              'Choose from gallery',
              onGallery,
              secondary: true,
              icon: Icons.photo_library_outlined,
            ),
          ),
        ],
      ),
    ],
  );
}
