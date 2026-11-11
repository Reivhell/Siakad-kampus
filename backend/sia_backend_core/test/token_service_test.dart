import 'package:sia_backend_core/sia_backend_core.dart';
import 'package:test/test.dart';

void main() {
  const secret = 'test-secret-0123456789-abcdefghijklmnop';
  const user = AppUser(
    id: 'user-1',
    email: 'admin@kampus.ac.id',
    namaLengkap: 'Admin',
    roles: ['ADMIN'],
  );

  test('issues and verifies a token', () {
    final service = TokenService(secret);
    final result = service.issue(user);
    final claims = service.verify(result.token);

    expect(claims.sub, user.id);
    expect(claims.roles, ['ADMIN']);
    expect(claims.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
  });

  test('rejects a tampered token', () {
    final service = TokenService(secret);
    final token = service.issue(user).token;
    final parts = token.split('.');
    final tampered = '${parts[0]}.${parts[1]}.${parts[2].substring(0, parts[2].length - 2)}xx';

    expect(() => service.verify(tampered), throwsA(isA<UnauthorizedException>()));
  });

  test('rejects a token signed with another secret', () {
    final issuer = TokenService(secret);
    final verifier = TokenService('${secret}_other');
    final token = issuer.issue(user).token;

    expect(() => verifier.verify(token), throwsA(isA<UnauthorizedException>()));
  });

  test('rejects an expired token', () {
    final service = TokenService(secret, ttl: const Duration(seconds: -1));
    final token = service.issue(user).token;

    expect(() => service.verify(token), throwsA(isA<UnauthorizedException>()));
  });

  test('requires a long secret', () {
    expect(() => TokenService('short'), throwsArgumentError);
  });
}
