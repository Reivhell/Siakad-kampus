import 'package:flutter/material.dart';

import 'dashboard/admin_dashboard_page.dart';
import 'models/admin_nav.dart';

/// Shell responsif M3 — satu codebase tiga platform (design.md §5).
/// ≥1024: NavigationDrawer + header. 600–1023: NavigationRail.
/// <600: AppBar + NavigationBar 5 tab (design.md §5.2).
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;
    final isTablet = width >= 600 && width < 1024;

    if (isDesktop) {
      return Scaffold(
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
                            padding: const EdgeInsets.symmetric(vertical: 1),
                            child: ListTile(
                              selected: selected,
                              selectedTileColor: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              shape: const StadiumBorder(),
                              leading: Icon(
                                selected ? d.selectedIcon : d.icon,
                              ),
                              title: Text(d.label),
                              onTap: () => setState(() => _index = i),
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
                  const _TopHeader(),
                  Expanded(child: _Content(index: _index)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isTablet) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('SIAKAD'),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: CircleAvatar(child: Text('A')),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
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
                    selected: i == _index,
                    selectedTileColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    shape: const StadiumBorder(),
                    leading: Icon(
                      i == _index
                          ? adminDestinations[i].selectedIcon
                          : adminDestinations[i].icon,
                    ),
                    title: Text(adminDestinations[i].label),
                    onTap: () {
                      setState(() => _index = i);
                      Navigator.pop(context);
                    },
                  ),
                ),
            ],
          ),
        ),
        body: Column(
          children: [
            const _TopHeader(),
            Expanded(child: _Content(index: _index)),
          ],
        ),
      );
    }

    // Mobile View
    final mobileTabs = [0, 5, 6, 7, 14]; 
    final bottomIndex = mobileTabs.indexOf(_index).clamp(0, 4);
    return Scaffold(
      appBar: AppBar(
        title: const Text('SIAKAD'),
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () {},
            icon: const Badge(
              label: Text('8'),
              child: Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 4),
          const CircleAvatar(child: Text('A')),
          const SizedBox(width: 12),
        ],
      ),
      drawer: Drawer(
        child: ListView(
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
                  selected: i == _index,
                  selectedTileColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  shape: const StadiumBorder(),
                  leading: Icon(
                    i == _index
                        ? adminDestinations[i].selectedIcon
                        : adminDestinations[i].icon,
                  ),
                  title: Text(adminDestinations[i].label),
                  onTap: () {
                    setState(() => _index = i);
                    Navigator.pop(context);
                  },
                ),
              ),
          ],
        ),
      ),
      body: _Content(index: _index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: bottomIndex,
        onDestinationSelected: (i) => setState(() => _index = mobileTabs[i]),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(letterSpacing: 1.5),
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
  const _TopHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              hintText: 'Cari MK / NIM / NIDN…  (Ctrl+F)',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Notifikasi (8)',
            onPressed: () {},
            icon: const Badge(
              label: Text('8'),
              child: Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 4),
          const CircleAvatar(child: Text('A')),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final int index;
  const _Content({required this.index});

  @override
  Widget build(BuildContext context) {
    if (index == 0) return const AdminDashboardPage();
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
              '${dest.route} — dibangun pada fase berikutnya.\nDashboard Fase 1 sudah fungsional penuh.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
