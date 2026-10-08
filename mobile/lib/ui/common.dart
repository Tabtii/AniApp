import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> perform(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Die Aktion konnte nicht gespeichert werden. Bitte versuche es erneut.',
          ),
        ),
      );
    }
  }
}

Future<void> openSource(BuildContext context, String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Der Link konnte nicht geöffnet werden.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Der Link konnte nicht geöffnet werden.')),
      );
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

String languageLabel(String code) =>
    const {
      'de': 'Deutsch',
      'en': 'Englisch',
      'ja': 'Japanisch',
      'fr': 'Französisch',
      'es': 'Spanisch',
      'it': 'Italienisch',
      'pl': 'Polnisch',
      'pt': 'Portugiesisch',
      'ko': 'Koreanisch',
      'ru': 'Russisch',
      'hi': 'Hindi',
      'ta': 'Tamil',
      'te': 'Telugu',
      'id': 'Indonesisch',
      'ms': 'Malaiisch',
      'vi': 'Vietnamesisch',
      'ar': 'Arabisch',
      'zh': 'Chinesisch',
      'th': 'Thailändisch',
    }[code] ??
    code;
String dateLabel(DateTime? date) => date == null
    ? 'Termin noch offen'
    : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
