import 'package:dart_frog/dart_frog.dart';
import 'package:sia_backend_core/sia_backend_core.dart';

Future<Response> onRequest(RequestContext context, String token) async {
  if (token.trim().isEmpty) {
    throw const ValidationException('Token verifikasi wajib diisi.');
  }
  // Backend contracts for public letter verification are not wired yet.
  // Return a safe, explicit response instead of crashing.
  return Response.json(
    statusCode: 404,
    body: {'error': 'Dokumen tidak ditemukan atau belum terbit.'},
  );
}
