import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme/siakad_theme.dart';

void main() {
  runApp(const ProviderScope(child: SiakadApp()));
}

class SiakadApp extends ConsumerWidget {
  const SiakadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SIAKAD KAMPUS',
      theme: SiakadTheme.light,
      darkTheme: SiakadTheme.dark,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
