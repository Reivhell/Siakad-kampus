import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:siakad_kampus/app/theme/siakad_theme.dart';

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final hi = math.max(_lum(a), _lum(b));
  final lo = math.min(_lum(a), _lum(b));
  return (hi + 0.05) / (lo + 0.05);
}

/// Kontras pasangan M3 aktual (teresolusi dari theme, bukan tebakan hex):
/// tile terpilih, indikator nav, search/chip, container primer.
void main() {
  for (final mode in [Brightness.light, Brightness.dark]) {
    testWidgets('M3 pairs AA — $mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SiakadTheme.light,
          darkTheme: SiakadTheme.dark,
          themeMode: mode == Brightness.light
              ? ThemeMode.light
              : ThemeMode.dark,
          home: const Scaffold(body: SizedBox()),
        ),
      );
      final theme = Theme.of(
        tester.element(find.byType(Scaffold)),
      );
      final cs = theme.colorScheme;
      // Warna teks tile terpilih = ListTileTheme.selectedColor (fallback M3: primary).
      final selectedText =
          theme.listTileTheme.selectedColor ?? cs.primary;
      expect(_contrast(selectedText, cs.secondaryContainer), greaterThanOrEqualTo(4.5),
          reason: 'selected tile text');
      expect(_contrast(cs.onSecondaryContainer, cs.secondaryContainer),
          greaterThanOrEqualTo(4.5),
          reason: 'nav indicator content');
      expect(_contrast(cs.onSurface, cs.surfaceContainerHigh),
          greaterThanOrEqualTo(4.5),
          reason: 'search/chip surface');
      expect(_contrast(cs.onPrimaryContainer, cs.primaryContainer),
          greaterThanOrEqualTo(4.5),
          reason: 'primary container content');
      expect(_contrast(cs.onSurface, cs.surface), greaterThanOrEqualTo(4.5),
          reason: 'body text');
    });
  }
}
