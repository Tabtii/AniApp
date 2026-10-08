import 'package:flutter/material.dart';

import '../data/app_store.dart';
import 'catalog_screen.dart';
import 'watchlist_screen.dart';
import 'content_screens.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store, this.startupWarning});
  final AppStore store;
  final String? startupWarning;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  @override
  void initState() {
    super.initState();
    if (widget.startupWarning != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(widget.startupWarning!)));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CatalogScreen(store: widget.store),
      WatchlistScreen(store: widget.store),
      CalendarScreen(store: widget.store),
      NewsScreen(store: widget.store),
      ProfileScreen(store: widget.store),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AniApp',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Dein Anime-Begleiter',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Entdecken',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Meine Liste',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Kalender',
          ),
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            label: 'News',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
