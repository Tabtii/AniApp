import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/strings.dart';

import '../data/app_store.dart';
import 'catalog_screen.dart';
import 'watchlist_screen.dart';
import 'content_screens.dart';
import 'profile_screen.dart';
import 'visuals.dart';
import 'brand.dart';
import 'login_dialog.dart';
import 'home_screen.dart';
import 'companion_screens.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store, this.startupWarning});
  final AppStore store;
  final String? startupWarning;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int index = 0;
  final visited = <int>{0};
  void navigate(int value) => setState(() {
    index = value;
    visited.add(value);
  });
  bool _recoveryOpen = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.store.addListener(_checkRecovery);
    _checkRecovery();
    if (widget.startupWarning != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.cloudWarning)));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.passwordChanged)));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.store.refreshWatchlist());
      unawaited(widget.store.refreshUnreadCount());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.store.removeListener(_checkRecovery);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(store: widget.store, navigate: navigate),
      CatalogScreen(store: widget.store),
      CalendarScreen(store: widget.store),
      NewsScreen(store: widget.store),
      WatchlistScreen(store: widget.store),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final destinations = [
      (Icons.home_outlined, context.l10n.today),
      (Icons.explore_outlined, context.l10n.discover),
      (Icons.calendar_month_outlined, context.l10n.calendar),
      (Icons.newspaper_outlined, 'News'),
      (Icons.bookmark_outline, context.l10n.myList),
    ];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 62,
        titleSpacing: 20,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
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
          ListenableBuilder(
            listenable: widget.store,
            builder: (context, _) => IconButton(
              tooltip: context.l10n.notifications,
              icon: Badge.count(
                count: widget.store.unreadCount,
                isLabelVisible: widget.store.unreadCount > 0,
                child: const Icon(Icons.notifications_none_rounded),
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => InboxScreen(store: widget.store),
                  ),
                );
                await widget.store.refreshUnreadCount();
              },
            ),
          ),
          IconButton(
            tooltip: context.l10n.openProfile,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(context.l10n.profile)),
                  body: SafeArea(child: ProfileScreen(store: widget.store)),
                ),
              ),
            ),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: navigate,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: Icon(d.$1),
                      label: Text(d.$2),
                    ),
                ],
              ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: IndexedStack(
                    index: index,
                    children: [
                      for (var i = 0; i < pages.length; i++)
                        visited.contains(i)
                            ? pages[i]
                            : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: navigate,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home_rounded),
                  label: context.l10n.today,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.explore_outlined),
                  selectedIcon: const Icon(Icons.explore),
                  label: context.l10n.discover,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: context.l10n.calendar,
                ),
                const NavigationDestination(
                  icon: Icon(Icons.newspaper_outlined),
                  label: 'News',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.bookmark_outline),
                  selectedIcon: const Icon(Icons.bookmark),
                  label: context.l10n.myList,
                ),
              ],
            ),
    );
  }
}
