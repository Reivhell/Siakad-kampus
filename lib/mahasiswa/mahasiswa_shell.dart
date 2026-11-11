import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../admin/widgets/bezel_card.dart';
import '../features/mahasiswa/providers/mahasiswa_providers.dart';
import 'models/mahasiswa_nav.dart';

/// Shell responsif portal mahasiswa (design.md §5):
/// ≥1024 drawer tetap, 600–1023 drawer, <600 NavigationBar 5 tab.
class MahasiswaShell extends ConsumerStatefulWidget {
  final String currentPath;
  final Widget child;
  final VoidCallback onLogout;

  const MahasiswaShell({
    super.key,
    required this.currentPath,
    required this.child,
    required this.onLogout,
  });

  @override
  ConsumerState<MahasiswaShell> createState() => _MahasiswaShellState();
}

class _MahasiswaShellState extends ConsumerState<MahasiswaShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _go(String path) {
    if (widget.currentPath != path) context.go(path);
  }

  void _logout() => widget.onLogout();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final idx = navIndexForPath(widget.currentPath);
    final nama = ref.watch(currentProfileProvider)?.nama ?? 'Mahasiswa';
    final periode = ref.watch(mahasiswaRepositoryProvider).periodeAktif.nama;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 280,
              child: _SidePanel(
                idx: idx,
                nama: nama,
                onSelect: _go,
                onLogout: _logout,
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  _TopBar(nama: nama, periode: periode),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (width >= 600) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('SIAKAD · Mahasiswa'),
          actions: [
            _TopActions(nama: nama, onLogout: _logout),
            const SizedBox(width: 8),
          ],
        ),
        drawer: Drawer(
          child: _DrawerPanel(idx: idx, onSelect: _go, onLogout: _logout),
        ),
        body: widget.child,
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          mahasiswaDestinations[idx].label == 'Beranda'
              ? 'SIAKAD · Mahasiswa'
              : mahasiswaDestinations[idx].label,
        ),
        actions: [
          _TopActions(nama: nama, onLogout: _logout),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        child: _DrawerPanel(idx: idx, onSelect: _go, onLogout: _logout),
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx <= 3 ? idx : 4,
        onDestinationSelected: (i) {
          if (i < 4) {
            _go(mahasiswaDestinations[i].path);
          } else {
            _scaffoldKey.currentState?.openDrawer();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'KRS',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Jadwal',
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
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
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
                'Portal Mahasiswa',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidePanel extends StatelessWidget {
  final int idx;
  final String nama;
  final void Function(String) onSelect;
  final VoidCallback onLogout;

  const _SidePanel({
    required this.idx,
    required this.nama,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: _Brand(),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              itemCount: mahasiswaDestinations.length,
              itemBuilder: (_, i) {
                final d = mahasiswaDestinations[i];
                final selected = i == idx;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: ListTile(
                    selected: selected,
                    selectedTileColor: cs.secondaryContainer,
                    shape: const StadiumBorder(),
                    leading: Icon(selected ? d.selectedIcon : d.icon),
                    title: Text(d.label),
                    onTap: () => onSelect(d.path),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: Text('Keluar ($nama)'),
              shape: const StadiumBorder(),
              onTap: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerPanel extends StatelessWidget {
  final int idx;
  final void Function(String) onSelect;
  final VoidCallback onLogout;

  const _DrawerPanel({
    required this.idx,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: _Brand(),
        ),
        for (var i = 0; i < mahasiswaDestinations.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: ListTile(
              selected: i == idx,
              selectedTileColor: cs.secondaryContainer,
              shape: const StadiumBorder(),
              leading: Icon(
                i == idx
                    ? mahasiswaDestinations[i].selectedIcon
                    : mahasiswaDestinations[i].icon,
              ),
              title: Text(mahasiswaDestinations[i].label),
              onTap: () {
                Navigator.pop(context);
                onSelect(mahasiswaDestinations[i].path);
              },
            ),
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Keluar'),
          shape: const StadiumBorder(),
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _TopActions extends StatelessWidget {
  final String nama;
  final VoidCallback onLogout;

  const _TopActions({required this.nama, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: nama,
      onSelected: (v) {
        if (v == 'profil') context.go('/mahasiswa/profil');
        if (v == 'keluar') onLogout();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'profil', child: Text('Profil')),
        PopupMenuItem(value: 'keluar', child: Text('Keluar')),
      ],
      child: CircleAvatar(
        radius: 16,
        child: Text(nama.isEmpty ? 'M' : nama.substring(0, 1).toUpperCase()),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String nama;
  final String periode;

  const _TopBar({required this.nama, required this.periode});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          BezelCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_available, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(periode, style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Info akademik',
            onPressed: () => context.go('/mahasiswa/info'),
            icon: const Icon(Icons.campaign_outlined),
          ),
          const SizedBox(width: 8),
          Text(nama, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Text(
              nama.isEmpty ? 'M' : nama.substring(0, 1).toUpperCase(),
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
