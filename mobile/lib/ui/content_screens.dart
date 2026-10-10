import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/strings.dart';
import '../data/app_store.dart';
import '../models/content.dart';
import '../models/anime.dart';
import 'detail_screen.dart';
import 'common.dart';
import 'visuals.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Future<List<ReleaseEvent>> future;
  bool onlyMine = false;
  String _settings = '';
  String? selectedDay;
  String? selectedProvider;
  String providerLabel(ReleaseEvent e) =>
      e.kind == 'japan' ? 'Japan (TV)' : e.provider;
  String get _key =>
      '${widget.store.region}|${widget.store.dubLanguages.join(',')}|${widget.store.languageMode}';
  @override
  void initState() {
    super.initState();
    _settings = _key;
    future = widget.store.calendarReleases();
    widget.store.addListener(_changed);
  }

  void _changed() {
    if (mounted) {
      setState(() {
        if (_settings != _key) {
          _settings = _key;
          selectedDay = null;
          selectedProvider = null;
          future = widget.store.calendarReleases();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_changed);
    super.dispose();
  }

  Future<void> reload() async {
    final next = widget.store.calendarReleases();
    setState(() => future = next);
    try {
      await next;
    } catch (_) {
      // FutureBuilder presents the error and retry action.
    }
  }

  String dayKey(DateTime? date) =>
      date == null ? 'offen' : '${date.year}-${date.month}-${date.day}';
  String dayLabel(DateTime? date) {
    if (date == null) return context.l10n.dateTba;
    return DateFormat(
      context.l10n.localeName == 'de' ? 'EEEE, d. MMMM' : 'EEEE, MMMM d',
      context.l10n.localeName,
    ).format(date);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SectionHeading(
        context.l10n.nextEpisode,
        eyebrow: context.l10n.releaseCalendar(widget.store.region),
        trailing: IconButton(
          tooltip: context.l10n.refresh,
          onPressed: reload,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              label: Text(context.l10n.myWatchlist),
              selected: onlyMine,
              onSelected: (v) => setState(() {
                onlyMine = v;
                selectedDay = null;
              }),
              avatar: const Icon(Icons.bookmark_outline_rounded, size: 16),
            ),
            FilterChip(
              label: Text(
                'Dub · ${widget.store.dubLanguages.map((code) => languageLabel(code, context)).join(' / ')}',
              ),
              selected: widget.store.languageMode == 'dub',
              onSelected: (value) => perform(
                context,
                () => widget.store.setCalendarMode(value ? 'dub' : 'any'),
              ),
              avatar: const Icon(Icons.record_voice_over_rounded, size: 16),
            ),
            IconButton(
              tooltip: context.l10n.aboutTimes,
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (context) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Text(context.l10n.calendarHint),
                ),
              ),
              icon: const Icon(Icons.info_outline_rounded, size: 16),
            ),
          ],
        ),
      ),
      Expanded(
        child: FutureBuilder<List<ReleaseEvent>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return EmptyPanel(
                context.l10n.calendarLoadError,
                action: OutlinedButton(
                  onPressed: reload,
                  child: Text(context.l10n.retry),
                ),
              );
            }
            final source = snapshot.data ?? [];
            final providers = source.map(providerLabel).toSet().toList()
              ..sort();
            final provider = providers.contains(selectedProvider)
                ? selectedProvider
                : null;
            final all = source
                .where((e) => provider == null || providerLabel(e) == provider)
                .where(
                  (e) =>
                      !onlyMine ||
                      (e.animeId != null && widget.store.isSaved(e.animeId!)),
                )
                .toList();
            final dates = <String, DateTime?>{
              for (final e in all) dayKey(e.date): e.date,
            };
            final day = dates.containsKey(selectedDay) ? selectedDay : null;
            final items = all
                .where((e) => day == null || dayKey(e.date) == day)
                .toList();
            return RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Text(
                      context.l10n.allSeasons,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                    child: Row(
                      children: [
                        for (final name in <String?>[null, ...providers])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(name ?? context.l10n.allProviders),
                              selected: provider == name,
                              onSelected: (_) => setState(() {
                                selectedProvider = name;
                                selectedDay = null;
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(context.l10n.allDays),
                            selected: day == null,
                            onSelected: (_) =>
                                setState(() => selectedDay = null),
                          ),
                        ),
                        ...dates.entries.map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                d.value == null
                                    ? context.l10n.undated
                                    : '${d.value!.day}.${d.value!.month}.',
                              ),
                              selected: day == d.key,
                              onSelected: (_) =>
                                  setState(() => selectedDay = d.key),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 70),
                      child: EmptyPanel(
                        context.l10n.calendarEmpty,
                        icon: Icons.event_available_rounded,
                      ),
                    ),
                  for (var i = 0; i < items.length; i++) ...[
                    if (i == 0 ||
                        dayKey(items[i - 1].date) != dayKey(items[i].date))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Text(
                          dayLabel(items[i].date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _ReleaseTile(event: items[i], store: widget.store),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _ReleaseTile extends StatelessWidget {
  const _ReleaseTile({required this.event, required this.store});
  final ReleaseEvent event;
  final AppStore store;
  @override
  Widget build(BuildContext context) {
    final e = event;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 47,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.startsAt == null
                        ? (e.startsOn == null ? 'TBA' : 'Tag')
                        : timeLabel(e.startsAt),
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.startsAt == null
                        ? (e.startsOn == null
                              ? context.l10n.undatedUpper
                              : context.l10n.noTime)
                        : context.l10n.timeUpper,
                    style: TextStyle(
                      fontSize: 8,
                      letterSpacing: 1.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: e.animeId == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DetailScreen(
                            anime: Anime(
                              id: e.animeId!,
                              title: e.title,
                              image: e.image,
                            ),
                            store: store,
                          ),
                        ),
                      ),
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 50,
                          height: 76,
                          child: Artwork(
                            e.image,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${e.kind == 'japan'
                                  ? 'Japan'
                                  : e.kind == 'dub'
                                  ? 'Dub · ${languageLabel(e.language ?? '?', context)}'
                                  : 'Streaming'}${e.episode == null ? '' : ' · ${context.l10n.episodeNumber('${e.episode}')}'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              e.kind == 'japan'
                                  ? context.l10n.japaneseBroadcast
                                  : e.provider,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                            if (e.note != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                e.note!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              e.status == 'estimated'
                                  ? context.l10n.estimated
                                  : e.status == 'confirmed'
                                  ? context.l10n.confirmed
                                  : e.status == 'delayed'
                                  ? context.l10n.delayed
                                  : context.l10n.announced,
                              style: TextStyle(
                                fontSize: 10,
                                color: scheme.secondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (e.checkedAt != null)
                              Text(
                                context.l10n.checkedOn(
                                  shortDate(e.checkedAt, context),
                                ),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 26,
                        height: 30,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          tooltip: context.l10n.openDateSource,
                          onPressed: () => openSource(context, e.source),
                          icon: Icon(
                            Icons.north_east_rounded,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<Map<String, dynamic>>> future;
  String? category;
  late String _languages;
  @override
  void initState() {
    super.initState();
    _languages = widget.store.newsLanguages.join(',');
    future = widget.store.news();
    widget.store.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _changed();
  }

  void _changed() {
    final next = widget.store.newsLanguages.join(',');
    if (!mounted || _languages == next) return;
    setState(() {
      _languages = next;
      future = widget.store.news();
    });
  }

  @override
  void dispose() {
    widget.store.removeListener(_changed);
    super.dispose();
  }

  Future<void> reload() async {
    final next = widget.store.news();
    setState(() => future = next);
    try {
      await next;
    } catch (_) {
      // FutureBuilder presents the error and retry action.
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SectionHeading(
        context.l10n.newsHeading,
        eyebrow: context.l10n.newsAnnouncements,
        trailing: IconButton(
          tooltip: context.l10n.refresh,
          onPressed: reload,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            for (final entry in <String?, String>{
              null: context.l10n.all,
              'season': context.l10n.seasons,
              'streaming': 'Streaming',
              'dub': 'Dubs',
            }.entries)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: category == entry.key,
                  onSelected: (_) => setState(() => category = entry.key),
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return EmptyPanel(
                context.l10n.newsLoadError,
                action: OutlinedButton(
                  onPressed: reload,
                  child: Text(context.l10n.retry),
                ),
              );
            }
            final rows = (snapshot.data ?? [])
                .where((n) => category == null || n['category'] == category)
                .toList();
            if (rows.isEmpty) {
              return EmptyPanel(
                context.l10n.newsEmpty,
                icon: Icons.auto_awesome_rounded,
              );
            }
            return RefreshIndicator(
              onRefresh: reload,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemCount: rows.length,
                itemBuilder: (context, i) =>
                    NewsCard(news: rows[i], featured: i == 0),
              ),
            );
          },
        ),
      ),
    ],
  );
}

String newsCategory(BuildContext context, dynamic value) => switch (value) {
  'season' => context.l10n.newSeasons,
  'dub' => 'Dub-News',
  'streaming' => 'Streaming',
  _ => 'Anime-News',
};

class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.news, this.featured = false});
  final Map<String, dynamic> news;
  final bool featured;
  @override
  Widget build(BuildContext context) {
    final n = news;
    final scheme = Theme.of(context).colorScheme;
    final date = DateTime.tryParse(
      n['published_at'] as String? ?? '',
    )?.toLocal();
    final metadata =
        '${n['source_name']} · ${shortDate(date, context)} · ${(n['language'] as String? ?? '?').toUpperCase()}';
    void open() => openSource(context, n['source_url'] as String);
    if (featured) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: open,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Artwork(
                      n['image_url'] as String?,
                      icon: Icons.newspaper_rounded,
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: Tag(
                        newsCategory(context, n['category']).toUpperCase(),
                        color: lime,
                        solid: true,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      n['headline'] as String,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                        height: 1.16,
                      ),
                    ),
                    if ((n['summary'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        n['summary'] as String,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          context.l10n.readOriginal,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.north_east_rounded,
                          size: 16,
                          color: scheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, top: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: open,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 105,
                height: 112,
                child: Artwork(
                  n['image_url'] as String?,
                  icon: Icons.newspaper_rounded,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    newsCategory(context, n['category']).toUpperCase(),
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 9,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n['headline'] as String,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    metadata,
                    maxLines: 2,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 9,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
