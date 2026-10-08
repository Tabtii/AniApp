import 'package:flutter/material.dart';
import 'common.dart';
import 'visuals.dart';

class KitsuPanel extends StatelessWidget {
  const KitsuPanel({super.key, required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    if (data['status'] != 'ok') return const SizedBox.shrink();
    final status = const {
      'current': 'Laufend',
      'finished': 'Abgeschlossen',
      'upcoming': 'Angekündigt',
      'tba': 'Termin offen',
      'unreleased': 'Noch nicht erschienen',
    }[data['airing_status']];
    final start = DateTime.tryParse(data['start_date'] as String? ?? '');
    final end = DateTime.tryParse(data['end_date'] as String? ?? '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mehr zur Serie',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status != null) Tag(status),
                if (data['episodes'] != null) Tag('${data['episodes']} Folgen'),
                if (data['episode_minutes'] != null)
                  Tag('${data['episode_minutes']} Min. / Folge'),
              ],
            ),
            if (start != null) ...[
              const SizedBox(height: 12),
              Text(
                'Originalausstrahlung: ${shortDate(start)}${end == null ? '' : ' – ${shortDate(end)}'}',
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Angaben beziehen sich auf diesen Anime-Eintrag; deutsche Veröffentlichungen können davon abweichen.',
              style: TextStyle(fontSize: 12),
            ),
            if (data['checked_at'] is String)
              Text(
                'Abgerufen: ${shortDate(DateTime.tryParse(data['checked_at'] as String))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () =>
                      openSource(context, data['source'] as String),
                  child: const Text('Quelle: Kitsu'),
                ),
                if (data['trailer_url'] is String)
                  TextButton.icon(
                    onPressed: () =>
                        openSource(context, data['trailer_url'] as String),
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: const Text('Trailer auf YouTube'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
