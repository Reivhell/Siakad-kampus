import 'package:flutter/material.dart';

/// 15 destinasi admin — route: Admin.md §4. Ikon outline M3 ultra-tipis.
class AdminDestination {
  final String label;
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  const AdminDestination(this.label, this.route, this.icon, this.selectedIcon);
}

const adminDestinations = [
  AdminDestination(
    'Dashboard',
    '/admin/dashboard',
    Icons.dashboard_outlined,
    Icons.dashboard,
  ),
  AdminDestination(
    'Pengguna & Role',
    '/admin/users',
    Icons.group_outlined,
    Icons.group,
  ),
  AdminDestination(
    'Master Data',
    '/admin/master',
    Icons.storage_outlined,
    Icons.storage,
  ),
  AdminDestination(
    'Kurikulum & MK',
    '/admin/akademik',
    Icons.book_outlined,
    Icons.book,
  ),
  AdminDestination(
    'Civitas',
    '/admin/civitas',
    Icons.school_outlined,
    Icons.school,
  ),
  AdminDestination(
    'Kelas & Jadwal',
    '/admin/perkuliahan',
    Icons.calendar_month_outlined,
    Icons.calendar_month,
  ),
  AdminDestination(
    'KRS',
    '/admin/krs',
    Icons.fact_check_outlined,
    Icons.fact_check,
  ),
  AdminDestination(
    'Nilai',
    '/admin/nilai',
    Icons.grade_outlined,
    Icons.grade,
  ),
  AdminDestination(
    'Presensi',
    '/admin/presensi',
    Icons.how_to_reg_outlined,
    Icons.how_to_reg,
  ),
  AdminDestination(
    'Dosen Wali',
    '/admin/dosen-wali',
    Icons.supervisor_account_outlined,
    Icons.supervisor_account,
  ),
  AdminDestination(
    'Yudisium',
    '/admin/yudisium',
    Icons.workspace_premium_outlined,
    Icons.workspace_premium,
  ),
  AdminDestination(
    'Konversi',
    '/admin/konversi',
    Icons.swap_horiz_outlined,
    Icons.swap_horiz,
  ),
  AdminDestination(
    'PDDIKTI',
    '/admin/pddikti',
    Icons.cloud_upload_outlined,
    Icons.cloud_upload,
  ),
  AdminDestination(
    'Surat',
    '/admin/persuratan',
    Icons.mail_outlined,
    Icons.mail,
  ),
  AdminDestination(
    'Audit Log',
    '/admin/logs',
    Icons.history_outlined,
    Icons.history,
  ),
];
