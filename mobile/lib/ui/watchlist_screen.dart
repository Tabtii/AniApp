import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../data/app_store.dart';
import '../models/anime.dart';
import 'detail_screen.dart';
import 'common.dart';
import 'visuals.dart';
import 'watch_actions.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  WatchStatus? filter;
  final search = TextEditingController();
  String sort = 'recent';
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_changed);
    search.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.store.removeListener(_changed);
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final query = search.text.trim().toLowerCase();
    final entries = store.entries.reversed
        .where(
          (e) =>
              (filter == null || e.status == filter) &&
              e.anime.title.toLowerCase().contains(query),
        )
        .toList();
    if (sort == 'title') {
      entries.sort(
        (a, b) =>
            a.anime.title.toLowerCase().compareTo(b.anime.title.toLowerCase()),
      );
    }
    if (sort == 'progress') {
      entries.sort((a, b) => b.watched.compareTo(a.watched));
    }
    return RefreshIndicator(
      onRefresh: store.refreshWatchlist,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SectionHeading(
              context.l10n.watchlistHeading,
              eyebrow: context.l10n.myWatchlist,
              trailing: PopupMenuButton<String>(
                tooltip: context.l10n.sortList,
                icon: const Icon(Icons.sort_rounded),
                onSelected: (value) => setState(() => sort = value),
                itemBuilder: (_) => [
                  for (final option in {
                    'recent': context.l10n.sortRecent,
                    'title': context.l10n.sortTitle,
                    'progress': context.l10n.sortProgress,
                  }.entries)
                    CheckedPopupMenuItem(
                      value: option.key,
                      checked: sort == option.key,
                      child: Text(option.value),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: search,
                decoration: InputDecoration(
                  hintText: context.l10n.listSearch,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.l10n.clearSearch,
                          onPressed: search.clear,
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  for (final status in <WatchStatus?>[
                    null,
                    ...WatchStatus.values,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          status == null
                              ? context.l10n.allCount('${store.entries.length}')
                              : watchStatusLabel(context, status),
                        ),
                        selected: filter == status,
                        onSelected: (_) => setState(() => filter = status),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: SyncStatus(store: store),
            ),
          ),
          if (entries.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyPanel(
                store.entries.isEmpty
                    ? context.l10n.watchlistEmpty
                    : context.l10n.noListMatches,
                icon: Icons.bookmark_add_outlined,
                action: store.entries.isEmpty
                    ? null
                    : TextButton(
                        onPressed: () {
                          search.clear();
                          setState(() => filter = null);
                        },
                        child: Text(context.l10n.all),
                      ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            sliver: SliverList.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                void open() => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        DetailScreen(anime: entry.anime, store: store),
                  ),
                );
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: open,
                              borderRadius: BorderRadius.circular(12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 64,
                                  height: 96,
                                  child: Artwork(entry.anime.image),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: open,
                                    child: Text(
                                      entry.anime.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    watchStatusLabel(context, entry.status),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        WatchProgress(store: store, entry: entry),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
