import 'package:flutter/material.dart';

/// Dialog adaptif: AlertDialog di desktop/tablet, bottom sheet di mobile.
/// Lebar max 560 agar form tetap ramping di web.
Future<T?> showAdminForm<T>({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(child: child),
      ),
    ),
  );
}

/// Konfirmasi destruktif — wajib ketik [keyword] (default KONFIRMASI).
/// Spec 02 §8.3: cegah klik tak sengaja saat reset/deaktivasi.
class ConfirmKeywordDialog extends StatefulWidget {
  final String title;
  final String message;
  final String keyword;
  final String confirmLabel;

  const ConfirmKeywordDialog({
    super.key,
    required this.title,
    required this.message,
    this.keyword = 'KONFIRMASI',
    this.confirmLabel = 'Eksekusi',
  });

  @override
  State<ConfirmKeywordDialog> createState() => _ConfirmKeywordDialogState();
}

class _ConfirmKeywordDialogState extends State<ConfirmKeywordDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 12),
          Text(
            'Ketik "${widget.keyword}" untuk konfirmasi:',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _c,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'KONFIRMASI',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _c.text.trim() == widget.keyword
              ? () => Navigator.pop(context, true)
              : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
