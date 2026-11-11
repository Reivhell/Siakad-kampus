import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/http_helpers.dart';

Future<Response> onRequest(RequestContext context) async {
  final actor = await requireUser(context);
  final page = await services(context).audit.list(actor, pageRequest(context));
  return ok(page.toJson((log) => log.toJson()));
}
