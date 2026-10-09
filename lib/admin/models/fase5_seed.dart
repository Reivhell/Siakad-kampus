import 'graduation.dart';

class YudisiumCalon {
  final String npm;
  final String nama;
  final int semesters;
  final List<AuditGrade> grades;
  final bool library;
  final bool finance;
  String? pin;
  YudisiumCalon({
    required this.npm,
    required this.nama,
    required this.semesters,
    required this.grades,
    this.library = true,
    this.finance = true,
    this.pin,
  });
}

List<AuditGrade> _mk(String id, int sks, String h, {bool wajib = false}) =>
    [AuditGrade(mkId: id, sks: sks, huruf: h, wajib: wajib)];

List<YudisiumCalon> seedYudisium() => [
  YudisiumCalon(
    npm: '2210010001',
    nama: 'Aditya Pratama',
    semesters: 8,
    grades: [
      ..._mk('mk1', 3, 'A', wajib: true),
      ..._mk('mk2', 3, 'A', wajib: true),
      ..._mk('mk-skripsi', 6, 'A', wajib: true),
      ..._mk('mk3', 132, 'B'),
    ],
  ),
  YudisiumCalon(
    npm: '2110010045',
    nama: 'Bagas Wicaksono',
    semesters: 10,
    grades: [
      ..._mk('mk1', 3, 'B', wajib: true),
      ..._mk('mk2', 3, 'C', wajib: true),
      ..._mk('mk3', 138, 'B'),
    ],
  ),
  YudisiumCalon(
    npm: '2110010089',
    nama: 'Hendra Saputra',
    semesters: 10,
    grades: [
      ..._mk('mk1', 3, 'B', wajib: true),
      ..._mk('mk2', 140, 'C'),
    ],
    finance: false,
  ),
];

class AdvisorLoad {
  final String nidn;
  final String nama;
  int asuhan;
  int approved;
  AdvisorLoad(this.nidn, this.nama, this.asuhan, this.approved);
}

List<AdvisorLoad> seedAdvisor() => [
  AdvisorLoad('0412088501', 'Dr. Aris Munandar', 35, 32),
  AdvisorLoad('0405027802', 'Hendra Wijaya, M.Eng.', 34, 34),
  AdvisorLoad('0419098901', 'Budi Santoso, M.T.', 36, 18),
  AdvisorLoad('0422119102', 'Dr. Siti Nurhaliza', 35, 35),
];
