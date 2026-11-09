import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/http_helpers.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final actor = await requireUser(context);
  final app = services(context);

  if (context.request.method == HttpMethod.get) {
    return ok((await app.users.get(actor, id)).toJson());
  }

  if (context.request.method == HttpMethod.patch) {
    final body = await jsonBody(context);
    final user = await app.users.update(
      actor,
      id,
      namaLengkap: body['nama_lengkap'] as String?,
      telepon: body['telepon'] as String?,
      urlAvatar: body['url_avatar'] as String?,
      aktif: body['aktif'] as bool?,
      roles: (body['roles'] as List?)?.cast<String>(),
    );
    return ok(user.toJson());
  }

  return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
}
