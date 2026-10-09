import 'package:flutter/material.dart';
import 'common.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Datenquellen & Hinweise')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Synchros', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'Dub data © MyDubList – CC BY 4.0. AniApp verwendet Einträge mit mehreren Quellen oder manueller Bestätigung, gefiltert nach Titel und gewählter Sprache. Die Anzeige wurde übersetzt. Fehlende Einträge bedeuten „unbekannt“. Ein Dub-Nachweis ist keine Zusage für einen Anbieter oder Folgentermin.',
        ),
        TextButton(
          onPressed: () => openSource(context, 'https://mydublist.com'),
          child: const Text('Powered by MyDubList'),
        ),
        TextButton(
          onPressed: () => openSource(
            context,
            'https://creativecommons.org/licenses/by/4.0/',
          ),
          child: const Text('Lizenz: CC BY 4.0'),
        ),
        TextButton(
          onPressed: () => openSource(
            context,
            'https://github.com/Joelis57/MyDubList/issues/new/choose',
          ),
          child: const Text('Fehlerhafte Dub-Angabe melden'),
        ),
        const Divider(height: 32),
        Text(
          'Zusätzliche Anime-Infos: Kitsu',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Bilder, Laufzeit, Episodenzahl, Originalausstrahlung und Trailer stammen bei Kennzeichnung von Kitsu. Titel werden über die dort hinterlegte MyAnimeList-ID zugeordnet. Angaben sind keine deutschen Streaming- oder Dub-Termine.',
        ),
        TextButton(
          onPressed: () => openSource(context, 'https://kitsu.app'),
          child: const Text('Kitsu'),
        ),
        const Divider(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: Image.asset('assets/tmdb-logo.png', width: 100),
        ),
        const SizedBox(height: 16),
        Text(
          'Anbieter & deutsche Beschreibungen',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'This product uses the TMDB API but is not endorsed or certified by TMDB.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Streamingangebote stammen von JustWatch über TMDb. Angaben beziehen sich auf die angezeigte Region und den Film, die Serie oder die zugeordnete Staffel. Sprachen und kommende Episodentermine werden daraus nicht abgeleitet. Die Verfügbarkeit kann sich ändern.',
        ),
        TextButton(
          onPressed: () => openSource(context, 'https://www.themoviedb.org'),
          child: const Text('The Movie Database'),
        ),
        TextButton(
          onPressed: () => openSource(context, 'https://www.justwatch.com'),
          child: const Text('JustWatch'),
        ),
        TextButton(
          onPressed: () =>
              openSource(context, 'https://github.com/Fribb/anime-lists'),
          child: const Text('ID-Zuordnung: Fribb / anime-lists'),
        ),
        const Divider(height: 32),
        Text(
          'Katalog, Kalender & News',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Anime-Katalog: MyAnimeList über Tenrai oder die offizielle API. Episodentermine können zusätzlich von AniList stammen, sofern für AniApp freigeschaltet; die jeweilige Quelle steht am Termin. Japanische Ausstrahlung und deutscher Streaming- oder Dub-Release sind getrennte Angaben.',
        ),
        TextButton(
          onPressed: () => openSource(context, 'https://anilist.co'),
          child: const Text('AniList'),
        ),
        TextButton(
          onPressed: () =>
              openSource(context, 'https://api.tenrai.org/documentation'),
          child: const Text('Tenrai / MyAnimeList'),
        ),
        const Text(
          'Anbietertermine: unter anderem ADN und geprüfte Ankündigungen. News: Anime2You, AniNews, MyAnimeList und ADN News. Der eigene ADN-Scraper übernimmt öffentliche Artikel-Metadaten und kurze Vorschauen. Originalquellen und Abrufdatum stehen an den jeweiligen Inhalten. Bilder bleiben Eigentum ihrer Rechteinhaber.',
        ),
      ],
    ),
  );
}
