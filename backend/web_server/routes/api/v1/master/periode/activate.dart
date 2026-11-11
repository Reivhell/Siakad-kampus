import 'package:dart_frog/dart_frog.dart';
import '../../../../../lib/http_helpers.dart';

Future<Response> onRequest(RequestContext context) async {
  final actor = await requireUser(context);
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }
  final body = await jsonBody(context);
  final item = await services(context).master.activatePeriode(actor, (body['id'] ?? '').toString());
  return ok(item.toJson());
}
