import 'package:flutter/foundation.dart';

import '../models/audit.dart';

/// Buffer audit klien (ringkas) untuk aksi UI; sumber kebenaran audit
/// operasional tetap berasal dari backend/API.
class AdminAuditLog extends ChangeNotifier {
  AdminAuditLog._();

  static final instance = AdminAuditLog._();

  final List<AuditEntry> _entries = <AuditEntry>[];
  int _counter = 0;

  List<AuditEntry> get entries => List.unmodifiable(_entries);
  List<AuditEntry> get newestFirst => _entries.reversed.toList(growable: false);
  AuditEntry? get last => _entries.isEmpty ? null : _entries.last;
  bool get chainValid => _entries.isEmpty || verifyChain(_entries);

  void record({
    required String aksi,
    required String entitas,
    required String aktor,
    Map<String, String> before = const {},
    Map<String, String> after = const {},
    String ip = '',
  }) {
    final now = DateTime.now();
    final prev = last?.hash ?? '';
    final draft = AuditEntry(
      id: 'AUD-${now.microsecondsSinceEpoch}-${_counter++}',
      waktu: now,
      aktor: aktor.isEmpty ? 'Sistem' : aktor,
      aksi: aksi,
      entitas: entitas,
      ip: ip,
      before: before,
      after: after,
    );
    final hash = auditHash(draft, prev);
    _entries.add(
      AuditEntry(
        id: draft.id,
        waktu: draft.waktu,
        aktor: draft.aktor,
        aksi: draft.aksi,
        entitas: draft.entitas,
        ip: draft.ip,
        before: draft.before,
        after: draft.after,
        hashPrev: prev,
        hash: hash,
      ),
    );
    notifyListeners();
  }

  @visibleForTesting
  void resetForTest() {
    _entries.clear();
    _counter = 0;
    notifyListeners();
  }
}
