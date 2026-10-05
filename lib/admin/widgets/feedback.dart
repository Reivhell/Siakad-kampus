import 'package:flutter/material.dart';

/// Feedback jujur untuk aksi yang aktif penuh saat backend wiring
/// (cetak PDF, ekspor CSV, reminder massal, navigasi global).
/// QC: tidak ada tombol yang diam saat diketuk.
void soon(BuildContext context, String fitur) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$fitur — demo lokal. Aktif penuh saat backend wiring.'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void ok(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
  );
}
