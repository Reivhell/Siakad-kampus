import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/mahasiswa_models.dart';
import '../repositories/mahasiswa_repository.dart';

final mahasiswaRepositoryProvider = ChangeNotifierProvider<MahasiswaRepository>(
  (ref) => MahasiswaRepository.seed(),
);

final studentIdentifierProvider = Provider<String?>((ref) => null);

final currentNpmProvider = Provider<String?>((ref) {
  final identifier = ref.watch(studentIdentifierProvider)?.trim();
  if (identifier == null || identifier.isEmpty) return null;

  final repo = ref.watch(mahasiswaRepositoryProvider);
  final normalized = identifier.toLowerCase();
  for (final profile in repo.profiles) {
    if (profile.npm == identifier || profile.email.toLowerCase() == normalized) {
      return profile.npm;
    }
  }
  return RegExp(r'^\d{8,}$').hasMatch(identifier) ? identifier : null;
});

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
