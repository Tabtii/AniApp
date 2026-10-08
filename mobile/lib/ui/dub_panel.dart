import 'package:flutter/material.dart';
import '../models/content.dart';
import 'common.dart';
import 'visuals.dart';

String dubDateLabel(ReleaseEvent event) {
  if (event.startsAt != null) {
    return '${dateLabel(event.startsAt)} · Gerätezeit';
  }
  if (event.startsOn != null) {
    return '${shortDate(event.startsOn)} · Uhrzeit offen';
  }
  return 'Starttermin noch offen';
}

class DubPanel extends StatelessWidget {
  const DubPanel({
    super.key,
    required this.language,
    required this.region,
    required this.events,
    required this.availability,
    required this.loading,
    required this.onRetry,
    this.error,
  });
  final String language, region;
  final List<ReleaseEvent> events;
  final List<Availability> availability;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final available = availability
        .where(
          (a) =>
              a.status == 'available' && (a.audio?.contains(language) ?? false),
        )
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.record_voice_over_rounded,
                  color: scheme.secondary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    language == 'de'
                        ? 'Deutsche Synchro'
                        : 'Synchro · ${languageLabel(language)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Tag(region, color: scheme.secondary),
              ],
            ),
            const SizedBox(height: 14),
            if (loading)
              const LinearProgressIndicator()
            else if (error != null) ...[
              Text(error!),
              TextButton(onPressed: onRetry, child: const Text('Erneut laden')),
            ] else ...[
              if (available.isNotEmpty) ...[
                Text(
                  'Als verfügbar gemeldet',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(available.map((a) => a.provider).toSet().join(' · ')),
                const Text(
                  'Die Sprachangabe kann je Staffel und Folge abweichen.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
              if (events.isEmpty && available.isEmpty)
                const Text(
                  'Noch keine belegte Dub-Ankündigung für diesen Titel und diese Region hinterlegt.',
                ),
              for (final e in events) ...[
                if (available.isNotEmpty || e != events.first)
                  const Divider(height: 28),
                Text(
                  e.status == 'delayed'
                      ? 'Verschoben'
                      : e.date == null
                      ? 'Angekündigt'
                      : 'Angekündigter Start',
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dubDateLabel(e),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${e.provider}${e.episode == null ? '' : ' · Folge ${e.episode}'}',
                ),
                if (e.note != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    e.note!,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (e.startsAt?.isBefore(DateTime.now()) ??
                    (e.startsOn?.isBefore(DateUtils.dateOnly(DateTime.now())) ??
                        false))
                  const Text(
                    'Der angekündigte Termin liegt in der Vergangenheit. Aktuelle Verfügbarkeit beim Anbieter prüfen.',
                    style: TextStyle(fontSize: 12),
                  ),
                if (e.checkedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Geprüft am ${shortDate(e.checkedAt)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                TextButton.icon(
                  onPressed: () => openSource(context, e.source),
                  icon: const Icon(Icons.north_east_rounded, size: 16),
                  label: const Text('Ankündigung ansehen'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
