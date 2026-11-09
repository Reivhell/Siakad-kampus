import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import 'package:sia_backend_core/sia_backend_core.dart';

import '../lib/app_services.dart';
import '../lib/http_helpers.dart';

final _env = DotEnv(includePlatformEnvironment: true)..load();
final _envValues = {
  for (final key in ['DATABASE_URL', 'JWT_SECRET', 'APP_ENV'])
    if (_env.isDefined(key)) key: _env[key]!,
};
final _services = AppServices.fromEnvironment(env: _envValues);

Handler middleware(Handler handler) {
  return (context) async {
    try {
      return await handler(context.provide(() => _services));
    } on AppException catch (e) {
      return error(e);
    } on Exception catch (e, st) {
      if (Platform.environment['APP_ENV'] != 'production') {
        stderr.writeln('Unhandled: $e\n$st');
      }
      return Response.json(
        statusCode: 500,
        body: {'error': 'Terjadi kesalahan pada server.'},
      );
    }
  };
}
