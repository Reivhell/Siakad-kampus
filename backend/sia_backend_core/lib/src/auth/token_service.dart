import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../exceptions/app_exception.dart';
import '../models/app_user.dart';

class TokenClaims {
  const TokenClaims({
    required this.sub,
    required this.roles,
    required this.expiresAt,
    required this.issuedAt,
  });

  final String sub;
  final List<String> roles;
  final DateTime expiresAt;
  final DateTime issuedAt;
}

class TokenService {
  TokenService(this.secret, {this.ttl = const Duration(hours: 12)}) {
    if (secret.length < 32) {
      throw ArgumentError('JWT secret minimal 32 karakter.');
    }
  }

  final String secret;
  final Duration ttl;

  AuthResult issue(AppUser user) {
    final now = DateTime.now().toUtc();
    final expires = now.add(ttl);
    final header = _encode({'alg': 'HS256', 'typ': 'JWT'});
    final payload = _encode({
      'sub': user.id,
      'email': user.email,
      'roles': user.roles,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': expires.millisecondsSinceEpoch ~/ 1000,
    });
    final body = '$header.$payload';
    final signature = _sign(body);
    return AuthResult(
      token: '$body.$signature',
      expiresAt: expires,
      user: user,
    );
  }

  TokenClaims verify(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const UnauthorizedException('Format token salah.');
    }

    final expected = _sign('${parts[0]}.${parts[1]}');
    if (!_constantTimeEquals(expected, parts[2])) {
      throw const UnauthorizedException('Tanda tangan token salah.');
    }

    final Map<String, Object?> payload;
    try {
      payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
          as Map<String, Object?>;
    } on FormatException {
      throw const UnauthorizedException('Payload token rusak.');
    }

    final exp = (payload['exp'] as num?)?.toInt() ?? 0;
    final iat = (payload['iat'] as num?)?.toInt() ?? 0;
    final sub = payload['sub'] as String?;
    if (sub == null || sub.isEmpty) {
      throw const UnauthorizedException('Token tanpa subjek.');
    }
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    if (expiresAt.isBefore(DateTime.now().toUtc())) {
      throw const UnauthorizedException('Token kedaluwarsa.');
    }

    final roles = (payload['roles'] as List<Object?>?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];

    return TokenClaims(
      sub: sub,
      roles: roles,
      expiresAt: expiresAt,
      issuedAt: DateTime.fromMillisecondsSinceEpoch(iat * 1000, isUtc: true),
    );
  }

  String _sign(String body) {
    final digest = Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(body));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  String _encode(Map<String, Object?> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
