import 'package:dart_frog/dart_frog.dart';

import '../../../../../lib/http_helpers.dart';

Future<Response> onRequest(RequestContext context, String npm) async {
  final actor = await requireUser(context);
  if (context.request.method != HttpMethod.patch) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }
  final body = await jsonBody(context);
  final mhs = await services(context).civitas.updateMahasiswa(
        actor,
        npm,
        namaLengkap: body['nama_lengkap'] as String?,
        status: body['status'] as String?,
        idDosenWali: body['id_dosen_wali'] as String?,
        telepon: body['telepon'] as String?,
      );
  return ok(mhs.toJson());
}
