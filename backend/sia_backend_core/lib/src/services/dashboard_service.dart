import '../exceptions/app_exception.dart';
import '../models/app_user.dart';
import '../models/dashboard.dart';
import '../models/pagination.dart';
import '../repositories/contracts.dart';

class DashboardService {
  DashboardService(this._repository);
  final DashboardRepository _repository;

  Future<DashboardStats> stats(AppUser actor) {
    if (actor.roles.isEmpty) throw const ForbiddenException();
    return _repository.stats(actor);
  }
}

class AuditService {
  AuditService(this._repository);
  final AuditRepository _repository;

  Future<Page<AuditLog>> list(AppUser actor, PageRequest request) {
    if (!actor.isAdmin) throw const ForbiddenException();
    return _repository.listLogs(actor, request.normalized());
  }
}
