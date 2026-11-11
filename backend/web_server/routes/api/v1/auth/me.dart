import 'package:dart_frog/dart_frog.dart';

import '../../../../lib/http_helpers.dart';

Future<Response> onRequest(RequestContext context) async {
  final user = await requireUser(context);
  return ok(user.toJson());
}
