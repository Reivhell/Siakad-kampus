# 15 — Prasyarat Mata Kuliah

> Status: EKSTENSI SKEMA — menutup celah validasi di `03`, tetapi **butuh migration baru** karena `ERD.md` v1 tidak memiliki relasi prasyarat. Migration: `database/migrations/022_buat_mata_kuliah_prasyarat.sql`. Service: `krs_service` (§17).

## 1. Fungsi

Mencegah mahasiswa mengambil MK lanjutan tanpa lulus dasarnya. Contoh: `TI401 Kecerdasan Buatan` mensyaratkan `TI301 Basis Data` minimal `C`. Tanpa tabel ini, aturan tersebut hanya bisa ditegakkan manual oleh Admin.

Tiga pihak yang terlibat:
- **Admin** menetapkan/mengubah relasi prasyarat (modul admin `04`).
- **Mahasiswa** melihat alasan terkunci di `14`/`03`.
- **Backend** menolak insert `krs` bila prasyarat belum terpenuhi.

## 2. Skema

Tabel `mata_kuliah_prasyarat`:

| Kolom | Tipe | Keterangan |
|:---|:---|:---|
| `id` | `uuid` | PK, `gen_random_uuid()` |
| `id_mata_kuliah` | `uuid` | FK → `mata_kuliah`, MK yang membutuhkan prasyarat |
| `id_prasyarat` | `uuid` | FK → `mata_kuliah`, MK yang harus lulus lebih dulu |
| `nilai_minimal` | `text` | `A/AB/B/BC/C/D`, default `C` |
| `dibuat_pada` | `timestamptz` | default `now()` |

Constraint: unik `(id_mata_kuliah, id_prasyarat)`, tidak boleh menunjuk dirinya sendiri, dan siklus (A butuh B, B butuh A) ditolak trigger.

## 3. Aturan Bisnis

- **Lulus** didefinisikan sebagai punya `nilai.sudah_final = true` dengan bobot huruf **>=** bobot `nilai_minimal`. Default ambang lulus program = `C` (bobot 2.0); ubah di satu konstanta, jangan duplikasi di `14`.
- Prasyarat dicek saat **submit** KRS (`DRAFT → MENUNGGU_APPROVAL`), bukan saat menambah draft, agar mahasiswa bisa menyusun rencana lebih dulu. Tampilkan peringatan sejak draft.
- Bila MK prasyarat sedang diambil di periode yang sama → tolak (bukan co-requisite). Bila perlu co-requisite, buat tabel terpisah di masa depan.
- Perubahan relasi oleh Admin hanya boleh saat tidak ada KRS aktif yang bergantung pada relasi tersebut, atau beri periode berlaku (`berlaku_mulai`). Untuk v1: tolak perubahan bila ada KRS aktif terkait.
- Semua perubahan relasi masuk audit usulan `ADMIN_UBAH_PRASYARAT` (belum ada di daftar kanonis `Rencana.md §15`).

## 4. Query Validasi

```sql
-- Nilai terbaik (final) mahasiswa untuk setiap prasyarat MK target
SELECT p.id_prasyarat, mk.kode, mk.nama, p.nilai_minimal,
       (
         SELECT n.huruf_nilai
         FROM krs
         JOIN kelas kl ON kl.id_kelas = krs.id_kelas
         JOIN nilai n ON n.id_krs = krs.id
         WHERE krs.id_mahasiswa = $1
           AND kl.id_mata_kuliah = p.id_prasyarat
           AND n.sudah_final = true
         ORDER BY CASE n.huruf_nilai
             WHEN 'A'  THEN 4.0
             WHEN 'AB' THEN 3.5
             WHEN 'B'  THEN 3.0
             WHEN 'BC' THEN 2.5
             WHEN 'C'  THEN 2.0
             WHEN 'D'  THEN 1.0
             ELSE 0.0
         END DESC
         LIMIT 1
       ) AS nilai_terbaik
FROM mata_kuliah_prasyarat p
JOIN mata_kuliah mk ON mk.id = p.id_prasyarat
WHERE p.id_mata_kuliah = $2;
```

`nilai_terbaik IS NULL` atau bobotnya di bawah `nilai_minimal` → prasyarat belum terpenuhi. Perbandingan bobot dilakukan di Dart (`lulus()` di bawah), bukan di SQL, agar urutan huruf tidak salah banding secara alfabetis.

## 5. Logika Dart

```dart
const bobotNilai = {
  'A': 4.0, 'AB': 3.5, 'B': 3.0, 'BC': 2.5, 'C': 2.0, 'D': 1.0, 'E': 0.0,
};

bool lulus(String? huruf, {String minimal = 'C'}) {
  if (huruf == null) return false;
  return (bobotNilai[huruf] ?? 0) >= (bobotNilai[minimal] ?? 2.0);
}
```

## 6. UI

- Di `14`, MK dengan prasyarat gagal berstatus `TERKUNCI_PRASYARAT` + tooltip "Butuh TI301 minimal C (nilai Anda: D)".
- Di `03`, tombol Tambah nonaktif dengan alasan yang sama; jangan hanya menyembunyikan tombol.
- Admin: layar pengelolaan relasi per MK, termasuk peringatan siklus dari database.

## 7. Edge Cases

| Kasus | Penanganan |
|:---|:---|
| MK prasyarat tidak ditawarkan lagi | Prasyarat tetap berlaku; arahkan ke Admin untuk kebijakan ekuivalensi |
| Mahasiswa pindahan/konversi | Prasyarat dapat terpenuhi lewat kredit transfer; cek `pengajuan_konversi` (lihat `12`) |
| Relasi diubah saat KRS berjalan | Tolak perubahan bila ada KRS aktif (v1) |
| Siklus prasyarat | Ditolak trigger; tampilkan pesan jelas ke Admin |
