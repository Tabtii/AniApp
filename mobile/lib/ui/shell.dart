import 'package:flutter/material.dart';

import '../data/app_store.dart';
import 'catalog_screen.dart';
import 'watchlist_screen.dart';
import 'content_screens.dart';
import 'profile_screen.dart';
import 'visuals.dart';
import 'brand.dart';
import 'login_dialog.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store, this.startupWarning});
  final AppStore store;
  final String? startupWarning;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  bool _recoveryOpen = false;
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_checkRecovery);
    _checkRecovery();
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

  void _checkRecovery() {
    if (_recoveryOpen ||
        !widget.store.passwordRecoveryPending ||
        widget.store.backend == null) {
      return;
    }
    _recoveryOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final done = await showDialog<bool>(
        context: context,
        builder: (_) => LoginDialog(
          backend: widget.store.backend!,
          initialMode: LoginMode.newPassword,
        ),
      );
      widget.store.finishPasswordRecovery();
      _recoveryOpen = false;
      if (mounted && done == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dein Passwort wurde geändert.')),
        );
      }
    });
  }

  @override
  void dispose() {
    widget.store.removeListener(_checkRecovery);
    super.dispose();
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
            const AniAppMark(size: 35),
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
