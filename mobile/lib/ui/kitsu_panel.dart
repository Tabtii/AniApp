import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import 'common.dart';
import 'visuals.dart';

class KitsuPanel extends StatelessWidget {
  const KitsuPanel({super.key, required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    if (data['status'] != 'ok') return const SizedBox.shrink();
    final status = {
      'current': context.l10n.airing,
      'finished': context.l10n.completed,
      'upcoming': context.l10n.announced,
      'tba': context.l10n.dateOpen,
      'unreleased': context.l10n.unreleased,
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
              context.l10n.moreAboutSeries,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status != null) Tag(status),
                if (data['episodes'] != null)
                  Tag(context.l10n.episodeCount('${data['episodes']}')),
                if (data['episode_minutes'] != null)
                  Tag(context.l10n.runtime('${data['episode_minutes']}')),
              ],
            ),
            if (start != null) ...[
              const SizedBox(height: 12),
              Text(
                context.l10n.originalDates(
                  '${shortDate(start, context)}${end == null ? '' : ' – ${shortDate(end, context)}'}',
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              context.l10n.kitsuDatesHint,
              style: const TextStyle(fontSize: 12),
            ),
            if (data['checked_at'] is String)
              Text(
                context.l10n.fetchedOn(
                  shortDate(
                    DateTime.tryParse(data['checked_at'] as String),
                    context,
                  ),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () =>
                      openSource(context, data['source'] as String),
                  child: Text(context.l10n.kitsuSource),
                ),
                if (data['trailer_url'] is String)
                  TextButton.icon(
                    onPressed: () =>
                        openSource(context, data['trailer_url'] as String),
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: Text(context.l10n.youtubeTrailer),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
