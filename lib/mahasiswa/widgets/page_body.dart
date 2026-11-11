import 'package:flutter/material.dart';

/// Pembungkus halaman: scroll + padding responsif + lebar maksimum.
class PageBody extends StatelessWidget {
  final List<Widget> children;
  final double maxWidth;

  const PageBody({super.key, required this.children, this.maxWidth = 1200});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = constraints.maxWidth < 600 ? 16.0 : 24.0;
        final spaced = <Widget>[];
        for (var i = 0; i < children.length; i++) {
          if (i > 0) spaced.add(const SizedBox(height: 16));
          spaced.add(children[i]);
        }
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: spaced,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Baris label–nilai untuk kartu profil/keuangan.
class InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const InfoLine({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
