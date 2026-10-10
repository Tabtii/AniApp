import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/strings.dart';

const coral = Color(0xFFFF806B);
const lavender = Color(0xFFB9A5FF);
const lime = Color(0xFFD8F69B);

class Artwork extends StatelessWidget {
  const Artwork(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.icon = Icons.auto_awesome,
    this.fallbackUrl,
  });
  final String? url;
  final BoxFit fit;
  final Alignment alignment;
  final IconData icon;
  final String? fallbackUrl;
  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF353354), Color(0xFF171E2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(icon, size: 38, color: lavender.withValues(alpha: .6)),
      ),
    );
    if (url == null || url!.isEmpty) return fallback;
    return Image.network(
      url!,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, error, stack) =>
          fallbackUrl != null && fallbackUrl != url
          ? Artwork(fallbackUrl, fit: fit, alignment: alignment, icon: icon)
          : fallback,
      frameBuilder: (context, child, frame, sync) =>
          frame == null ? fallback : child,
    );
  }
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color, this.solid = false, this.icon});
  final String text;
  final Color? color;
  final bool solid;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: solid ? c : c.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: solid ? const Color(0xFF151924) : c),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: solid ? const Color(0xFF151924) : c,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: .3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.eyebrow, this.trailing});
  final String title;
  final String? eyebrow;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 10,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

String shortDate(DateTime? date, [BuildContext? context]) {
  final strings = stringsFor(context);
  if (date == null) return strings.dateOpen;
  if (strings.localeName == 'de') {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
  return DateFormat('MMM d, yyyy', strings.localeName).format(date);
}

String timeLabel(DateTime? date) => date == null
    ? '—'
    : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
