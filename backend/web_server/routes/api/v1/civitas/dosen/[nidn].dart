import 'package:dart_frog/dart_frog.dart';

import '../../../../../lib/http_helpers.dart';

Future<Response> onRequest(RequestContext context, String nidn) async {
  final actor = await requireUser(context);
  if (context.request.method != HttpMethod.patch) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }
  final body = await jsonBody(context);
  final dosen = await services(context).civitas.updateDosen(
        actor,
        nidn,
        namaLengkap: body['nama_lengkap'] as String?,
        status: body['status'] as String?,
        telepon: body['telepon'] as String?,
      );
  return ok(dosen.toJson());
}
