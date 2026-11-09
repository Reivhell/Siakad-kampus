import 'dart:io';

import 'package:sia_backend_core/sia_backend_core.dart';
import 'package:sia_backend_postgres/sia_backend_postgres.dart';
import 'package:sia_backend_supabase/supabase_backend.dart';

class AppServices {
  AppServices._({
    required AuthRepository authRepository,
    required UserRepository userRepository,
    required MasterRepository masterRepository,
    required CivitasRepository civitasRepository,
    required DashboardRepository dashboardRepository,
    required AuditRepository auditRepository,
    required TokenService tokens,
    required Future<void> Function() closeBackend,
  }) : auth = AuthService(repository: authRepository, tokens: tokens),
       users = UserService(userRepository),
       master = MasterDataService(masterRepository),
       civitas = CivitasService(civitasRepository),
       dashboard = DashboardService(dashboardRepository),
       audit = AuditService(auditRepository),
       _closeBackend = closeBackend;

  factory AppServices.fromEnvironment({Map<String, String>? env}) {
    final values = env ?? Platform.environment;
    final secret = values['JWT_SECRET'] ?? _devSecret;
    final appEnv = values['APP_ENV'] ?? 'development';
    if (appEnv == 'production' && secret == _devSecret) {
      throw StateError('JWT_SECRET wajib diisi di production.');
    }

    final tokens = TokenService(secret);

    final supabaseUrl = values['SUPABASE_URL'];
    final supabaseKey = values['SUPABASE_SERVICE_ROLE_KEY'];

    late final AuthRepository authRepository;
    late final UserRepository userRepository;
    late final MasterRepository masterRepository;
    late final CivitasRepository civitasRepository;
    late final DashboardRepository dashboardRepository;
    late final AuditRepository auditRepository;
    late final Future<void> Function() closeBackend;

    if (supabaseUrl != null &&
        supabaseUrl.isNotEmpty &&
        supabaseKey != null &&
        supabaseKey.isNotEmpty) {
      // Backend melalui Supabase (PostgREST + GoTrue Auth, kunci service role).
      final backend = SupabaseBackend(
        url: supabaseUrl,
        serviceRoleKey: supabaseKey,
      );
      authRepository = backend;
      userRepository = backend;
      masterRepository = backend;
      civitasRepository = backend;
      dashboardRepository = backend;
      auditRepository = backend;
      closeBackend = backend.close;
    } else {
      // Backend melalui Postgres mentah (default development).
      final url = values['DATABASE_URL'] ??
          'postgresql://postgres@127.0.0.1:5432/siakad';
      final backend = PostgresBackend(url);
      authRepository = backend;
      userRepository = backend;
      masterRepository = backend;
      civitasRepository = backend;
      dashboardRepository = backend;
      auditRepository = backend;
      closeBackend = backend.close;
    }

    return AppServices._(
      authRepository: authRepository,
      userRepository: userRepository,
      masterRepository: masterRepository,
      civitasRepository: civitasRepository,
      dashboardRepository: dashboardRepository,
      auditRepository: auditRepository,
      tokens: tokens,
      closeBackend: closeBackend,
    );
  }

  final AuthService auth;
  final UserService users;
  final MasterDataService master;
  final CivitasService civitas;
  final DashboardService dashboard;
  final AuditService audit;
  final Future<void> Function() _closeBackend;

  Future<void> close() => _closeBackend();
}

const _devSecret = 'dev-only-secret-change-me-0123456789abcdef';
