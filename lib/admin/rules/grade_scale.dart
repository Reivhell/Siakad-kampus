import 'admin_thresholds.dart';

/// Satu-satunya tabel bobot huruf → angka (7-tier, spec 08 §4.1).
///
/// Sebelumnya tabel ini disalin di 3 tempat ([grading], [graduation],
/// [curriculum]) dengan risiko divergen — varian kurikulum bahkan
/// kehilangan tier AB/BC sehingga prasyarat menilai AB sebagai 0.0.
/// Seluruh modul wajib memakai tabel ini.
const gradeBobot = {
  'A': 4.0,
  'AB': 3.5,
  'B': 3.0,
  'BC': 2.5,
  'C': 2.0,
  'D': 1.0,
  'E': 0.0,
};

/// Bobot untuk [huruf]; huruf tak dikenal → 0.0 (gagal).
double bobotOf(String huruf) => gradeBobot[huruf] ?? 0.0;

/// Lulus = bobot ≥ C. Dipakai yudisium, prasyarat, transfer.
bool isPassingGrade(String huruf) =>
    bobotOf(huruf) >= AdminThresholds.bobotLulusMin;
