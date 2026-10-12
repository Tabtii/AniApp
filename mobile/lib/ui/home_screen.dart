import 'package:flutter/material.dart';
import '../data/app_store.dart';
import '../models/anime.dart';
import '../models/content.dart';
import '../l10n/strings.dart';
import 'common.dart';
import 'visuals.dart';
import 'detail_screen.dart';
import 'content_screens.dart';
import 'companion_screens.dart';

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
      '${widget.store.region}|${widget.store.dubLanguages}|${widget.store.newsLanguages}|${widget.store.providers}|${widget.store.mutedSources}|${widget.store.personalNews}';
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  coral.withValues(alpha: .22),
                  lavender.withValues(alpha: .1),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tag(
                  '${store.region} · ${store.dubLanguages.map((e) => e.toUpperCase()).join(' / ')}',
                  icon: Icons.language_rounded,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.todayHeading,
                  style: const TextStyle(
                    fontSize: 32,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(context.l10n.todayIntro),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => InboxScreen(store: store),
                    ),
                  ),
                  icon: const Icon(Icons.notifications_none_rounded),
                  label: Text(context.l10n.notifications),
                ),
              ],
            ),
          ),
          if (store.pendingChanges > 0)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cloud_upload_outlined),
              title: Text(
                '${context.l10n.syncPending}: ${store.pendingChanges}',
              ),
              trailing: IconButton(
                tooltip: context.l10n.syncNow,
                onPressed: store.syncing ? null : store.refreshWatchlist,
                icon: const Icon(Icons.sync),
              ),
            ),
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
          for (final entry in watching)
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: SizedBox(
                  width: 46,
                  height: 68,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Artwork(entry.anime.image),
                  ),
                ),
                title: Text(
                  entry.anime.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${entry.watched} / ${entry.anime.episodes ?? '?'}',
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        DetailScreen(anime: entry.anime, store: store),
                  ),
                ),
                trailing: IconButton.filledTonal(
                  tooltip: context.l10n.oneWatched,
                  icon: const Icon(Icons.add),
                  onPressed: () => perform(context, () async {
                    await store.changeProgress(entry, 1);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.progressSaved),
                        action: SnackBarAction(
                          label: context.l10n.undo,
                          onPressed: () =>
                              perform(context, () => store.save(entry)),
                        ),
                      ),
                    );
                  }),
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
