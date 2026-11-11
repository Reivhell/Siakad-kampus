import 'package:flutter/material.dart';

import 'pages/curriculum_page.dart';
import 'pages/civitas_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/transfer_page.dart';
import 'pages/krs_page.dart';
import 'pages/audit_page.dart';
import 'pages/master_page.dart';
import 'models/admin_nav.dart';
import 'pages/grades_page.dart';
import 'pages/feeder_page.dart';
import 'pages/scheduling_page.dart';
import 'pages/attendance_page.dart';
import 'pages/letters_page.dart';
import 'pages/users_page.dart';
import 'pages/advisor_page.dart';
import 'pages/graduation_page.dart';
import '../shared/api_client.dart';
import '../shared/auth_service.dart';
import 'core/admin_api_scope.dart';

/// Shell responsif M3 — satu codebase tiga platform (design.md §5).
/// ≥1024: NavigationDrawer + header. 600–1023: NavigationRail.
/// <600: AppBar + NavigationBar 5 tab (design.md §5.2).
class AdminShell extends StatefulWidget {
  final String userLabel;
  final VoidCallback? onLogout;
  final ApiClient? apiClient;
  final AuthService? auth;

  const AdminShell({
    super.key,
    this.userLabel = 'A',
    this.onLogout,
    this.apiClient,
    this.auth,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<int> _history = [0];

  void _go(int i) {
    if (i == _index) return;
    if (i < 0 || i >= adminDestinations.length) return;
    setState(() {
      _index = i;
      _history.add(i);
      if (_history.length > 32) _history.removeAt(0);
    });
  }

  void _onPop(bool didPop) {
    if (didPop) return;
    if (_history.length > 1) {
      setState(() {
        _history.removeLast();
        _index = _history.last.clamp(0, adminDestinations.length - 1);
      });
    }
  }

  bool get _canPop => _history.length <= 1;

  Widget _wrap(Widget child) => AdminApiScope(
    apiClient: widget.apiClient,
    auth: widget.auth,
    userLabel: widget.userLabel,
    child: child,
  );

  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final isTablet = width >= 600 && width < 1024;
    final iconOnly = width < 840;

    if (isDesktop) {
      return _wrap(
        PopScope(
          canPop: _canPop,
          onPopInvokedWithResult: (didPop, _) => _onPop(didPop),
          child: Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 300,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: _Brand(),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            itemCount: adminDestinations.length,
                            itemBuilder: (_, i) {
                              final d = adminDestinations[i];
                              final selected = i == _index;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 1,
                                ),
                                child: ListTile(
                                  selected: selected,
                                  selectedTileColor: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  shape: const StadiumBorder(),
                                  leading: Icon(
                                    selected ? d.selectedIcon : d.icon,
                                  ),
                                  title: Text(
                                    d.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => _go(i),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      _TopHeader(
                        userLabel: widget.userLabel,
                        onLogout: widget.onLogout,
                      ),
                      Expanded(child: _Content(index: _index)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isTablet) {
      return _wrap(
        PopScope(
          canPop: _canPop,
          onPopInvokedWithResult: (didPop, _) => _onPop(didPop),
          child: Scaffold(
            body: SafeArea(
              top: false,
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: _go,
                    // 15 destination × label = >1000px tinggi; rail tidak
                    // menggulir sendiri sehingga meluber 24–448px di tablet.
                    scrollable: true,
                    // Label membuat rail melar ~180px pada 600px dan menyisakan
                    // kartu KPI terlalu sempit. Di bawah 840 label disembunyikan
                    // (ikon + tooltip) supaya rail balik ke ~72px.
                    labelType: iconOnly
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    groupAlignment: -1.0,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                    destinations: [
                      for (final d in adminDestinations)
                        NavigationRailDestination(
                          // Tanpa label, ikon wajib punya tooltip agar
                          // tujuan tetap bisa dibaca.
                          icon: iconOnly
                              ? Tooltip(message: d.label, child: Icon(d.icon))
                              : Icon(d.icon),
                          selectedIcon: iconOnly
                              ? Tooltip(
                                  message: d.label,
                                  child: Icon(d.selectedIcon),
                                )
                              : Icon(d.selectedIcon),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: Column(
                      children: [
                        _TopHeader(
                          userLabel: widget.userLabel,
                          onLogout: widget.onLogout,
                        ),
                        Expanded(child: _Content(index: _index)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Mobile: tab memetakan ke route (bukan indeks mentah) agar tahan
    // terhadap perubahan urutan adminDestinations.
    final mobileRoutes = [
      '/admin/dashboard',
      '/admin/perkuliahan',
      '/admin/krs',
      '/admin/nilai',
    ];
    final currentRoute = adminDestinations[_index].route;
    final pos = mobileRoutes.indexOf(currentRoute);
    final bottomIndex = pos < 0 ? 4 : pos;
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) => _onPop(didPop),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('SIAKAD'),
          actions: [
            IconButton(
              tooltip: 'Notifikasi',
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined),
            ),
            const SizedBox(width: 4),
            _AccountMenu(label: widget.userLabel, onLogout: widget.onLogout),
            const SizedBox(width: 12),
          ],
        ),
        drawer: Drawer(
          child: _AdminNavList(
            selected: _index,
            onTap: (i) {
              _go(i);
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(top: false, child: _Content(index: _index)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: bottomIndex,
          onDestinationSelected: (i) {
            if (i == 4) {
              _scaffoldKey.currentState?.openDrawer();
            } else {
              final route = mobileRoutes[i];
              final target = adminDestinations.indexWhere(
                (d) => d.route == route,
              );
              if (target >= 0) _go(target);
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.meeting_room_outlined),
              selectedIcon: Icon(Icons.meeting_room),
              label: 'Kelas',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check),
              label: 'KRS',
            ),
            NavigationDestination(
              icon: Icon(Icons.grade_outlined),
              selectedIcon: Icon(Icons.grade),
              label: 'Nilai',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu),
              selectedIcon: Icon(Icons.menu_open),
              label: 'Menu',
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.school_rounded,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SIAKAD',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(letterSpacing: 1.5),
              ),
              Text(
                'Admin Console',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String userLabel;
  final VoidCallback? onLogout;

  const _TopHeader({this.userLabel = 'A', this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              hintText: 'Cari data akademik…',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onSubmitted: (_) {},
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
          const SizedBox(width: 4),
          _AccountMenu(label: userLabel, onLogout: onLogout),
        ],
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  final String label;
  final VoidCallback? onLogout;

  const _AccountMenu({required this.label, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(child: Text(label));
    final logout = onLogout;
    if (logout == null) return avatar;
    return PopupMenuButton<String>(
      tooltip: 'Akun',
      offset: const Offset(0, 48),
      onSelected: (v) {
        if (v == 'logout') logout();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'logout', child: Text('Keluar')),
      ],
      child: avatar,
    );
  }
}

class _AdminNavList extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _AdminNavList({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: _Brand(),
        ),
        for (var i = 0; i < adminDestinations.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: ListTile(
              selected: i == selected,
              selectedTileColor: Theme.of(context)
                  .colorScheme
                  .secondaryContainer,
              shape: const StadiumBorder(),
              leading: Icon(
                i == selected
                    ? adminDestinations[i].selectedIcon
                    : adminDestinations[i].icon,
              ),
              title: Text(
                adminDestinations[i].label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onTap(i),
            ),
          ),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  final int index;
  const _Content({required this.index});

  static const _pages = <Widget>[
    AdminDashboardPage(),
    UsersPage(),
    MasterPage(),
    CurriculumPage(),
    CivitasPage(),
    SchedulingPage(),
    KrsPage(),
    GradesPage(),
    AttendancePage(),
    AdvisorPage(),
    GraduationPage(),
    TransferPage(),
    FeederPage(),
    LettersPage(),
    AuditPage(),
  ];

  @override
  Widget build(BuildContext context) {
    if (index >= 0 && index < _pages.length) return _pages[index];
    final dest = adminDestinations[index];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(dest.icon, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(dest.label, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '${dest.route} — selesai di Fase 5.\nSeluruh 15 modul fungsional penuh.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
