# 13 — Kalkulator Target IPK

> Status: TURUNAN KANONIS — memperkaya `Rencana.md §12` ("melihat nilai") tanpa kapabilitas baru dan **tanpa tabel baru**. Service: `nilai_service` (§17). Tidak ada endpoint tulis; seluruh perhitungan murni di backend.

## 1. Fungsi

Menjawab "kalau target IPK saya X, nilai berapa yang harus saya capai semester ini?" serta "masih mungkin atau tidak?". Mahasiswa memasukkan target, sistem membalik rumus IPK dan menampilkan bobot minimum yang dibutuhkan per MK aktif.

Dua mode:
1. **Target IPK kumulatif** — memperhitungkan seluruh nilai final + MK yang sedang diambil.
2. **Target IPS semester ini** — hanya MK periode aktif.

## 2. Rumus

Bobot huruf (`ERD.md` §3.16): `A=4, AB=3.5, B=3, BC=2.5, C=2, D=1, E=0`.

```
P  = Σ(bobot × sks)  untuk MK ber-nilai final   (poin terkumpul)
E  = Σ sks           untuk MK ber-nilai final   (SKS lulus dihitung)
A  = Σ sks           untuk MK periode aktif     (SKS sedang diambil)
```

Mode IPK:

```
totalSks = E + A
butuh    = target × totalSks − P
maksimal = 4 × A
```

- `butuh <= 0` → target sudah tercapai tanpa usaha tambahan.
- `butuh > maksimal` → target tidak mungkin; tampilkan batas IPK maksimum yang realistis (`(P + 4A) / totalSks`).
- selain itu → bobot rata-rata minimum = `butuh / A`, diterjemahkan ke kombinasi huruf.

Mode IPS: sama, dengan `E = 0`, `P = 0`, `totalSks = A`.

## 3. Logika Dart

```dart
const bobotNilai = {
  'A': 4.0, 'AB': 3.5, 'B': 3.0, 'BC': 2.5, 'C': 2.0, 'D': 1.0, 'E': 0.0,
};

class SimulasiIpk {
  const SimulasiIpk({
    required this.sksFinal,
    required this.poinFinal,
    required this.sksAktif,
  });

  final double sksFinal;
  final double poinFinal;
  final double sksAktif;

  /// null = tidak ada MK aktif (tidak bisa disimulasikan).
  double? butuhPoin(double target) {
    final total = sksFinal + sksAktif;
    if (total == 0 || sksAktif == 0) return null;
    return target * total - poinFinal;
  }

  bool tidakMungkin(double target) {
    final butuh = butuhPoin(target);
    return butuh != null && butuh > 4.0 * sksAktif;
  }

  double ipkMaksimum() {
    final total = sksFinal + sksAktif;
    return total == 0 ? 0 : (poinFinal + 4.0 * sksAktif) / total;
  }
}
```

## 4. Aturan Bisnis

- Hanya `nilai.sudah_final = true` yang masuk `P` dan `E`; nilai draft diabaikan (sama dengan `05`).
- **MK mengulang**: gunakan nilai terbaik per `id_mata_kuliah` untuk IPK (kebijakan default; jadikan konstanta agar mudah diubah).
- MK tanpa `huruf_nilai` tidak dihitung, walaupun `sudah_final = true` (data belum lengkap) — tampilkan badge "nilai tidak lengkap".
- Hasil bersifat estimasi; tampilkan disclaimer "bukan jaminan nilai".
- Pembulatan 2 desimal, tanpa mengubah nilai asli.

## 5. Query

```sql
SELECT mk.id, mk.kode, mk.nama, mk.sks, n.huruf_nilai
FROM krs
JOIN kelas k ON krs.id_kelas = k.id
JOIN mata_kuliah mk ON k.id_mata_kuliah = mk.id
JOIN nilai n ON n.id_krs = krs.id
WHERE krs.id_mahasiswa = $1 AND n.sudah_final = true;
```

MK aktif diambil dari `krs` periode aktif yang statusnya `AKTIF`/`MENUNGGU_APPROVAL` dan belum punya nilai final.

## 6. Wireframe

```
┌───────────────────────────────────────────────┐
│ Simulasi IPK        Mode: (•) IPK  ( ) IPS    │
│ Target: [ 3.50 ]   SKS final 68 | aktif 21    │
├───────────────────────────────────────────────┤
│ Butuh poin: 18.5 dari maksimal 84  ✅ Mungkin │
│ Rata-rata bobot minimum: 2.64                 │
│ Perkiraan huruf: B (3.0) cukup untuk 5 MK     │
├───────────────────────────────────────────────┤
│ MK                SKS  Nilai minimum          │
│ Basis Data         3   B                      │
│ Jaringan           3   B                      │
└───────────────────────────────────────────────┘
```

## 7. RLS & Edge Cases

- Hanya membaca `nilai` milik sendiri (policy `05`); tidak ada agregat lintas mahasiswa.
- `sksAktif = 0` (belum ambil KRS) → nonaktifkan tombol simulasi + arahkan ke `03`.
- Target di luar `0.00–4.00` → validasi form.
- Periode aktif kosong → mode IPS disembunyikan.
