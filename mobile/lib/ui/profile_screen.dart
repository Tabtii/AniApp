import 'package:flutter/material.dart';
import '../l10n/strings.dart';

import '../data/app_store.dart';
import 'common.dart';
import 'login_dialog.dart';
import 'visuals.dart';
import 'sources_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.store.removeListener(_changed);
    super.dispose();
  }

  Future<void> _login() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => LoginDialog(backend: widget.store.backend!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          context.l10n.yourProfile,
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 10,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.profileHeading,
          style: const TextStyle(
            fontSize: 27,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: -.6,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [coral, lavender]),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF171D2A),
                    size: 29,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  store.signedIn
                      ? store.email ?? context.l10n.signedIn
                      : context.l10n.guest,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  store.signedIn
                      ? context.l10n.watchlistCloud
                      : context.l10n.watchlistLocal,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.listCount('${store.entries.length}'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (store.backend != null && !store.signedIn)
                  FilledButton(
                    onPressed: _login,
                    child: Text(context.l10n.loginRegister),
                  ),
                if (store.signedIn) ...[
                  TextButton(
                    onPressed: store.busy
                        ? null
                        : () => perform(context, store.importGuestList),
                    child: Text(context.l10n.importGuest),
                  ),
                  TextButton(
                    onPressed: () =>
                        perform(context, () => store.backend!.auth.signOut()),
                    child: Text(context.l10n.signOut),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.region,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        DropdownButton<String>(
          isExpanded: true,
          value: store.region,
          items: [
            DropdownMenuItem(value: 'DE', child: Text(context.l10n.germany)),
            DropdownMenuItem(value: 'AT', child: Text(context.l10n.austria)),
            DropdownMenuItem(
              value: 'CH',
              child: Text(context.l10n.switzerland),
            ),
            const DropdownMenuItem(value: 'US', child: Text('USA')),
            DropdownMenuItem(
              value: 'GB',
              child: Text(context.l10n.unitedKingdom),
            ),
          ],
          onChanged: (r) => perform(context, () => store.setRegion(r!)),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.appLanguage,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        DropdownButton<String>(
          key: const ValueKey('app-language'),
          isExpanded: true,
          value: store.appLanguage,
          items: [
            DropdownMenuItem(
              value: 'system',
              child: Text(context.l10n.systemLanguage),
            ),
            const DropdownMenuItem(value: 'de', child: Text('Deutsch')),
            const DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (value) =>
              perform(context, () => store.setAppLanguage(value!)),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.newsLanguage,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        DropdownButton<String>(
          key: const ValueKey('news-language'),
          isExpanded: true,
          value: store.newsLanguage,
          items: [
            DropdownMenuItem(value: 'app', child: Text(context.l10n.followApp)),
            const DropdownMenuItem(value: 'de', child: Text('Deutsch')),
            const DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(
              value: 'both',
              child: Text(context.l10n.bothLanguages),
            ),
          ],
          onChanged: (value) =>
              perform(context, () => store.setNewsLanguage(value!)),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.dubLanguages,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final code in AppStore.supportedLanguages)
              FilterChip(
                key: ValueKey('dub-$code'),
                label: Text(languageLabel(code, context)),
                selected: store.dubLanguages.contains(code),
                onSelected: (selected) => perform(
                  context,
                  () => store.setDubLanguages([
                    ...store.dubLanguages.where((l) => l != code),
                    if (selected) code,
                  ]),
                ),
              ),
          ],
        ),
        Text(context.l10n.dubSelectionHint),
        const SizedBox(height: 16),
        Text(
          context.l10n.calendarDisplay,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        DropdownButton<String>(
          key: const ValueKey('calendar-mode'),
          isExpanded: true,
          value: store.languageMode,
          items: [
            DropdownMenuItem(
              value: 'any',
              child: Text(
                context.l10n.calendarAll,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'dub',
              child: Text(
                context.l10n.calendarDubs,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          onChanged: (value) =>
              perform(context, () => store.setCalendarMode(value!)),
        ),
        const SizedBox(height: 24),
        Text(context.l10n.availabilityHint),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline_rounded),
          title: Text(context.l10n.sources),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SourcesScreen()),
          ),
        ),
      ],
    );
  }
}
