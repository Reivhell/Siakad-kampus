/// Validasi murni form login (tanpa Flutter agar mudah diuji).
/// Aturan NPM: tepat 10 digit angka (design.md §3, ERD `ck_npm_format`).
final _npmRe = RegExp(r'^[0-9]{10}$');

/// NPM harus 10 digit angka. Kembalikan pesan error atau null bila valid.
String? validateNpm(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return 'NPM wajib diisi.';
  if (!RegExp(r'^[0-9]+$').hasMatch(t)) return 'NPM hanya boleh angka.';
  if (t.length != 10) return 'NPM harus tepat 10 digit.';
  if (!_npmRe.hasMatch(t)) return 'Format NPM tidak valid.';
  return null;
}

/// Login hanya butuh sandi non-kosong; kebijakan kompleks milik server.
String? validateLoginPassword(String v) {
  if (v.isEmpty) return 'Kata sandi wajib diisi.';
  return null;
}

/// STUB pengganti Supabase Auth — selalu sukses setelah jeda.
/// Ganti dengan `supabase.auth.signInWithPassword` saat backend wiring.
Future<String?> fakeSignIn(String npm, String password) async {
  await Future.delayed(const Duration(milliseconds: 800));
  if (validateNpm(npm) != null) return 'NPM tidak dikenal.';
  if (validateLoginPassword(password) != null) return 'Kata sandi salah.';
  return null;
}
