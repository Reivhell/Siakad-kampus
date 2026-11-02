/// Formatter ringan tanpa inisialisasi locale (deterministik untuk tes).
library;

const List<String> _bulanSingkat = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// `12 Sep 2026`
String formatTanggal(DateTime d) =>
    '${d.day} ${_bulanSingkat[d.month - 1]} ${d.year}';

/// `12 September 2026`
String formatTanggalPanjang(DateTime d) {
  const bulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${d.day} ${bulan[d.month - 1]} ${d.year}';
}

/// `Rp 4.500.000`
String formatRupiah(int value) {
  final digits = value.abs().toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return '${value < 0 ? '-' : ''}Rp $out';
}

/// `3.42` / `—` bila belum ada nilai.
String formatDesimal(double? v, {int digits = 2}) =>
    v == null ? '—' : v.toStringAsFixed(digits);

/// `68%` / `—`
String formatPersen(double? v) =>
    v == null ? '—' : '${v.round()}%';
