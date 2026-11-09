import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/http_helpers.dart';

Future<Response> onRequest(RequestContext context) async {
  final actor = await requireUser(context);
  final app = services(context);

  if (context.request.method == HttpMethod.get) {
    final page = await app.users.list(
      actor,
      pageRequest(context),
      role: context.request.uri.queryParameters['role'],
    );
    return ok(page.toJson((user) => user.toJson()));
  }

  if (context.request.method == HttpMethod.post) {
    final body = await jsonBody(context);
    final user = await app.users.create(
      actor,
      email: (body['email'] ?? '').toString(),
      namaLengkap: (body['nama_lengkap'] ?? '').toString(),
      roles: (body['roles'] as List? ?? const []).cast<String>(),
      telepon: body['telepon'] as String?,
      password: body['password'] as String?,
    );
    return ok(user.toJson(), status: 201);
  }

  return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
}
