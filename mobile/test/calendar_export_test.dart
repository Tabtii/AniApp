import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:aniapp/data/calendar_export.dart';
import 'package:aniapp/models/content.dart';

void main() {
  test(
    'ICS exports confirmed dates only and preserves all-day meaning and UTF-8 folding',
    () {
      final date = DateTime(2026, 10, 12);
      Map<String, dynamic> row(String id, String status) => {
        'id': id,
        'title': 'Überraschung, nächste Staffel; 日本語' * 5,
        'provider': 'Netflix',
        'kind': 'dub',
        'region': 'DE',
        'audio_language': 'de',
        'starts_on': '2026-10-13',
        'status': status,
        'source_url': 'https://example.com/news',
        'revision': 2,
      };
      final output = exportCalendar([
        ReleaseEvent(row('1', 'confirmed')),
        ReleaseEvent(row('2', 'estimated')),
        ReleaseEvent({...row('3', 'announced'), 'starts_on': null}),
      ], now: date);
      expect(RegExp('BEGIN:VEVENT').allMatches(output).length, 1);
      expect(output, contains('DTSTART;VALUE=DATE:20261013'));
      expect(output, contains('DTEND;VALUE=DATE:20261014'));
      expect(output, contains('SEQUENCE:2'));
      expect(output, contains(r'\,'));
      for (final line in output.split('\r\n')) {
        expect(utf8.encode(line).length, lessThanOrEqualTo(75));
      }
    },
  );
}
