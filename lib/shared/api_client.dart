import 'dart:convert';

import 'package:http/http.dart' as http;

/// Hasil login dari backend.
class LoginResult {
  const LoginResult({
    required this.npm,
    required this.token,
    required this.user,
  });

  final String npm;
  final String token;
  final Map<String, dynamic> user;
}

/// Klien API SIAKAD. Berkomunikasi dengan `sia_web_server` (dart_frog)
/// yang di belakangnya menggunakan [SupabaseBackend] / [PostgresBackend].
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  String? _token;

  /// Token JWT yang didapat dari login, bila ada.
  String? get token => _token;

  Future<LoginResult> login(String identifier, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );
    if (response.statusCode >= 400) {
      final error = _decode(response.body);
      throw Exception(
        (error is Map && error['error'] is String)
            ? error['error'] as String
            : 'Login gagal (HTTP ${response.statusCode}).',
      );
    }
    final data = _decode(response.body) as Map<String, dynamic>;
    final token = data['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Server tidak mengembalikan access token.');
    }
    _token = token;
    final user = (data['user'] as Map?)?.cast<String, dynamic>() ?? {};
    final npm = (user['email'] as String?) ?? identifier;
    return LoginResult(
      npm: npm,
      token: token,
      user: user.cast<String, Object?>(),
    );
  }

  /// Muat profil pengguna yang login (butuh token).
  Future<Map<String, dynamic>> me() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
    );
    if (response.statusCode >= 400) {
      throw Exception('Gagal memuat profil (HTTP ${response.statusCode}).');
    }
    return _decode(response.body) as Map<String, dynamic>;
  }

  void setToken(String? token) => _token = token;

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
  };

  Future<dynamic> getJson(String path) async {
    final response = await _client.get(
      Uri.parse('$baseUrl$path'),
      headers: _authHeaders,
    );
    return _handle(response);
  }

  Future<dynamic> postJson(String path, [Object? body]) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: _authHeaders,
      body: body == null ? null : jsonEncode(body),
    );
    return _handle(response);
  }

  Future<dynamic> patchJson(String path, [Object? body]) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl$path'),
      headers: _authHeaders,
      body: body == null ? null : jsonEncode(body),
    );
    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    if (response.statusCode >= 400) {
      final error = _decode(response.body);
      throw ApiException(
        (error is Map && error['error'] is String)
            ? error['error'] as String
            : 'Permintaan gagal (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    if (response.body.isEmpty) return null;
    return _decode(response.body);
  }

  void logout() => _token = null;

  dynamic _decode(String body) {
    final decoded = jsonDecode(body);
    return decoded;
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}
