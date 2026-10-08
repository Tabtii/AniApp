import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/anime.dart';

class CatalogException implements Exception {
  const CatalogException(this.message);
  final String message;
  @override
  String toString() => message;
}

class Catalog {
  Catalog({http.Client? client, this.backend})
    : _client = client ?? http.Client();
  final http.Client _client;
  final SupabaseClient? backend;
  final Map<String, (DateTime, Map<String, dynamic>)> _cache = {};
  Future<void> _queue = Future.value();
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  // Serialise Jikan requests: at most one request per second per client.
  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) async {
    final uri = Uri.https('api.jikan.moe', '/v4/$path', query);
    final cached = _cache[uri.toString()];
    if (cached != null &&
        DateTime.now().difference(cached.$1) < const Duration(minutes: 15)) {
      return cached.$2;
    }
    final waitFor = _queue;
    final completion = Completer<void>();
    _queue = completion.future;
    await waitFor;
    try {
      final remaining =
          1000 - DateTime.now().difference(_lastRequest).inMilliseconds;
      if (remaining > 0) {
        await Future<void>.delayed(Duration(milliseconds: remaining));
      }
      _lastRequest = DateTime.now();
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 429) {
        throw const CatalogException(
          'Zu viele Anfragen. Bitte warte kurz und versuche es erneut.',
        );
      }
      if (response.statusCode != 200) {
        throw const CatalogException(
          'Anime-Daten sind gerade nicht erreichbar.',
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _cache[uri.toString()] = (DateTime.now(), json);
      return json;
    } on TimeoutException {
      throw const CatalogException(
        'Die Anfrage dauert zu lange. Bitte versuche es erneut.',
      );
    } on http.ClientException {
      throw const CatalogException(
        'Keine Verbindung. Bitte prüfe dein Internet.',
      );
    } finally {
      completion.complete();
    }
  }

  Future<Map<String, dynamic>> _request(
    String path,
    Map<String, String> query,
  ) async {
    // The server keeps provider credentials private and can use MAL + Jikan.
    if (backend != null) {
      try {
        final result = await backend!.functions
            .invoke('catalog', body: {'path': path, 'query': query})
            .timeout(const Duration(seconds: 20));
        if (result.status == 200 && result.data is Map) {
          return Map<String, dynamic>.from(result.data as Map);
        }
      } catch (_) {
        /* The read-only public catalog still works if the backend is unavailable. */
      }
    }
    return _get(path, query);
  }

  Future<AnimePage> season(int year, String season, int page) async => _page(
    await _request('seasons/$year/$season', {'page': '$page', 'sfw': 'true'}),
  );
  Future<AnimePage> search(String query, int page, {String? genre}) async =>
      _page(
        await _request('anime', {
          'q': query.trim(),
          'page': '$page',
          'sfw': 'true',
          'order_by': 'score',
          'sort': 'desc',
          if (genre != null) 'genres': genre,
        }),
      );
  AnimePage _page(Map<String, dynamic> json) => AnimePage(
    (json['data'] as List)
        .map((e) => Anime.fromJikan(Map<String, dynamic>.from(e as Map)))
        .toList(),
    (json['pagination'] as Map?)?['has_next_page'] == true,
  );
  Future<Anime> detail(int id) async => Anime.fromJikan(
    Map<String, dynamic>.from(
      (await _request('anime/$id/full', {}))['data'] as Map,
    ),
  );
  void dispose() => _client.close();
}
