import 'dart:io';

import 'package:args/args.dart';
import 'package:postgres/postgres.dart';

const _migrations = <String>[
  'database/migrations/000_baseline.sql',
  'database/migrations/001_extensions.sql',
  'database/local/000_supabase_stub.sql',
  'database/migrations/010_spec_additive.sql',
  'database/migrations/020_functions.sql',
  'database/migrations/021_views.sql',
  'database/migrations/022_rls.sql',
  'database/migrations/023_hardening.sql',
  'database/migrations/024_rls_hardening.sql',
  'database/migrations/025_function_search_path.sql',
  'database/migrations/026_audit_chain_extensions.sql',
];

const _versions = <String>[
  '000_baseline',
  '001_extensions',
  'local_000_supabase_stub',
  '010_spec_additive',
  '020_functions',
  '021_views',
  '022_rls',
  '023_hardening',
  '024_rls_hardening',
  '025_function_search_path',
  '026_audit_chain_extensions',
];

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption('env', abbr: 'e', defaultsTo: 'local', allowed: ['local', 'supabase'])
    ..addOption('url',
        help: 'PostgreSQL URL. Default: SUPABASE_DB_URL untuk env supabase, '
            'selain itu DATABASE_URL / lokal.')
    ..addFlag('help', abbr: 'h', negatable: false);

  final args = parser.parse(argv);
  if (args['help'] as bool || args.rest.isEmpty) {
    stdout.writeln('Usage: dart run tool/db.dart <migrate|adopt|seed|verify> [options]');
    stdout.writeln(parser.usage);
    return;
  }

  final env = args['env'] as String;
  final url = (args['url'] as String?) ??
      Platform.environment[env == 'supabase' ? 'SUPABASE_DB_URL' : 'DATABASE_URL'] ??
      (env == 'local' ? 'postgresql://postgres@127.0.0.1:5432/siakad' : null);
  if (url == null || url.isEmpty) {
    stderr.writeln('Set SUPABASE_DB_URL atau --url untuk env supabase.');
    exitCode = 64;
    return;
  }


  try {
    switch (args.rest.first) {
      case 'migrate':
        await _migrate(url, env, adopt: false);
      case 'adopt':
        await _migrate(url, env, adopt: true);
      case 'seed':
        await _seed(url, env);
      case 'verify':
        await _verify(url);
      default:
        stderr.writeln('Unknown command: ${args.rest.first}');
        exitCode = 64;
    }
  } on ProcessException catch (e) {
    stderr.writeln('Failed to run psql: ${e.message}');
    exitCode = 1;
  } on Exception catch (e) {
    stderr.writeln(e);
    exitCode = 1;
  }
}

bool _isLocalHost(String url) {
  final host = Uri.parse(url).host;
  return host == 'localhost' || host == '127.0.0.1' || host == '::1';
}

Future<void> _migrate(String url, String env, {required bool adopt}) async {
  // Stub auth lokal tidak boleh menyentuh database remote (pernah terjadi:
  // local_000_supabase_stub ikut diterapkan ke project Supabase).
  if (env == 'local' && !_isLocalHost(url)) {
    throw Exception('Tolak --env local untuk host non-lokal: ${Uri.parse(url).host}');
  }
  await _psql(url, ['-c', '''
    CREATE TABLE IF NOT EXISTS public.schema_migrations (
      version text PRIMARY KEY,
      applied_at timestamptz NOT NULL DEFAULT now()
    );
  ''']);

  final applied = await _appliedVersions(url);
  if (adopt) {
    await _mark(url, '000_baseline');
    applied.add('000_baseline');
    stdout.writeln('adopted existing schema as 000_baseline');
  }

  for (var i = 0; i < _migrations.length; i++) {
    final path = _migrations[i];
    final version = _versions[i];
    if (version.startsWith('local_') && env != 'local') continue;
    if (applied.contains(version)) {
      stdout.writeln('skip $version');
      continue;
    }
    stdout.writeln('apply $version ($path)');
    await _psql(url, ['-v', 'ON_ERROR_STOP=1', '-f', path]);
    await _mark(url, version);
  }
}

Future<void> _seed(String url, String env) async {
  if (env == 'local' && !_isLocalHost(url)) {
    throw Exception('Tolak --env local untuk host non-lokal: ${Uri.parse(url).host}');
  }
  await _psql(url, ['-v', 'ON_ERROR_STOP=1', '-f', 'database/seed/001_reference.sql']);
  if (env == 'local') {
    await _psql(url, ['-v', 'ON_ERROR_STOP=1', '-f', 'database/local/002_dev_seed.sql']);
  }
  stdout.writeln('seed done ($env)');
}

Future<Set<String>> _appliedVersions(String url) async {
  final result = await _query(url, 'SELECT version FROM public.schema_migrations');
  return result.map((row) => row[0]! as String).toSet();
}

Future<void> _mark(String url, String version) async {
  await _psql(url, [
    '-c',
    "INSERT INTO public.schema_migrations(version) VALUES ('$version') ON CONFLICT DO NOTHING",
  ]);
}

Future<void> _psql(String url, List<String> args) async {
  final result = await Process.run('psql', [url, ...args]);
  if (result.exitCode != 0) {
    throw Exception('psql failed (${result.exitCode}):\n${result.stderr}');
  }
  if ((result.stdout as String).trim().isNotEmpty) {
    stdout.write(result.stdout);
  }
}

Future<void> _verify(String url) async {
  final tables = await _query(url, '''
    SELECT count(*) FROM pg_tables WHERE schemaname = 'public'
  ''');
  final rls = await _query(url, '''
    SELECT count(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity
  ''');
  final functions = await _query(url, '''
    SELECT count(*) FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
  ''');
  final migrations = await _query(url, 'SELECT count(*) FROM public.schema_migrations');
  final views = await _query(url, '''
    SELECT count(*) FROM pg_views WHERE schemaname = 'public'
  ''');

  stdout.writeln('tables=${tables.first[0]} rls=${rls.first[0]} '
      'functions=${functions.first[0]} views=${views.first[0]} '
      'migrations=${migrations.first[0]}');
}

Future<List<List<Object?>>> _query(String url, String sql) async {
  final uri = Uri.parse(url);
  // Password di URL biasanya percent-encoded (mis. %40 untuk @).
  final userInfo = uri.userInfo.split(':').map(Uri.decodeComponent).toList();
  final endpoint = Endpoint(
    host: uri.host,
    port: uri.hasPort ? uri.port : 5432,
    database: uri.pathSegments.first,
    username: userInfo.first,
    password: userInfo.length > 1 ? userInfo[1] : null,
  );
  final connection = await Connection.open(
    endpoint,
    settings: ConnectionSettings(
      sslMode: uri.host == '127.0.0.1' || uri.host == 'localhost'
          ? SslMode.disable
          : SslMode.require,
    ),
  );
  try {
    return await connection.execute(sql);
  } finally {
    await connection.close();
  }
}
