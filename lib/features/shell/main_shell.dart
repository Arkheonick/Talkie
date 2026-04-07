import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../utils/app_audio.dart';
import '../home/home_screen.dart';
import '../explore/explore_screen.dart';
import '../prof/prof_screen.dart';
import '../notebook/notebook_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // Track which tabs have been visited — screens are only created on first visit.
  // This prevents ProfScreen from speaking at startup while the user is on Home.
  final Set<int> _visited = {0};

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Accueil'),
    _TabItem(icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Explorer'),
    _TabItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Discussion'),
    _TabItem(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book_rounded, label: 'Carnet'),
  ];

  Widget _buildScreen(int i) {
    if (!_visited.contains(i)) return const SizedBox.expand();
    switch (i) {
      case 0: return const HomeScreen();
      case 1: return const ExploreScreen();
      case 2: return const ProfScreen();
      case 3: return const NotebookScreen();
      default: return const SizedBox.expand();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: List.generate(4, _buildScreen),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          AppAudio.stopAll(); // stop any playing TTS before switching tabs
          _visited.add(i);
          setState(() => _index = i);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primaryLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon, color: AppTheme.muted),
                  selectedIcon: Icon(t.activeIcon, color: AppTheme.primary),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({required this.icon, required this.activeIcon, required this.label});
}
