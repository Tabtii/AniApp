import 'package:flutter/material.dart';

import '../data/app_store.dart';
import 'common.dart';

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
    final email = TextEditingController(), password = TextEditingController();
    bool busy = false;
    String? message;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Deine Watchlist überall'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'E-Mail'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Passwort'),
                ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(message!),
                  ),
                if (busy) const LinearProgressIndicator(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (password.text.length < 8 ||
                          !email.text.contains('@')) {
                        setDialogState(
                          () => message =
                              'Bitte nutze eine gültige E-Mail und mindestens 8 Zeichen im Passwort.',
                        );
                        return;
                      }
                      setDialogState(() {
                        busy = true;
                        message = null;
                      });
                      try {
                        await widget.store.backend!.auth.signUp(
                          email: email.text.trim(),
                          password: password.text,
                        );
                        if (context.mounted) {
                          setDialogState(
                            () => message =
                                'Bitte bestätige deine E-Mail. Danach kannst du dich anmelden.',
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          setDialogState(
                            () => message =
                                'Registrierung nicht möglich. Bitte prüfe deine Angaben oder versuche es später.',
                          );
                        }
                      } finally {
                        if (context.mounted) setDialogState(() => busy = false);
                      }
                    },
              child: const Text('Registrieren'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setDialogState(() {
                        busy = true;
                        message = null;
                      });
                      try {
                        await widget.store.backend!.auth.signInWithPassword(
                          email: email.text.trim(),
                          password: password.text,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (_) {
                        if (context.mounted) {
                          setDialogState(
                            () => message =
                                'Anmeldung nicht möglich. Prüfe E-Mail, Passwort und E-Mail-Bestätigung.',
                          );
                        }
                      } finally {
                        if (context.mounted) setDialogState(() => busy = false);
                      }
                    },
              child: const Text('Anmelden'),
            ),
          ],
        ),
      ),
    );
    email.dispose();
    password.dispose();
  }

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
