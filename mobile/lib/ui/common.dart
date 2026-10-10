import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../models/anime.dart';
import 'visuals.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> perform(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.actionFailed)));
    }
  }
}

Future<void> openSource(BuildContext context, String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.linkFailed)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.linkFailed)));
    }
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel(
    this.text, {
    super.key,
    this.icon = Icons.auto_awesome_outlined,
    this.action,
  });
  final String text;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}

String languageLabel(String code, [BuildContext? context]) {
  final strings = stringsFor(context);
  return switch (code) {
    'de' => strings.languageDe,
    'en' => strings.languageEn,
    'ja' => strings.languageJa,
    _ => code.toUpperCase(),
  };
}

String watchStatusLabel(BuildContext context, WatchStatus value) =>
    switch (value) {
      WatchStatus.planned => context.l10n.planned,
      WatchStatus.watching => context.l10n.watching,
      WatchStatus.completed => context.l10n.completed,
      WatchStatus.paused => context.l10n.paused,
      WatchStatus.dropped => context.l10n.dropped,
    };

String catalogErrorText(BuildContext context, String error) => switch (error) {
  "Zu viele Anfragen. Bitte warte kurz und versuche es erneut." =>
    context.l10n.catalogRateLimit,
  "Anime-Daten sind gerade nicht erreichbar." =>
    context.l10n.catalogUnavailable,
  "Die Anfrage dauert zu lange. Bitte versuche es erneut." =>
    context.l10n.catalogTimeout,
  "Keine Verbindung. Bitte prüfe dein Internet." => context.l10n.catalogOffline,
  "Die Anime-Quelle antwortet gerade nicht. Bitte versuche es später erneut." =>
    context.l10n.catalogNoResponse,
  "Die Anime-Quelle liefert gerade ungültige Daten." =>
    context.l10n.catalogInvalid,
  _ => context.l10n.catalogUnavailable,
};
String watchErrorText(BuildContext context, String error) =>
    error == 'Die lokale Watchlist konnte nicht gelesen werden.'
    ? context.l10n.localListError
    : context.l10n.syncError;
String dateLabel(DateTime? date, [BuildContext? context]) => date == null
    ? stringsFor(context).dateTba
    : '${shortDate(date, context)} · ${timeLabel(date)}';
