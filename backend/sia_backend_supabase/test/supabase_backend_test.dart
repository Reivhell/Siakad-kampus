import 'package:test/test.dart';
import 'package:sia_backend_core/sia_backend_core.dart';
import 'package:sia_backend_supabase/supabase_backend.dart';

void main() {
  test('SupabaseBackend mengimplementasikan semua kontrak repository', () {
    // Konstruksi tidak menjalankan jaringan; cukup memeriksa tipe.
    final backend = SupabaseBackend(
      url: 'http://localhost:54321',
      serviceRoleKey: 'test-service-role-key-0123456789abcdef',
    );

    expect(backend, isA<AuthRepository>());
    expect(backend, isA<UserRepository>());
    expect(backend, isA<MasterRepository>());
    expect(backend, isA<CivitasRepository>());
    expect(backend, isA<DashboardRepository>());
    expect(backend, isA<AuditRepository>());
  });

  test('SupabaseBackend gagal dibuat tanpa URL dan kunci service role', () {
    expect(
      () => SupabaseBackend(url: '', serviceRoleKey: 'k'),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => SupabaseBackend(url: 'http://x', serviceRoleKey: ''),
      throwsA(isA<ArgumentError>()),
    );
  });
}
