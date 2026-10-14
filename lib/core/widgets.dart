import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

Widget card(Widget child, {Color color = Colors.white}) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(22),
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(26),
    border: Border.all(color: border),
    boxShadow: const [
      BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 5)),
    ],
  ),
  child: child,
);
Widget action(
  String text,
  VoidCallback? onTap, {
  bool secondary = false,
  IconData icon = Icons.arrow_forward,
}) => Opacity(
  opacity: onTap == null ? .45 : 1,
  child: InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
      decoration: BoxDecoration(
        color: secondary ? Colors.white : primary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: secondary ? border : primary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: secondary ? primary : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(icon, color: secondary ? primary : Colors.white),
        ],
      ),
    ),
  ),
);
Widget notice(String s, {bool error = false}) => Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: error ? const Color(0xFFFBE8EC) : soft,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        error ? Icons.error_outline : Icons.shield_outlined,
        color: error ? Colors.red : primary,
        size: 20,
      ),
      const SizedBox(width: 10),
      Expanded(child: copy(s, size: 12)),
    ],
  ),
);
