import "../../core/theme.dart";
import "../../core/widgets.dart";
import "package:flutter/material.dart";

class Home extends StatelessWidget {
  final VoidCallback onConsult, onStudio, onPrivacy;
  final VoidCallback? onResults;
  const Home({
    super.key,
    required this.onConsult,
    required this.onStudio,
    required this.onPrivacy,
    this.onResults,
  });
  @override
  Widget build(BuildContext c) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              title('Glow', size: 29),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: primary),
                  const SizedBox(width: 5),
                  copy('MADE FOR YOU', size: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF4DCE5), bg, Color(0xFFF4E6D5)],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                eyebrow('YOUR EVERYDAY BEAUTY RITUAL'),
                const SizedBox(height: 16),
                title('Your beauty.\nYour kind of glow.', size: 41),
                const SizedBox(height: 16),
                copy(
                  'A personal makeup artist and style advisor, inspired by everything that makes you, you.',
                ),
                const SizedBox(height: 28),
                action('Create my look', onConsult),
                const SizedBox(height: 12),
                Center(
                  child: copy(
                    'PERSONALISED SHADES · THOUGHTFUL STYLE',
                    size: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          eyebrow('THE GLOWAI STUDIO'),
          const SizedBox(height: 6),
          title('Try a little possibility.', size: 27),
          const SizedBox(height: 14),
          card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.palette_outlined,
                      color: Color(0xFFE8A0B4),
                      size: 34,
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title('Virtual makeup', size: 22, color: Colors.white),
                        copy(
                          'Your portrait. Endless shades.',
                          size: 12,
                          color: const Color(0xFFEAD4DE),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                copy(
                  'Explore lipstick, soft blush and expressive eyes — right on your photo.',
                  color: const Color(0xFFEAD4DE),
                ),
                const SizedBox(height: 16),
                action(
                  'Enter the studio',
                  onStudio,
                  secondary: true,
                  icon: Icons.auto_fix_high,
                ),
              ],
            ),
            color: plum,
          ),
          if (onResults != null) ...[
            const SizedBox(height: 14),
            action(
              'Revisit my current look',
              onResults,
              secondary: true,
              icon: Icons.favorite_border,
            ),
          ],
          const SizedBox(height: 22),
          notice(
            'You’re in control. AI consultations use your shared photo. Virtual makeup stays on your device.',
          ),
          const SizedBox(height: 14),
          action(
            'Privacy & about Glow AI',
            onPrivacy,
            secondary: true,
            icon: Icons.info_outline,
          ),
        ],
      ),
    ),
  );
}
