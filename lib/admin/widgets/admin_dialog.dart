import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

bool _isApple(BuildContext context) {
  final p = Theme.of(context).platform;
  return p == TargetPlatform.iOS || p == TargetPlatform.macOS;
}

/// Dialog adaptif: AlertDialog di desktop/tablet, bottom sheet di mobile.
/// Lebar max 560 agar form tetap ramping di web.
Future<T?> showAdminForm<T>({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) {
    if (_isApple(context)) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: Text(title),
          message: SingleChildScrollView(child: child),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ),
      );
    }
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
  if (_isApple(context)) {
    return showCupertinoDialog<T>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: child),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
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
    final ok = _c.text.trim() == widget.keyword;
    final field = _isApple(context)
        ? CupertinoTextField(
            controller: _c,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            maxLength: 20,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (ok) Navigator.pop(context, true);
            },
            placeholder: 'KONFIRMASI',
          )
        : TextField(
            controller: _c,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            maxLength: 20,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_c.text.trim() == widget.keyword) {
                Navigator.pop(context, true);
              }
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'KONFIRMASI',
              counterText: '',
            ),
          );
    if (_isApple(context)) {
      return CupertinoAlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.message),
            const SizedBox(height: 12),
            field,
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: ok ? () => Navigator.pop(context, true) : null,
            child: Text(widget.confirmLabel),
          ),
        ],
      );
    }
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: 12),
          Text(
            'Ketik "${widget.keyword}" untuk lanjut:',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _c,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            maxLength: 20,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_c.text.trim() == widget.keyword) {
                Navigator.pop(context, true);
              }
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'KONFIRMASI',
              counterText: '',
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
