import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/content.dart';
import 'common.dart';
import 'visuals.dart';

String dubDateLabel(ReleaseEvent event, [BuildContext? context]) {
  final strings = stringsFor(context);
  if (event.startsAt != null) {
    return strings.deviceTime(dateLabel(event.startsAt, context));
  }
  if (event.startsOn != null) {
    return strings.timeUnknown(shortDate(event.startsOn, context));
  }
  return strings.startTba;
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
    this.observation = const {},
  });
  final String language, region;
  final List<ReleaseEvent> events;
  final List<Availability> availability;
  final bool loading;
  final String? error;
  final Map<String, dynamic> observation;
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
                        ? context.l10n.germanDub
                        : context.l10n.dubHeading(
                            languageLabel(language, context),
                          ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Tag(region, color: scheme.secondary),
              ],
            ),
            const SizedBox(height: 14),
            if (loading)
              const LinearProgressIndicator()
            else ...[
              if (['available', 'partial'].contains(observation['status'])) ...[
                Text(
                  observation['status'] == 'partial'
                      ? context.l10n.partialDub
                      : context.l10n.dubExists,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.dubEvidenceHint,
                  style: const TextStyle(fontSize: 12),
                ),
                if (observation['checked_at'] is String)
                  Text(
                    context.l10n.fetchedOn(
                      shortDate(
                        DateTime.tryParse(observation['checked_at'] as String),
                        context,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                TextButton(
                  onPressed: () => openSource(context, 'https://mydublist.com'),
                  child: Text(context.l10n.mydubSource),
                ),
                if (events.isNotEmpty || available.isNotEmpty)
                  const Divider(height: 24),
              ],
              if (observation['status'] == 'original_language')
                Text(context.l10n.japaneseOriginalHint),
              if (error != null) ...[
                Text(error!),
                TextButton(
                  onPressed: onRetry,
                  child: Text(context.l10n.reload),
                ),
              ],
              if (observation['status'] == 'unavailable')
                Text(context.l10n.mydubUnavailable),
              if (available.isNotEmpty) ...[
                Text(
                  context.l10n.reportedAvailable,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(available.map((a) => a.provider).toSet().join(' · ')),
                Text(
                  context.l10n.languageVaries,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
              if (events.isEmpty &&
                  available.isEmpty &&
                  error == null &&
                  ![
                    'available',
                    'partial',
                    'original_language',
                    'unavailable',
                  ].contains(observation['status']))
                Text(context.l10n.noDubEvidence),
              for (final e in events) ...[
                if (available.isNotEmpty || e != events.first)
                  const Divider(height: 28),
                Text(
                  e.status == 'delayed'
                      ? context.l10n.delayed
                      : e.date == null
                      ? context.l10n.announced
                      : context.l10n.announcedStart,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dubDateLabel(e, context),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${e.provider}${e.episode == null ? '' : ' · ${context.l10n.episodeNumber('${e.episode}')}'}',
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
                  Text(
                    context.l10n.pastAnnouncement,
                    style: const TextStyle(fontSize: 12),
                  ),
                if (e.checkedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.checkedOn(shortDate(e.checkedAt, context)),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                TextButton.icon(
                  onPressed: () => openSource(context, e.source),
                  icon: const Icon(Icons.north_east_rounded, size: 16),
                  label: Text(context.l10n.viewAnnouncement),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
