import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../models/recommendation.dart';
import 'package:flutter/material.dart';

const _essentials = ['lips', 'eyes', 'face'];
const _labels = {
  'lips': 'Lips',
  'eyes': 'Eyes',
  'face': 'Base & blush',
  'outfit': 'Outfit',
  'accessories': 'Accessories',
  'hair_hijab': 'Hair & hijab',
  'brands': 'Product suggestions',
  'lens': 'Contact lenses',
  'skin_analysis': 'Skin preferences',
};

class Results extends StatelessWidget {
  final Recommendation result;
  final VoidCallback onStudio;
  final VoidCallback onCreateAnother;
  const Results({
    super.key,
    required this.result,
    required this.onStudio,
    required this.onCreateAnother,
  });

  @override
  Widget build(BuildContext context) {
    final more = {
      for (final key in [
        'outfit',
        'accessories',
        'hair_hijab',
        'brands',
        'lens',
        'skin_analysis',
        ...result.sections.keys.where((key) => !_labels.containsKey(key)),
      ])
        if (result.sections.containsKey(key)) key: result.sections[key]!,
    };
    return Scaffold(
      appBar: AppBar(title: copy('Your beauty edit', color: inkOf(context))),
      body: responsiveBody(
        ListView(
          padding: const EdgeInsets.all(22),
          children: [
            eyebrow('YOUR MAKEUP ESSENTIALS'),
            const SizedBox(height: 8),
            title('Your look, made simple.'),
            const SizedBox(height: 12),
            copy(result.overall),
            const SizedBox(height: 20),
            action('Try this look', onStudio, icon: Icons.auto_fix_high),
            const SizedBox(height: 20),
            copy(
              'Start with these three. Tap a card for the details.',
              size: 12,
            ),
            const SizedBox(height: 12),
            for (final key in _essentials)
              if (result.sections.containsKey(key))
                _ResultSection(section: key, data: result.sections[key]!),
            if (more.isNotEmpty) ...[
              const SizedBox(height: 8),
              action(
                'See more categories',
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _MoreCategories(sections: more),
                  ),
                ),
                secondary: true,
                icon: Icons.add,
              ),
              const SizedBox(height: 8),
              copy(
                'Outfits, accessories and finishing touches — whenever you want them.',
                size: 12,
              ),
            ],
            const SizedBox(height: 24),
            action('Create another look', onCreateAnother, secondary: true),
            const SizedBox(height: 18),
            copy(
              '${result.fromAi ? 'AI-assisted' : 'Curated'} suggestions based on your preferences. Your photo has not been analysed for this consultation.',
              size: 11,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreCategories extends StatelessWidget {
  final Map<String, Map<String, String>> sections;
  const _MoreCategories({required this.sections});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: copy('More styling ideas', color: inkOf(context))),
    body: responsiveBody(
      ListView(
        padding: const EdgeInsets.all(22),
        children: [
          title('The finishing touches.'),
          const SizedBox(height: 10),
          copy(
            'Optional ideas to complete your look. Open only what interests you.',
          ),
          const SizedBox(height: 22),
          for (final entry in sections.entries)
            _ResultSection(
              section: entry.key,
              data: entry.value,
              showPreview: false,
            ),
        ],
      ),
    ),
  );
}

class _ResultSection extends StatelessWidget {
  final String section;
  final Map<String, String> data;
  final bool showPreview;
  const _ResultSection({
    required this.section,
    required this.data,
    this.showPreview = true,
  });

  @override
  Widget build(BuildContext context) {
    final entries = data.entries
        .where(
          (entry) =>
              entry.value.trim().isNotEmpty &&
              !entry.key.toLowerCase().endsWith('hex'),
        )
        .toList();
    final preferred = switch (section) {
      'lips' => 'shade',
      'eyes' => 'eyeshadow',
      'face' => 'blush',
      _ => '',
    };
    final preview =
        data[preferred] ??
        (entries.isNotEmpty ? entries.first.value : 'Explore your shade');
    final shade =
        data[switch (section) {
          'lips' => 'hex',
          'eyes' => 'eyeshadow_hex',
          _ => 'blush_hex',
        }];
    final hex = shade?.replaceFirst('#', '');
    final parsed = hex != null && hex.length == 6
        ? int.tryParse(hex, radix: 16)
        : null;
    final label = _labels[section] ?? section.replaceAll('_', ' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: surfaceOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderOf(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          key: PageStorageKey(section),
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: parsed == null
              ? Icon(_sectionIcon(section), color: accentOf(context))
              : Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Color(0xFF000000 | parsed),
                    shape: BoxShape.circle,
                    border: Border.all(color: border),
                  ),
                ),
          title: Text(
            label,
            style: TextStyle(
              color: inkOf(context),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: showPreview
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: copy(preview, size: 12),
                )
              : null,
          children: [
            for (final entry in entries.where(
              (entry) => !showPreview || entry.key != preferred,
            ))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      eyebrow(entry.key.replaceAll('_', ' ')),
                      copy(entry.value, size: 13),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

IconData _sectionIcon(String section) => switch (section) {
  'eyes' => Icons.remove_red_eye_outlined,
  'lips' => Icons.face_retouching_natural,
  'face' || 'skin_analysis' => Icons.face_6_outlined,
  'outfit' => Icons.checkroom_outlined,
  'accessories' => Icons.diamond_outlined,
  'hair_hijab' => Icons.style_outlined,
  'lens' => Icons.visibility_outlined,
  'brands' => Icons.shopping_bag_outlined,
  _ => Icons.auto_awesome,
};
