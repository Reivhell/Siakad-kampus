import 'package:flutter/material.dart';

import 'app/theme/siakad_theme.dart';
import 'shared/api_client.dart';
import 'shared/auth_service.dart';
import 'shared/login/role_gate.dart';
import 'shared/widgets/siakad_adaptive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient(baseUrl: 'http://127.0.0.1:8080');
  final auth = AuthService(apiClient: apiClient);
  await auth.init();
  runApp(SiakadApp(apiClient: apiClient, auth: auth));
}

class SiakadApp extends StatelessWidget {
  final ApiClient apiClient;
  final AuthService auth;

  const SiakadApp({super.key, required this.apiClient, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIAKAD KAMPUS',
      theme: SiakadTheme.light,
      darkTheme: SiakadTheme.dark,
      home: RoleGate(apiClient: apiClient, auth: auth),
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          SiakadAdaptive.wrap(context, child ?? const SizedBox.shrink()),
    );
  }
}
