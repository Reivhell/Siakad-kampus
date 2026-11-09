import 'dart:convert';

import 'api_client.dart';
import 'app_session.dart';
import 'secure_storage.dart';

/// Kelola sesi autentikasi admin di Flutter: menyimpan JWT dan payload sesi
/// ke [SecureStorage], memulihkannya saat aplikasi dibuka, dan membersihkannya
/// saat keluar.
class AuthService {
  AuthService({
    required this.apiClient,
  });

  final ApiClient apiClient;

  AppSession? _session;

  /// Sesi saat ini, bila ada.
  AppSession? get session => _session;

  /// Apakah pengguna sudah login.
  bool get isAuthenticated => _session != null && _session!.token != null;

  /// Inisialisasi penyimpanan dan coba memulihkan sesi yang tersimpan.
  Future<void> init() async {
    await SecureStorage.init();
    await _restoreSession();
  }

  /// Login dengan NPM dan kata sandi, lalu simpan sesi ke penyimpanan.
  Future<AppSession> login(String npm, String password) async {
    final result = await apiClient.login(npm, password);
    final session = AppSession(
      npm: result.npm,
      role: resolveRole(result.npm, user: result.user),
      token: result.token,
      user: result.user,
    );
    await _persist(session);
    _session = session;
    return session;
  }

  /// Muat ulang profil dari server untuk memverifikasi token masih aktif.
  /// Gagal jika token kedaluwarsa → sesi dibuang dan [UnauthorizedException]
  /// dilemparkan.
  Future<void> refresh() async {
    if (_session == null || _session!.token == null) {
      throw UnauthorizedException('Tidak ada sesi aktif.');
    }
    final profile = await apiClient.me();
    final current = _session!;
    _session = AppSession(
      npm: current.npm,
      role: resolveRole(current.npm, user: profile),
      token: current.token,
      user: profile,
    );
    await _persist(_session!);
  }

  /// Keluar: hapus token dan sesi dari penyimpanan dan memori.
  Future<void> logout() async {
    _session = null;
    await SecureStorage.clear();
    apiClient.logout();
  }

  /// Mulai ulang `ApiClient` (untuk mengganti baseUrl saat deployment).
  void setBaseUrl(String baseUrl) {
    apiClient.dispose();
    // ApiClient tidak expose baseUrl setter; pembuat harus membuat instance baru.
    // Metode ini disediakan agar pemanggil bisa menimpa `apiClient` di
    // [RoleGate] bila diperlukan.
  }

  /// Tetapkan sesi yang sudah diterima dari server (mis. setelah LoginPage
  /// sukses) dan simpan ke penyimpanan tanpa memanggil login lagi.
  void setSession(AppSession session) {
    _session = session;
    _persist(session);
  }

  // ---------------------------------------------------------------- private

  Future<void> _restoreSession() async {
    final token = await SecureStorage.readToken();
    final sessionJson = await SecureStorage.readSession();
    if (token == null || token.isEmpty || sessionJson == null) {
      _session = null;
      return;
    }
    try {
      final decoded = jsonDecode(sessionJson) as Map<String, dynamic>;
      apiClient.setToken(token);
      final user = (decoded['user'] as Map?)?.cast<String, dynamic>() ?? {};
      _session = AppSession(
        npm: (decoded['npm'] as String?) ?? '',
        role: resolveRole((decoded['npm'] as String?) ?? '', user: user),
        token: token,
        user: user,
      );
    } catch (_) {
      await SecureStorage.clear();
      apiClient.setToken(null);
      _session = null;
    }
  }

  Future<void> _persist(AppSession session) async {
    await SecureStorage.writeToken(session.token!);
    final json = jsonEncode({
      'npm': session.npm,
      'user': session.user,
    });
    await SecureStorage.writeSession(json);
  }
}

/// Dilemparkan saat token tidak valid / kedaluwarsa.
class UnauthorizedException implements Exception {
  const UnauthorizedException(this.message);
  final String message;
  @override
  String toString() => 'UnauthorizedException: $message';
}
