import 'dart:async';

import 'package:flutter/foundation.dart';

import 'admin_audit_log.dart';

/// Tier operator. Satu sumber kebenaran untuk UI gate + aksi.
enum AdminTier { superAdmin, operator, auditor }

enum AdminPermission {
  viewDashboard,
  manageUsers,
  manageMaster,
  manageCurriculum,
  manageCivitas,
  manageScheduling,
  manageKrs,
  manageGrades,
  manageAttendance,
  manageAdvising,
  manageGraduation,
  manageTransfer,
  manageFeeder,
  manageLetters,
  viewAudit,
  exportData,
  broadcast,
  unlockGrades,
  manageSession,
}

const Map<AdminTier, Set<AdminPermission>> tierPermissions = {
  AdminTier.superAdmin: {...AdminPermission.values},
  AdminTier.operator: {
    AdminPermission.viewDashboard,
    AdminPermission.manageMaster,
    AdminPermission.manageCurriculum,
    AdminPermission.manageCivitas,
    AdminPermission.manageScheduling,
    AdminPermission.manageKrs,
    AdminPermission.manageGrades,
    AdminPermission.manageAttendance,
    AdminPermission.manageAdvising,
    AdminPermission.manageGraduation,
    AdminPermission.manageTransfer,
    AdminPermission.manageFeeder,
    AdminPermission.manageLetters,
    AdminPermission.exportData,
    AdminPermission.broadcast,
    AdminPermission.unlockGrades,
  },
  AdminTier.auditor: {
    AdminPermission.viewDashboard,
    AdminPermission.viewAudit,
    AdminPermission.exportData,
  },
};

String adminTierLabel(AdminTier t) => switch (t) {
  AdminTier.superAdmin => 'Super Admin',
  AdminTier.operator => 'Operator Akademik',
  AdminTier.auditor => 'Auditor Read-only',
};

String adminTierScope(AdminTier t) => switch (t) {
  AdminTier.superAdmin => 'Akses penuh • kelola pengguna, kunci, & sesi',
  AdminTier.operator => 'Operasional akademik • tanpa kelola pengguna',
  AdminTier.auditor => 'Baca + ekspor • semua mutasi diblokir',
};

/// Permission minimum untuk membuka route admin.
AdminPermission? permissionForRoute(String route) {
  if (route.startsWith('/admin/dashboard')) return AdminPermission.viewDashboard;
  if (route.startsWith('/admin/users')) return AdminPermission.manageUsers;
  if (route.startsWith('/admin/master')) return AdminPermission.manageMaster;
  if (route.startsWith('/admin/akademik')) {
    return AdminPermission.manageCurriculum;
  }
  if (route.startsWith('/admin/civitas')) return AdminPermission.manageCivitas;
  if (route.startsWith('/admin/perkuliahan')) {
    return AdminPermission.manageScheduling;
  }
  if (route.startsWith('/admin/krs')) return AdminPermission.manageKrs;
  if (route.startsWith('/admin/nilai')) return AdminPermission.manageGrades;
  if (route.startsWith('/admin/presensi')) return AdminPermission.manageAttendance;
  if (route.startsWith('/admin/dosen-wali')) return AdminPermission.manageAdvising;
  if (route.startsWith('/admin/yudisium')) return AdminPermission.manageGraduation;
  if (route.startsWith('/admin/konversi')) return AdminPermission.manageTransfer;
  if (route.startsWith('/admin/pddikti')) return AdminPermission.manageFeeder;
  if (route.startsWith('/admin/persuratan')) return AdminPermission.manageLetters;
  if (route.startsWith('/admin/logs')) return AdminPermission.viewAudit;
  return null;
}

/// Sesi admin: tier, permission, idle timeout, lock/unlock.
///
/// Idle watch hanya aktif bila [idleEnabled] di-set dari bootstrap aplikasi.
/// Test widget tidak mengaktifkannya agar tidak meninggalkan timer.
class AdminSessionController extends ChangeNotifier {
  AdminSessionController._();

  static final instance = AdminSessionController._();

  AdminTier _tier = AdminTier.superAdmin;
  bool _locked = false;
  bool idleEnabled = false;
  Duration idleTimeout = const Duration(minutes: 15);
  Duration warnBefore = const Duration(minutes: 1);
  String lockReason = 'Sesi dikunci otomatis karena tidak ada aktivitas.';

  Timer? _idleTimer;
  DateTime _lastActivity = DateTime.now();

  AdminTier get tier => _tier;
  String get tierLabel => adminTierLabel(_tier);
  String get scopeLabel => adminTierScope(_tier);
  Set<AdminPermission> get permissions => tierPermissions[_tier]!;
  bool get locked => _locked;
  DateTime get lastActivity => _lastActivity;
  Duration get idleFor => DateTime.now().difference(_lastActivity);
  Duration get warningRemaining => idleTimeout - idleFor;
  bool get inWarningWindow =>
      idleEnabled && warningRemaining <= warnBefore && warningRemaining > Duration.zero;

  bool can(AdminPermission p) => permissions.contains(p);
  bool canRoute(String route) {
    final p = permissionForRoute(route);
    return p == null || can(p);
  }

  void setTier(AdminTier tier, {String? actor}) {
    if (_tier == tier) return;
    final old = _tier;
    _tier = tier;
    _locked = false;
    AdminAuditLog.instance.record(
      aksi: 'ADMIN_GANTI_TIER',
      entitas: 'session',
      aktor: actor ?? 'Sistem',
      before: {'tier': adminTierLabel(old)},
      after: {'tier': adminTierLabel(tier)},
    );
    notifyListeners();
  }
  void configureIdle({bool enabled = true, Duration? timeout, Duration? warn}) {
    idleEnabled = enabled;
    if (timeout != null) idleTimeout = timeout;
    if (warn != null) warnBefore = warn;
    if (enabled) {
      startIdleWatch();
    } else {
      _idleTimer?.cancel();
      _idleTimer = null;
    }
    notifyListeners();
  }

  void startIdleWatch() {
    if (!idleEnabled) return;
    _idleTimer?.cancel();
    _lastActivity = DateTime.now();
    // Cek per menit; warning muncul di menit terakhir.
    _idleTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_locked) return;
      if (idleFor >= idleTimeout) {
        lock(reason: lockReason);
      } else {
        notifyListeners();
      }
    });
  }

  void touch() {
    if (_locked) return;
    _lastActivity = DateTime.now();
    notifyListeners();
  }

  void lock({String? reason}) {
    if (_locked) return;
    _locked = true;
    if (reason != null) lockReason = reason;
    AdminAuditLog.instance.record(
      aksi: 'AUTH_SESSION_LOCK',
      entitas: 'session',
      aktor: 'SYSTEM',
      after: {'alasan': lockReason},
    );
    notifyListeners();
  }

  Future<bool> verifyUnlock({
    required Future<bool> Function(String password) reauthenticate,
    required String password,
    String actor = 'Sistem',
  }) async {
    final ok = await reauthenticate(password);
    if (!ok) {
      AdminAuditLog.instance.record(
        aksi: 'AUTH_SESSION_UNLOCK_FAILED',
        entitas: 'session',
        aktor: actor,
      );
      notifyListeners();
      return false;
    }
    _locked = false;
    _lastActivity = DateTime.now();
    AdminAuditLog.instance.record(
      aksi: 'AUTH_SESSION_UNLOCK',
      entitas: 'session',
      aktor: actor,
    );
    startIdleWatch();
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }
}
