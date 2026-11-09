import 'package:dart_frog/dart_frog.dart';
import 'package:sia_backend_core/sia_backend_core.dart';

import '../../../../../lib/http_helpers.dart';

Future<Response> onRequest(RequestContext context) async {
  final actor = await requireUser(context);
  final app = services(context);

  if (context.request.method == HttpMethod.get) {
    final page = await app.civitas.listMahasiswa(
      actor,
      pageRequest(context),
      status: context.request.uri.queryParameters['status'],
    );
    return ok(page.toJson((mhs) => mhs.toJson()));
  }

  if (context.request.method == HttpMethod.post) {
    final body = await jsonBody(context);
    final mhs = await app.civitas.createMahasiswa(
      actor,
      CreateMahasiswaInput(
        email: (body['email'] ?? '').toString(),
        namaLengkap: (body['nama_lengkap'] ?? '').toString(),
        idProgramStudi: (body['id_program_studi'] ?? '').toString(),
        tahunMasuk: (body['tahun_masuk'] as num?)?.toInt() ?? 0,
        jenisKelamin: (body['jenis_kelamin'] ?? '').toString(),
        npm: body['npm'] as String?,
        password: body['password'] as String?,
        telepon: body['telepon'] as String?,
        tanggalLahir: _date(body['tanggal_lahir']),
        idDosenWali: body['id_dosen_wali'] as String?,
        nik: body['nik'] as String?,
        namaIbuKandung: body['nama_ibu_kandung'] as String?,
      ),
    );
    return ok(mhs.toJson(), status: 201);
  }

  return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());
