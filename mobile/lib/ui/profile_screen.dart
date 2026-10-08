import 'package:flutter/material.dart';

import '../data/app_store.dart';
import 'common.dart';
import 'login_dialog.dart';

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

  Future<void> _login() => showDialog<void>(
    context: context,
    builder: (_) => LoginDialog(backend: widget.store.backend!),
  );

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'So schaust du Anime',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.signedIn ? store.email ?? 'Angemeldet' : 'Gastmodus',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  store.signedIn
                      ? 'Deine Watchlist wird mit deinem Konto synchronisiert.'
                      : 'Deine Watchlist bleibt lokal auf diesem Gerät.',
                ),
                if (store.backend != null && !store.signedIn)
                  FilledButton(
                    onPressed: _login,
                    child: const Text('Anmelden oder registrieren'),
                  ),
                if (store.signedIn) ...[
                  TextButton(
                    onPressed: store.busy
                        ? null
                        : () => perform(context, store.importGuestList),
                    child: const Text('Lokale Gast-Watchlist übernehmen'),
                  ),
                  TextButton(
                    onPressed: () =>
                        perform(context, () => store.backend!.auth.signOut()),
                    child: const Text('Abmelden'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Streaming-Region',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        DropdownButton<String>(
          isExpanded: true,
          value: store.region,
          items: const [
            DropdownMenuItem(value: 'DE', child: Text('Deutschland')),
            DropdownMenuItem(value: 'AT', child: Text('Österreich')),
            DropdownMenuItem(value: 'CH', child: Text('Schweiz')),
            DropdownMenuItem(value: 'US', child: Text('USA')),
          ],
          onChanged: (r) => perform(
            context,
            () => store.setPreferences(r!, store.language, store.languageMode),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Bevorzugte Sprache',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        DropdownButton<String>(
          isExpanded: true,
          value: store.language,
          items: ['de', 'en', 'ja', 'fr', 'es', 'it']
              .map(
                (l) =>
                    DropdownMenuItem(value: l, child: Text(languageLabel(l))),
              )
              .toList(),
          onChanged: (l) => perform(
            context,
            () => store.setPreferences(store.region, l!, store.languageMode),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Kalender anzeigen',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        DropdownButton<String>(
          isExpanded: true,
          value: store.languageMode,
          items: const [
            DropdownMenuItem(
              value: 'any',
              child: Text('Alle passenden Veröffentlichungen'),
            ),
            DropdownMenuItem(
              value: 'dub',
              child: Text('Nur Synchronfassung in meiner Sprache'),
            ),
          ],
          onChanged: (m) => perform(
            context,
            () => store.setPreferences(store.region, store.language, m!),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Audio und Untertitel werden getrennt ausgewiesen. Angaben können sich je Anbieter, Region, Staffel und Folge unterscheiden.',
        ),
      ],
    );
  }
}
