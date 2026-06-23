import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_state.dart';
import '../main.dart';
import 'dashboard_screen.dart';
import 'classes_screen.dart';
import 'students_screen.dart';
import 'grades_screen.dart';
import 'analysis_screen.dart';
import 'scores_screen.dart';
import 'plans_screen.dart';
import 'not_merkezi_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  final pages = const [
    {'icon': Icons.home_rounded, 'label': 'Ana Ekran', 'page': DashboardScreen()},
    {'icon': Icons.school_rounded, 'label': 'Sınıflarım', 'page': ClassesScreen()},
    {'icon': Icons.groups_rounded, 'label': 'Öğrenciler', 'page': StudentsScreen()},
    {'icon': Icons.edit_note_rounded, 'label': 'Not Defteri', 'page': GradesScreen()},
    {'icon': Icons.science_rounded, 'label': 'Madde Analizi', 'page': AnalysisScreen()},
    {'icon': Icons.star_rounded, 'label': 'Puan Sistemi', 'page': ScoresScreen()},
    {'icon': Icons.menu_book_rounded, 'label': 'Ders Planları', 'page': PlansScreen()},
    {'icon': Icons.folder_special_rounded, 'label': 'Not Merkezi', 'page': NotMerkeziScreen()},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadAll();
    });
  }

  void _select(int i) {
    setState(() => index = i);
    if (Navigator.canPop(context)) {
      // Drawer açıksa kapat
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isWide = MediaQuery.of(context).size.width >= 800;
    final appState = context.watch<AppState>();

    final body = appState.loading
        ? const Center(child: CircularProgressIndicator(color: kAccent))
        : AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: KeyedSubtree(
              key: ValueKey(index),
              child: pages[index]['page'] as Widget,
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle),
            ),
            const Text('📋 Öğretmen Dosyası'),
          ],
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Chip(
                backgroundColor: kAccentSoft,
                side: BorderSide.none,
                avatar: const Icon(Icons.person, size: 15, color: kAccent),
                label: Text(user.email ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1A1D2E))),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Çıkış',
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: isWide ? null : _AppDrawer(pages: pages, selected: index, onSelect: _select),
      body: isWide
          ? Row(
              children: [
                _SideNav(pages: pages, selected: index, onSelect: _select),
                const VerticalDivider(width: 1),
                Expanded(child: Container(color: kBg, child: body)),
              ],
            )
          : Container(color: kBg, child: body),
    );
  }
}

class _SideNav extends StatelessWidget {
  final List pages;
  final int selected;
  final ValueChanged<int> onSelect;
  const _SideNav({required this.pages, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          for (var i = 0; i < pages.length; i++)
            _NavItem(
              icon: pages[i]['icon'] as IconData,
              label: pages[i]['label'] as String,
              selected: selected == i,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final List pages;
  final int selected;
  final ValueChanged<int> onSelect;
  const _AppDrawer({required this.pages, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kAccent, Color(0xFF6C9BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Row(
              children: [
                Text('📋', style: TextStyle(fontSize: 26)),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Öğretmen Dosyası',
                      style: TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (var i = 0; i < pages.length; i++)
                  _NavItem(
                    icon: pages[i]['icon'] as IconData,
                    label: pages[i]['label'] as String,
                    selected: selected == i,
                    onTap: () {
                      onSelect(i);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem(
      {required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Material(
        color: selected ? kAccentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, size: 21, color: selected ? kAccent : Colors.grey.shade600),
                const SizedBox(width: 14),
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? kAccent : const Color(0xFF1A1D2E))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
