import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan kunci-nilai sensitif (JWT token, payload sesi) untuk
/// autentikasi admin. Menggunakan [shared_preferences] sehingga bekerja di
/// Flutter Web, Windows, Linux, Android, dan iOS tanpa konfigurasi tambahan.
///
/// Untuk production dengan enkripsi at-rest (keystore/keychain), ganti
/// implementasi ini dengan [flutter_secure_storage] di [SecureStorage].
class SecureStorage {
  SecureStorage._();

  static SharedPreferences? _prefs;

  /// Pastikan SharedPreferences telah diinisialisasi (lazy init untuk uji).
  static Future<SharedPreferences> _ensurePrefs() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    return prefs;
  }

  /// Inisialisasi sekali saat aplikasi mulai.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Kunci untuk menyimpan JWT access token.
  static const _kToken = 'siakad.auth.access_token';
  /// Kunci untuk menyimpan payload sesi (JSON AppSession).
  static const _kSession = 'siakad.auth.session';

  /// Simpan token.
  static Future<bool> writeToken(String token) async {
    return (await _ensurePrefs()).setString(_kToken, token);
  }

  /// Baca token.
  static Future<String?> readToken() async {
    return (await _ensurePrefs()).getString(_kToken);
  }

  /// Hapus token.
  static Future<void> deleteToken() async {
    await (await _ensurePrefs()).remove(_kToken);
  }

  /// Simpan payload sesi (JSON).
  static Future<bool> writeSession(String sessionJson) async {
    return (await _ensurePrefs()).setString(_kSession, sessionJson);
  }

  /// Baca payload sesi (JSON).
  static Future<String?> readSession() async {
    return (await _ensurePrefs()).getString(_kSession);
  }

  /// Hapus payload sesi.
  static Future<void> deleteSession() async {
    await (await _ensurePrefs()).remove(_kSession);
  }

  /// Bersihkan semua data autentikasi.
  static Future<void> clear() async {
    await deleteToken();
    await deleteSession();
  }
}
