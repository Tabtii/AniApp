import 'package:flutter/material.dart';
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
  String get _key =>
      '${widget.store.region}|${widget.store.language}|${widget.store.languageMode}';
  @override
  void initState() {
    super.initState();
    _settings = _key;
    future = widget.store.releases();
    widget.store.addListener(_changed);
  }

  void _changed() {
    if (mounted) {
      setState(() {
        if (_settings != _key) {
          _settings = _key;
          future = widget.store.releases();
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
    final next = widget.store.releases();
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
    if (date == null) return 'Termin noch offen';
    const days = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ];
    const months = [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    return '${days[date.weekday - 1]}, ${date.day}. ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SectionHeading(
        'Deine nächste Folge.',
        eyebrow: 'Release-Kalender · ${widget.store.region}',
        trailing: IconButton(
          tooltip: 'Aktualisieren',
          onPressed: reload,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            FilterChip(
              label: const Text('Meine Watchlist'),
              selected: onlyMine,
              onSelected: (v) => setState(() => onlyMine = v),
              avatar: const Icon(Icons.bookmark_outline_rounded, size: 16),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Zu den Zeiten',
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (context) => const Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Text(
                    'Alle Zeiten werden in deiner Gerätezeitzone angezeigt. Japanische Ausstrahlung, Streaming und Synchronfassungen haben eigene Termine. „Voraussichtlich“ folgt dem regulären Sendeplan; Sonderpausen und Verschiebungen sind möglich.',
                  ),
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
                'Release-Termine konnten nicht geladen werden.',
                action: OutlinedButton(
                  onPressed: reload,
                  child: const Text('Erneut versuchen'),
                ),
              );
            }
            final all = (snapshot.data ?? [])
                .where(
                  (e) =>
                      !onlyMine ||
                      (e.animeId != null && widget.store.isSaved(e.animeId!)),
                )
                .toList();
            final dates = <String, DateTime?>{
              for (final e in all) dayKey(e.startsAt): e.startsAt,
            };
            final items = all
                .where(
                  (e) =>
                      selectedDay == null || dayKey(e.startsAt) == selectedDay,
                )
                .toList();
            return RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('Alle Tage'),
                            selected: selectedDay == null,
                            onSelected: (_) =>
                                setState(() => selectedDay = null),
                          ),
                        ),
                        ...dates.entries
                            .take(8)
                            .map(
                              (d) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    d.value == null
                                        ? 'Offen'
                                        : '${d.value!.day}.${d.value!.month}.',
                                  ),
                                  selected: selectedDay == d.key,
                                  onSelected: (_) =>
                                      setState(() => selectedDay = d.key),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 70),
                      child: EmptyPanel(
                        'Hier ist noch nichts geplant. Wähle einen anderen Tag oder zeige alle Anime.',
                        icon: Icons.event_available_rounded,
                      ),
                    ),
                  for (var i = 0; i < items.length; i++) ...[
                    if (i == 0 ||
                        dayKey(items[i - 1].startsAt) !=
                            dayKey(items[i].startsAt))
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Text(
                          dayLabel(items[i].startsAt).toUpperCase(),
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
                    timeLabel(e.startsAt),
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'UHR',
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
                                  ? 'Dub · ${languageLabel(e.language ?? '?')}'
                                  : 'Streaming'}${e.episode == null ? '' : ' · Folge ${e.episode}'}',
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              e.status == 'estimated'
                                  ? 'Voraussichtlich'
                                  : e.status == 'confirmed'
                                  ? 'Bestätigt'
                                  : e.status == 'delayed'
                                  ? 'Verschoben'
                                  : 'Angekündigt',
                              style: TextStyle(
                                fontSize: 10,
                                color: scheme.secondary,
                                fontWeight: FontWeight.w700,
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
                          tooltip: 'Terminquelle öffnen',
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
  @override
  void initState() {
    super.initState();
    future = widget.store.news();
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
        'Neues aus deiner Welt.',
        eyebrow: 'News & Ankündigungen',
        trailing: IconButton(
          tooltip: 'Aktualisieren',
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
              null: 'Alles',
              'season': 'Staffeln',
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
                'News konnten nicht geladen werden.',
                action: OutlinedButton(
                  onPressed: reload,
                  child: const Text('Erneut versuchen'),
                ),
              );
            }
            final rows = (snapshot.data ?? [])
                .where((n) => category == null || n['category'] == category)
                .toList();
            if (rows.isEmpty) {
              return const EmptyPanel(
                'Zu diesem Thema gibt es gerade keine Meldungen.',
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

String newsCategory(dynamic value) => switch (value) {
  'season' => 'Neue Staffeln',
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
        '${n['source_name']} · ${shortDate(date)}${n['language'] == 'en' ? ' · EN' : ''}';
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
                        newsCategory(n['category']).toUpperCase(),
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
                          'Original lesen',
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
                    newsCategory(n['category']).toUpperCase(),
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
