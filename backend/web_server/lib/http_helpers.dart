import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:sia_backend_core/sia_backend_core.dart';

import 'app_services.dart';

AppServices services(RequestContext context) => context.read<AppServices>();

Future<AppUser> requireUser(RequestContext context) async {
  final header = context.request.headers[HttpHeaders.authorizationHeader];
  if (header == null || !header.toLowerCase().startsWith('bearer ')) {
    throw const UnauthorizedException('Header Authorization Bearer wajib diisi.');
  }
  return services(context).auth.me(header.substring(7).trim());
}

Future<Map<String, Object?>> jsonBody(RequestContext context) async {
  final value = await context.request.json();
  if (value is! Map) throw const ValidationException('Body harus berupa objek JSON.');
  return value.map((key, value) => MapEntry(key.toString(), value));
}

PageRequest pageRequest(RequestContext context) {
  final q = context.request.uri.queryParameters;
  return PageRequest(
    page: int.tryParse(q['page'] ?? '') ?? 1,
    limit: int.tryParse(q['limit'] ?? '') ?? 20,
    query: q['q'],
  );
}

Response ok(Object? body, {int status = 200}) => Response.json(statusCode: status, body: body);

Response error(AppException exception) {
  final status = switch (exception) {
    ValidationException() => 400,
    UnauthorizedException() => 401,
    ForbiddenException() => 403,
    NotFoundException() => 404,
    ConflictException() => 409,
  };
  return Response.json(statusCode: status, body: {'error': exception.message});
}
