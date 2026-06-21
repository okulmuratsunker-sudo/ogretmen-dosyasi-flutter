import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_state.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isWide = MediaQuery.of(context).size.width >= 800;
    final appState = context.watch<AppState>();

    final body = appState.loading
        ? const Center(child: CircularProgressIndicator())
        : (pages[index]['page'] as Widget);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Öğretmen Dosyası'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                avatar: const Icon(Icons.person, size: 16),
                label: Text(user.email ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış',
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: ListView(
                children: [
                  const DrawerHeader(
                      child: Text('📋 Öğretmen Dosyası',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))),
                  for (var i = 0; i < pages.length; i++)
                    ListTile(
                      leading: Icon(pages[i]['icon'] as IconData),
                      title: Text(pages[i]['label'] as String),
                      selected: index == i,
                      onTap: () {
                        setState(() => index = i);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (i) => setState(() => index = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final p in pages)
                      NavigationRailDestination(
                        icon: Icon(p['icon'] as IconData),
                        label: Text(p['label'] as String),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
    );
  }
}
