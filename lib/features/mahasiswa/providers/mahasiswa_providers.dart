import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../auth/auth_providers.dart';
import '../models/mahasiswa_models.dart';
import '../repositories/mahasiswa_repository.dart';

/// Satu repository in-memory untuk seluruh sesi (mahasiswa & admin).
final mahasiswaRepositoryProvider = ChangeNotifierProvider<MahasiswaRepository>(
  (ref) => MahasiswaRepository.seed(),
);

/// NPM mahasiswa yang sedang login; null untuk admin.
final currentNpmProvider = Provider<String?>(
  (ref) => ref.watch(authSessionProvider).account?.npm,
);

final currentProfileProvider = Provider<MahasiswaProfile?>((ref) {
  final npm = ref.watch(currentNpmProvider);
  final repo = ref.watch(mahasiswaRepositoryProvider);
  return npm == null ? null : repo.profile(npm);
});

final gateKrsProvider = Provider<GateKrs>((ref) {
  final npm = ref.watch(currentNpmProvider);
  final repo = ref.watch(mahasiswaRepositoryProvider);
  if (npm == null) return const GateKrs.blokir('Sesi tidak ditemukan.');
  return repo.gate(npm);
});
