import 'package:flutter/material.dart';

import 'app/theme/siakad_theme.dart';
import 'auth/auth_gate.dart';

void main() {
  runApp(const SiakadApp());
}

class SiakadApp extends StatelessWidget {
  const SiakadApp({super.key});

  @override 
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIAKAD KAMPUS',
      theme: SiakadTheme.light,
      darkTheme: SiakadTheme.dark,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
