import 'package:flutter/material.dart';

import 'admin/admin_shell.dart';
import 'app/theme/siakad_theme.dart';

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
      home: const AdminShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
