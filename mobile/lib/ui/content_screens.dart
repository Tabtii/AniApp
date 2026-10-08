import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/content.dart';
import 'common.dart';

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
  @override
  void initState() {
    super.initState();
    _settings = _key;
    future = widget.store.releases();
    widget.store.addListener(_changed);
  }

  String get _key =>
      '${widget.store.region}|${widget.store.language}|${widget.store.languageMode}';
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

  void reload() => setState(() => future = widget.store.releases());
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Nächste Folgen · ${widget.store.region}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Aktualisieren',
              onPressed: reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      SwitchListTile(
        title: const Text('Nur meine Watchlist'),
        value: onlyMine,
        onChanged: (value) => setState(() => onlyMine = value),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Zeiten in deiner Gerätezeitzone. Japanische Ausstrahlung, Streaming und Dub haben eigene Termine.',
          style: Theme.of(context).textTheme.bodySmall,
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
            final items = (snapshot.data ?? [])
                .where(
                  (e) =>
                      !onlyMine ||
                      (e.animeId != null && widget.store.isSaved(e.animeId!)),
                )
                .toList();
            if (items.isEmpty) {
              return const EmptyPanel(
                'Noch keine passenden Release-Termine hinterlegt. Neue Folgen erscheinen hier, sobald ihre Termine erfasst sind.',
                icon: Icons.event_outlined,
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: items
                  .map(
                    (e) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${e.episode == null ? 'Start' : 'Folge ${e.episode}'} · ${dateLabel(e.startsAt)}',
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                Chip(
                                  label: Text(switch (e.kind) {
                                    'dub' =>
                                      'Synchronfassung · ${languageLabel(e.language ?? '?')}',
                                    'streaming' => 'Streaming',
                                    _ => 'Japanische Ausstrahlung',
                                  }),
                                ),
                                Chip(
                                  label: Text(switch (e.status) {
                                    'confirmed' => 'Bestätigt',
                                    'estimated' => 'Voraussichtlich',
                                    'delayed' => 'Verschoben',
                                    _ => 'Angekündigt',
                                  }),
                                ),
                              ],
                            ),
                            Text('${e.provider} · ${e.region}'),
                            TextButton.icon(
                              onPressed: () => openSource(context, e.source),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Quelle'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    ],
  );
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = widget.store.news();
  }

  void reload() => setState(() => future = widget.store.news());
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'News & Ankündigungen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Aktualisieren',
              onPressed: reload,
              icon: const Icon(Icons.refresh),
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
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return const EmptyPanel(
                'Hier erscheinen neue Staffeln, Streaming-Starts und Dub-Ankündigungen mit Originalquelle.',
                icon: Icons.newspaper_outlined,
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: rows
                  .map(
                    (n) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n['category'] as String? ?? 'Ankündigung',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              n['headline'] as String,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Text(n['summary'] as String? ?? ''),
                            const SizedBox(height: 8),
                            Text(
                              '${n['source_name']} · ${dateLabel(DateTime.tryParse(n['published_at'] as String? ?? '')?.toLocal())}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            TextButton.icon(
                              onPressed: () => openSource(
                                context,
                                n['source_url'] as String,
                              ),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Original lesen'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    ],
  );
}
