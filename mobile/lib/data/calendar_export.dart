import 'dart:convert';
import '../models/content.dart';

String exportCalendar(List<ReleaseEvent> events, {DateTime? now}) {
  String escape(String value) => value
      .replaceAll('\\', '\\\\')
      .replaceAll('\r', '')
      .replaceAll('\n', r'\n')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,');
  String day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  String stamp(DateTime d) {
    final u = d.toUtc();
    return '${day(u)}T${u.hour.toString().padLeft(2, '0')}${u.minute.toString().padLeft(2, '0')}${u.second.toString().padLeft(2, '0')}Z';
  }

  final lines = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//AniApp//Release Calendar//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
  ];
  for (final e in events.where(
    (e) =>
        e.status == 'confirmed' &&
        e.date != null &&
        e.isUpcoming(now ?? DateTime.now()),
  )) {
    final id = e.data['id'];
    if (id == null) continue;
    lines.addAll([
      'BEGIN:VEVENT',
      'UID:${escape('$id')}@aniapp',
      'SEQUENCE:${e.data['revision'] ?? 1}',
      'DTSTAMP:${stamp(now ?? DateTime.now())}',
    ]);
    if (e.startsAt != null) {
      lines.add('DTSTART:${stamp(e.startsAt!)}');
    } else {
      lines.addAll([
        'DTSTART;VALUE=DATE:${day(e.startsOn!)}',
        'DTEND;VALUE=DATE:${day(DateTime(e.startsOn!.year, e.startsOn!.month, e.startsOn!.day + 1))}',
      ]);
    }
    lines.addAll([
      'SUMMARY:${escape('${e.title} · ${e.language?.toUpperCase() ?? e.kind}${e.episode == null ? '' : ' · #${e.episode}'}')}',
      'DESCRIPTION:${escape('${e.provider} · ${e.region}\n${e.source}\n${e.note ?? ''}')}',
      'URL:${e.source}',
      'STATUS:CONFIRMED',
      'END:VEVENT',
    ]);
  }
  lines.add('END:VCALENDAR');
  // RFC 5545 folds after at most 75 UTF-8 octets, without splitting a codepoint.
  return '${lines.map((line) {
    final parts = <String>[];
    var current = '', size = 0;
    for (final rune in line.runes) {
      final char = String.fromCharCode(rune), bytes = utf8.encode(char).length;
      if (size + bytes > 75) {
        parts.add(current);
        current = ' ';
        size = 1;
      }
      current += char;
      size += bytes;
    }
    parts.add(current);
    return parts.join('\r\n');
  }).join('\r\n')}\r\n';
}
