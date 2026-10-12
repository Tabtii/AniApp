import 'dart:convert';
import 'package:xml/xml.dart';
import '../models/anime.dart';

class ListImport {
  const ListImport(this.entries, this.skipped);
  final List<WatchEntry> entries;
  final int skipped;
}

ListImport parseWatchlist(String text) {
  if (utf8.encode(text).length > 2 * 1024 * 1024) {
    throw const FormatException('File too large');
  }
  final result = <int, WatchEntry>{};
  var skipped = 0;
  late List<dynamic> rows;
  final xml = text.trimLeft().startsWith('<');
  if (xml) {
    if (RegExp(r'<!DOCTYPE|<!ENTITY', caseSensitive: false).hasMatch(text)) {
      throw const FormatException('Entities not allowed');
    }
    final doc = XmlDocument.parse(text);
    if (doc.rootElement.name.local != 'myanimelist') {
      throw const FormatException('Not a MAL export');
    }
    rows = doc.findAllElements('anime').toList();
  } else {
    final data = jsonDecode(text);
    rows = data is List ? data : (data as Map)['entries'] as List;
  }
  if (rows.length > 5000) throw const FormatException('Too many entries');
  for (final row in rows) {
    try {
      late WatchEntry entry;
      if (xml) {
        final element = row as XmlElement;
        String field(String name) =>
            element.getElement(name)?.innerText.trim() ?? '';
        final total = int.tryParse(field('series_episodes'));
        final status = switch (field('my_status').toLowerCase()) {
          '1' || 'watching' => WatchStatus.watching,
          '2' || 'completed' => WatchStatus.completed,
          '3' || 'on-hold' || 'on hold' => WatchStatus.paused,
          '4' || 'dropped' => WatchStatus.dropped,
          '6' || 'plan to watch' || 'plan-to-watch' => WatchStatus.planned,
          _ => throw const FormatException('Unknown status'),
        };
        entry = WatchEntry(
          anime: Anime(
            id: int.parse(field('series_animedb_id')),
            title: field('series_title'),
            episodes: total == 0 ? null : total,
          ),
          status: status,
          watched: int.parse(field('my_watched_episodes')),
        );
      } else {
        final map = Map<String, dynamic>.from(row as Map);
        if (!WatchStatus.values.any((s) => s.name == map['status'])) {
          throw const FormatException('Unknown status');
        }
        entry = WatchEntry.fromJson(map);
      }
      if (entry.anime.id <= 0 ||
          entry.anime.title.trim().isEmpty ||
          entry.anime.title.length > 500 ||
          entry.watched < 0 ||
          entry.watched > 1000000 ||
          (entry.anime.episodes != null &&
              (entry.anime.episodes! < 0 ||
                  entry.watched > entry.anime.episodes!))) {
        throw const FormatException('Invalid entry');
      }
      if (result.containsKey(entry.anime.id)) {
        skipped++;
        continue;
      }
      result[entry.anime.id] = entry;
    } catch (_) {
      skipped++;
    }
  }
  if (result.isEmpty && rows.isNotEmpty) {
    throw const FormatException('No valid entries');
  }
  return ListImport(result.values.toList(), skipped);
}

String exportWatchlist(List<WatchEntry> entries) =>
    const JsonEncoder.withIndent('  ').convert({
      'format': 'aniapp-watchlist-v1',
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
    });
