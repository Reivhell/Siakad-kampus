import 'package:dart_frog/dart_frog.dart';
import '../../../../../lib/http_helpers.dart';

Future<Response> onRequest(RequestContext context) async {
  final actor = await requireUser(context);
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }
  final body = await jsonBody(context);
  final item = await services(context).master.savePeriode(
        actor,
        id: body['id'] as String?,
        nama: (body['nama'] ?? '').toString(),
        tahunAkademik: (body['tahun_akademik'] ?? body['tahun'] ?? '').toString(),
        semester: (body['semester'] ?? '').toString(),
        tanggalMulai: DateTime.parse((body['tanggal_mulai'] ?? body['mulai'] ?? '').toString()),
        tanggalSelesai: DateTime.parse((body['tanggal_selesai'] ?? body['selesai'] ?? '').toString()),
        aktif: body['aktif'] == true,
      );
  return ok(item.toJson(), status: body['id'] == null ? 201 : 200);
}
