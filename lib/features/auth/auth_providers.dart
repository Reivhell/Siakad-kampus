import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository.seed(),
);

final authSessionProvider = ChangeNotifierProvider<AuthSession>(
  (ref) => AuthSession(),
);
