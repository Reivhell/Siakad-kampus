import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/http_helpers.dart';

Future<Response> onRequest(RequestContext context) async {
  final actor = await requireUser(context);
  final stats = await services(context).dashboard.stats(actor);
  return ok(stats.toJson());
}
