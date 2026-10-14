import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const bg = Color(0xFFFDF6F9),
    ink = Color(0xFF2D1B26),
    muted = Color(0xFF735561);
const primary = Color(0xFF9D3F60),
    soft = Color(0xFFF9EEF2),
    border = Color(0xFFEDD5E0),
    plum = Color(0xFF462535);

Text title(String s, {double size = 32, Color color = ink}) => Text(
  s,
  style: GoogleFonts.playfairDisplay(
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.25,
  ),
);
Text copy(String s, {double size = 14, Color color = muted}) => Text(
  s,
  style: GoogleFonts.poppins(fontSize: size, color: color, height: 1.6),
);
Widget eyebrow(String s) => Text(
  s.toUpperCase(),
  style: GoogleFonts.poppins(
    fontSize: 10,
    letterSpacing: 2.2,
    color: primary,
    fontWeight: FontWeight.w600,
  ),
);
