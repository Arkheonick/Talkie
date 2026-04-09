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
  late final PageController _pageController;

  // Discussion (index 2) auto-speaks on initState — only build it when selected.
  // All other tabs can be pre-built during swipe for smooth animation.
  final Set<int> _visited = {0};

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined,          activeIcon: Icons.home_rounded,          label: 'Accueil'),
    _TabItem(icon: Icons.explore_outlined,        activeIcon: Icons.explore_rounded,        label: 'Explorer'),
    _TabItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Discussion'),
    _TabItem(icon: Icons.menu_book_outlined,      activeIcon: Icons.menu_book_rounded,      label: 'Lexique'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  // Pre-build non-sensitive tabs as the user starts swiping, so the
  // animation is smooth. Discussion stays lazy (auto-speaks on initState).
  void _onScroll() {
    if (!mounted || !_pageController.hasClients) return;
    final page = _pageController.page ?? 0.0;
    bool changed = false;
    for (final i in [page.floor(), page.ceil()]) {
      if (i >= 0 && i < 4 && i != 2 && !_visited.contains(i)) {
        _visited.add(i);
        changed = true;
      }
    }
    if (changed) setState(() {});
  }

  void _selectTab(int i) {
    AppAudio.stopAll();
    _visited.add(i);
    setState(() => _index = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildScreen(int i) {
    if (!_visited.contains(i)) return const ColoredBox(color: Colors.white);
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
      body: PageView.builder(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        itemCount: 4,
        onPageChanged: (i) {
          AppAudio.stopAll();
          _visited.add(i);
          setState(() => _index = i);
        },
        itemBuilder: (_, i) => _KeepAlivePage(child: _buildScreen(i)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
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

// Wraps a page in AutomaticKeepAliveClientMixin so PageView keeps its state
// alive when the user scrolls away.
class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
