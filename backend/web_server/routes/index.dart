import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) => Response.json(
      body: {
        'service': 'siakad-api',
        'version': '1.0.0',
        'status': 'ok',
      },
    );
