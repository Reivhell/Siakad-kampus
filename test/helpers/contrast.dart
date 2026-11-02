import 'dart:math' as math;

import 'package:flutter/material.dart';

double luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

/// Rasio kontras WCAG 2.x antara dua warna (1..21).
double contrast(Color a, Color b) {
  final hi = math.max(luminance(a), luminance(b));
  final lo = math.min(luminance(a), luminance(b));
  return (hi + 0.05) / (lo + 0.05);
}

/// Ambang WCAG AA: 3.0 untuk teks besar (>=24px, atau >=18.66px bold),
/// 4.5 untuk teks normal.
double minimumContrastFor({required double fontSize, required bool bold}) {
  final large = fontSize >= 24 || (fontSize >= 18.66 && bold);
  return large ? 3.0 : 4.5;
}
