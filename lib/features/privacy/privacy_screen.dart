import "../../core/theme.dart";
import "../../core/widgets.dart";
import "package:flutter/material.dart";

class Privacy extends StatelessWidget {
  final VoidCallback onClear;
  const Privacy({super.key, required this.onClear});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: copy('Privacy & about', color: ink)),
    body: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        title('Beauty, on your terms.'),
        const SizedBox(height: 18),
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title('Your photos', size: 24),
              copy(
                'Virtual makeup uses local face geometry. It does not identify you, and it does not send your studio portrait to a server.',
              ),
              const SizedBox(height: 12),
              copy(
                'When you create an AI look, your preferences may be sent to Gemini when configured. A look can always be created without a photo.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title('Your choices', size: 24),
              copy(
                'Camera and gallery permissions are requested only when needed. Your current portrait and consultation are held for this app session.',
              ),
              const SizedBox(height: 14),
              action(
                'Clear my current session',
                onClear,
                secondary: true,
                icon: Icons.delete_outline,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        copy('Glow AI · Your personal makeup artist and style advisor.'),
      ],
    ),
  );
}
