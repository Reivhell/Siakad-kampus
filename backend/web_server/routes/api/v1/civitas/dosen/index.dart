import 'package:dart_frog/dart_frog.dart';
import 'package:sia_backend_core/sia_backend_core.dart';

import '../../../../../lib/http_helpers.dart';

Future<Response> onRequest(RequestContext context) async {
  final actor = await requireUser(context);
  final app = services(context);

  if (context.request.method == HttpMethod.get) {
    final page = await app.civitas.listDosen(
      actor,
      pageRequest(context),
      status: context.request.uri.queryParameters['status'],
    );
    return ok(page.toJson((dosen) => dosen.toJson()));
  }

  if (context.request.method == HttpMethod.post) {
    final body = await jsonBody(context);
    final dosen = await app.civitas.createDosen(
      actor,
      CreateDosenInput(
        email: (body['email'] ?? '').toString(),
        nidn: (body['nidn'] ?? '').toString(),
        namaLengkap: (body['nama_lengkap'] ?? '').toString(),
        idProgramStudi: (body['id_program_studi'] ?? '').toString(),
        password: body['password'] as String?,
        telepon: body['telepon'] as String?,
        gelarAkademik: body['gelar_akademik'] as String?,
        jenisKelamin: body['jenis_kelamin'] as String?,
        tanggalLahir: _date(body['tanggal_lahir']),
      ),
    );
    return ok(dosen.toJson(), status: 201);
  }

  return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());
