import "../../core/theme.dart";
import "../../core/widgets.dart";
import "../../models/recommendation.dart";
import "package:flutter/material.dart";

class Results extends StatelessWidget {
  final Recommendation result;
  final VoidCallback onStudio;
  const Results({super.key, required this.result, required this.onStudio});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: copy('Your beauty edit', color: ink)),
    body: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        eyebrow('YOUR PERSONAL BEAUTY EDIT'),
        const SizedBox(height: 8),
        title('A look that feels\nlike you.'),
        const SizedBox(height: 14),
        copy(result.overall),
        const SizedBox(height: 18),
        notice(
          'AI is unavailable. These are curated suggestions based on your preferences; your photo has not been analysed.',
        ),
        const SizedBox(height: 16),
        action('Try this look', onStudio, icon: Icons.auto_fix_high),
        const SizedBox(height: 20),
        ...result.sections.entries.map(
          (e) => _ResultSection(
            title: e.key == 'hair_hijab'
                ? 'Hair & hijab'
                : e.key.replaceAll('_', ' '),
            data: e.value,
          ),
        ),
        const SizedBox(height: 12),
        action('Create another look', () => Navigator.pop(c), secondary: true),
      ],
    ),
  );
}

class _ResultSection extends StatefulWidget {
  final String title;
  final Map<String, String> data;
  const _ResultSection({required this.title, required this.data});
  @override
  State<_ResultSection> createState() => _ResultSectionState();
}

class _ResultSectionState extends State<_ResultSection> {
  bool open = true;
  @override
  Widget build(BuildContext c) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => open = !open),
            child: Row(
              children: [
                Icon(_sectionIcon(widget.title), color: primary),
                const SizedBox(width: 12),
                Expanded(child: title(widget.title, size: 22)),
                Icon(
                  open ? Icons.expand_less : Icons.expand_more,
                  color: muted,
                ),
              ],
            ),
          ),
          if (open)
            ...widget.data.entries
                .where((e) => e.value.isNotEmpty && !e.key.endsWith('hex'))
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        eyebrow(e.key.replaceAll('_', ' ')),
                        copy(e.value),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    ),
  );
}

IconData _sectionIcon(String title) {
  final normalized = title.toLowerCase();
  if (normalized.contains('eye')) return Icons.remove_red_eye_outlined;
  if (normalized.contains('lip')) return Icons.face_retouching_natural;
  if (normalized.contains('face') || normalized.contains('skin')) {
    return Icons.face_6_outlined;
  }
  if (normalized.contains('outfit')) return Icons.checkroom_outlined;
  if (normalized.contains('accessor')) return Icons.diamond_outlined;
  if (normalized.contains('hair') || normalized.contains('hijab')) {
    return Icons.style_outlined;
  }
  if (normalized.contains('lens')) return Icons.visibility_outlined;
  if (normalized.contains('brand')) return Icons.shopping_bag_outlined;
  return Icons.auto_awesome;
}
