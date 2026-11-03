import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class Settings extends StatelessWidget {
  final bool darkMode;
  final ValueChanged<bool> onDarkMode;
  final VoidCallback onPrivacy;
  final Future<void> Function() onClear;
  const Settings({
    super.key,
    required this.darkMode,
    required this.onDarkMode,
    required this.onPrivacy,
    required this.onClear,
  });

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Clear your data?'),
        content: const Text(
          'This removes your current photo, consultation choices and recommendations, and resets the theme to light. Images you downloaded stay in your chosen save location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear data'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await onClear();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your app data has been cleared.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: responsiveBody(
      ListView(
        padding: const EdgeInsets.all(22),
        children: [
          eyebrow('MAKE GLOW YOURS'),
          const SizedBox(height: 8),
          title('Settings'),
          const SizedBox(height: 8),
          copy('Your appearance. Your privacy. Your choice.'),
          const SizedBox(height: 24),
          card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title('Appearance', size: 23),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    Icons.dark_mode_outlined,
                    color: accentOf(context),
                  ),
                  title: const Text('Dark mode'),
                  subtitle: const Text('A softer glow for low light.'),
                  value: darkMode,
                  onChanged: onDarkMode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          card(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title('Privacy & data', size: 23),
                const SizedBox(height: 16),
                action(
                  'Privacy policy & about',
                  onPrivacy,
                  secondary: true,
                  icon: Icons.shield_outlined,
                ),
                const SizedBox(height: 12),
                action(
                  'Clear my data',
                  () => _confirmClear(context),
                  secondary: true,
                  icon: Icons.delete_outline,
                ),
                const SizedBox(height: 12),
                copy(
                  'Your portrait stays on your device. You decide when to clear your session.',
                  size: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(child: copy('Glow AI · Made for your kind of glow', size: 11)),
        ],
      ),
    ),
  );
}
