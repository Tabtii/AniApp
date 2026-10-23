import 'package:flutter/material.dart';
import '../data/app_store.dart';
import '../models/anime.dart';
import '../models/content.dart';
import '../l10n/strings.dart';
import 'visuals.dart';
import 'detail_screen.dart';
import 'content_screens.dart';
import 'watch_actions.dart';
import 'common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store, required this.navigate});
  final AppStore store;
  final ValueChanged<int> navigate;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<ReleaseEvent>> releases;
  late Future<List<Map<String, dynamic>>> news;
  String settings = '';
  String get keySettings =>
      '${widget.store.scope}|${widget.store.region}|${widget.store.dubLanguages}|${widget.store.languageMode}|${widget.store.newsLanguages}|${widget.store.providers}|${widget.store.mutedSources}|${widget.store.personalNews}|${(widget.store.entries.map((e) => e.anime.id).toList()..sort()).join(',')}';
  @override
  void initState() {
    super.initState();
    settings = keySettings;
    _load();
    widget.store.addListener(_changed);
  }

  void _load() {
    releases = widget.store.calendarReleases();
    news = widget.store.news();
  }

  void _changed() {
    if (mounted) {
      setState(() {
        if (settings != keySettings) {
          settings = keySettings;
          _load();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_changed);
    super.dispose();
  }

  Future<void> refresh() async {
    setState(_load);
    await Future.wait([
      releases.then((_) {}).catchError((Object _) {}),
      news.then((_) {}).catchError((Object _) {}),
      widget.store.refreshWatchlist(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final watching = store.entries
        .where((e) => e.status == WatchStatus.watching)
        .toList()
        .reversed
        .take(5)
        .toList();
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            context.l10n.todayHeading,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${store.region} · ${store.dubLanguages.map((e) => languageLabel(e, context)).join(' / ')}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SyncStatus(store: store),
          const SizedBox(height: 24),
          Text(
            context.l10n.continueWatching,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (watching.isEmpty)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(context.l10n.startYourList),
                trailing: const Icon(Icons.explore_outlined),
                onTap: () => widget.navigate(1),
              ),
            ),
          if (watching.isEmpty)
            OutlinedButton.icon(
              onPressed: () => widget.navigate(store.entries.isEmpty ? 1 : 4),
              icon: const Icon(Icons.explore_outlined),
              label: Text(
                store.entries.isEmpty
                    ? context.l10n.discoverFirst
                    : context.l10n.myList,
              ),
            ),
          for (final entry in watching)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              DetailScreen(anime: entry.anime, store: store),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 44,
                              height: 66,
                              child: Artwork(entry.anime.image),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              entry.anime.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    WatchProgress(store: store, entry: entry),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            context.l10n.upcomingForYou,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextButton(
            onPressed: () => widget.navigate(2),
            child: Text(context.l10n.openCalendar),
          ),
          FutureBuilder<List<ReleaseEvent>>(
            future: releases,
            builder: (context, s) {
              if (s.hasError) return Text(context.l10n.calendarLoadError);
              if (!s.hasData) return const LinearProgressIndicator();
              final list = s.data!
                  .where(
                    (e) =>
                        store.isSaved(e.animeId ?? -1) &&
                        (store.providers.isEmpty ||
                            e.kind == 'japan' ||
                            store.providers.contains(e.provider)),
                  )
                  .take(4)
                  .toList();
              return Column(
                children: [
                  if (list.isEmpty) Text(context.l10n.noPersonalDates),
                  for (final e in list)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shortDate(e.date, context)),
                        const SizedBox(height: 8),
                        ReleaseTile(event: e, store: store),
                      ],
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('News', style: Theme.of(context).textTheme.titleLarge),
          TextButton(
            onPressed: () => widget.navigate(3),
            child: Text(context.l10n.openNews),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: news,
            builder: (context, s) {
              if (s.hasError) return Text(context.l10n.newsLoadError);
              if (!s.hasData) return const LinearProgressIndicator();
              final own = s.data!
                  .where(
                    (n) => store.isSaved((n['mal_id'] as num?)?.toInt() ?? -1),
                  )
                  .take(3)
                  .toList();
              final selected = own.isNotEmpty ? own : s.data!.take(3).toList();
              return Column(
                children: [
                  if (own.isEmpty && store.entries.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(context.l10n.noPersonalNews),
                    ),
                  for (final n in selected)
                    NewsCard(
                      news: n,
                      featured: !store.spoilerSafe && n == selected.first,
                      hidePreview: store.spoilerSafe,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
