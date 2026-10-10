import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import 'common.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.sources)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          context.l10n.dubsCreditHeading,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(context.l10n.dubCredit),
        TextButton(
          onPressed: () => openSource(context, 'https://mydublist.com'),
          child: const Text('Powered by MyDubList'),
        ),
        TextButton(
          onPressed: () => openSource(
            context,
            'https://creativecommons.org/licenses/by/4.0/',
          ),
          child: Text(context.l10n.license),
        ),
        TextButton(
          onPressed: () => openSource(
            context,
            'https://github.com/Joelis57/MyDubList/issues/new/choose',
          ),
          child: Text(context.l10n.reportDub),
        ),
        const Divider(height: 32),
        Text(
          context.l10n.kitsuInfo,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(context.l10n.kitsuAttribution),
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
          context.l10n.providerDescriptions,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'This product uses the TMDB API but is not endorsed or certified by TMDB.',
        ),
        const SizedBox(height: 8),
        Text(context.l10n.justwatchCredit),
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
          child: Text(context.l10n.idMapping),
        ),
        const Divider(height: 32),
        Text(
          context.l10n.catalogCalendarNews,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(context.l10n.catalogAttribution),
        TextButton(
          onPressed: () => openSource(context, 'https://anilist.co'),
          child: const Text('AniList'),
        ),
        TextButton(
          onPressed: () =>
              openSource(context, 'https://api.tenrai.org/documentation'),
          child: const Text('Tenrai / MyAnimeList'),
        ),
        Text(context.l10n.newsAttribution),
      ],
    ),
  );
}
