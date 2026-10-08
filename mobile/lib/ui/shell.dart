import 'package:flutter/material.dart';

import '../data/app_store.dart';
import 'catalog_screen.dart';
import 'watchlist_screen.dart';
import 'content_screens.dart';
import 'profile_screen.dart';
import 'visuals.dart';

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
        toolbarHeight: 62,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [coral, Color(0xFFA47FEF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 9),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'ani'),
                  TextSpan(
                    text: 'app',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.3,
              ),
            ),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: widget.store,
            builder: (context, _) => Tag(
              widget.store.region,
              icon: Icons.language_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            tooltip: 'Profil öffnen',
            onPressed: () => setState(() => index = 4),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 8),
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
