import 'package:flutter/material.dart';
import '../l10n/strings.dart';

import '../data/app_store.dart';
import '../models/anime.dart';
import 'catalog_screen.dart';
import 'detail_screen.dart';
import 'common.dart';
import 'visuals.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  WatchStatus? filter;
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.store.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final entries = store.entries
        .where((e) => filter == null || e.status == filter)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          context.l10n.watchlistHeading,
          eyebrow: context.l10n.myWatchlist,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(context.l10n.allCount('${store.entries.length}')),
                  selected: filter == null,
                  onSelected: (_) => setState(() => filter = null),
                ),
              ),
              ...WatchStatus.values.map(
                (status) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(watchStatusLabel(context, status)),
                    selected: filter == status,
                    onSelected: (_) => setState(() => filter = status),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (store.busy) const LinearProgressIndicator(),
        if (store.watchError != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(watchErrorText(context, store.watchError!)),
                TextButton(
                  onPressed: store.refreshWatchlist,
                  child: Text(context.l10n.retrySync),
                ),
              ],
            ),
          ),
        Expanded(
          child: entries.isEmpty
              ? EmptyPanel(
                  context.l10n.watchlistEmpty,
                  icon: Icons.bookmark_add_outlined,
                )
              : RefreshIndicator(
                  onRefresh: store.refreshWatchlist,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final total = entry.anime.episodes;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Cover(
                                  entry.anime.image,
                                  width: 88,
                                  height: 132,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => DetailScreen(
                                            anime: entry.anime,
                                            store: store,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        entry.anime.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownButton<WatchStatus>(
                                      isExpanded: true,
                                      value: entry.status,
                                      items: WatchStatus.values
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(
                                                watchStatusLabel(context, s),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: store.busy
                                          ? null
                                          : (status) => perform(
                                              context,
                                              () => store.save(
                                                entry.withStatus(status!),
                                              ),
                                            ),
                                    ),
                                    LinearProgressIndicator(
                                      value: total != null && total > 0
                                          ? (entry.watched / total).clamp(
                                              0.0,
                                              1.0,
                                            )
                                          : 0,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            context.l10n.episodeCount(
                                              '${entry.watched} / ${total ?? '?'}',
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: context.l10n.oneLess,
                                          onPressed:
                                              store.busy || entry.watched == 0
                                              ? null
                                              : () => perform(
                                                  context,
                                                  () => store.save(
                                                    entry.progress(-1),
                                                  ),
                                                ),
                                          icon: const Icon(Icons.remove),
                                        ),
                                        IconButton.filledTonal(
                                          tooltip: context.l10n.oneWatched,
                                          onPressed:
                                              store.busy ||
                                                  (total != null &&
                                                      total > 0 &&
                                                      entry.watched >= total)
                                              ? null
                                              : () => perform(
                                                  context,
                                                  () => store.save(
                                                    entry.progress(1),
                                                  ),
                                                ),
                                          icon: const Icon(Icons.add),
                                        ),
                                      ],
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: store.busy
                                            ? null
                                            : () async {
                                                final confirm =
                                                    await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                            title: Text(
                                                              context
                                                                  .l10n
                                                                  .removeAnime,
                                                            ),
                                                            content: Text(
                                                              context
                                                                  .l10n
                                                                  .removeProgress,
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      false,
                                                                    ),
                                                                child: Text(
                                                                  context
                                                                      .l10n
                                                                      .cancel,
                                                                ),
                                                              ),
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      true,
                                                                    ),
                                                                child: Text(
                                                                  context
                                                                      .l10n
                                                                      .remove,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                if (confirm == true &&
                                                    context.mounted) {
                                                  await perform(
                                                    context,
                                                    () => store.remove(
                                                      entry.anime.id,
                                                    ),
                                                  );
                                                }
                                              },
                                        child: Text(context.l10n.remove),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
