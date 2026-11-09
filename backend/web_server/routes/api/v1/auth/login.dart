import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/http_helpers.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }
  final body = await jsonBody(context);
  final identifier = (body['identifier'] ?? body['email'] ?? '').toString();
  final password = (body['password'] ?? '').toString();
  final result = await services(context).auth.login(
        identifier,
        password,
        ip: context.request.headers['x-forwarded-for'],
        userAgent: context.request.headers['user-agent'],
      );
  return ok(result.toJson());
}
