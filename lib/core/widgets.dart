import 'package:flutter/material.dart';
import 'theme.dart';

Widget card(Widget child, {Color? color}) => Builder(
  builder: (context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: color ?? surfaceOf(context),
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: borderOf(context)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 18,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  ),
);
Widget action(
  String text,
  VoidCallback? onTap, {
  bool secondary = false,
  IconData icon = Icons.arrow_forward,
}) => Builder(
  builder: (context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        backgroundColor: secondary ? surfaceOf(context) : accentOf(context),
        foregroundColor: secondary
            ? accentOf(context)
            : Theme.of(context).colorScheme.onPrimary,
        disabledBackgroundColor: secondary
            ? surfaceOf(context)
            : accentOf(context).withValues(alpha: .45),
        side: BorderSide(
          color: secondary ? borderOf(context) : accentOf(context),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text)),
          const SizedBox(width: 10),
          Icon(icon, size: 22),
        ],
      ),
    ),
  ),
);

Widget photoActions({
  required VoidCallback? onCamera,
  required VoidCallback? onGallery,
}) => IntrinsicHeight(
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: action('Camera', onCamera, icon: Icons.camera_alt_outlined),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: action(
          'Photos',
          onGallery,
          secondary: true,
          icon: Icons.photo_library_outlined,
        ),
      ),
    ],
  ),
);
Widget notice(String s, {bool error = false}) => Builder(
  builder: (context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: error
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          error ? Icons.error_outline : Icons.shield_outlined,
          color: error
              ? Theme.of(context).colorScheme.error
              : accentOf(context),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(child: copy(s, size: 12)),
      ],
    ),
  ),
);

Widget responsiveBody(Widget child, {double maxWidth = 820}) => SafeArea(
  top: false,
  child: Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  ),
);
