import 'package:dart_frog/dart_frog.dart';

import '../../../../../lib/http_helpers.dart';

Future<Response> onRequest(RequestContext context) async {
  final actor = await requireUser(context);
  if (context.request.method != HttpMethod.get) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }
  final prefix = context.request.uri.queryParameters['prefix'] ?? '';
  final npm = await services(context).civitas.nextNpm(actor, prefix);
  return ok({'npm': npm, 'prefix': prefix});
}
