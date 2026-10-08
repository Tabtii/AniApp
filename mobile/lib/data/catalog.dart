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
  Catalog({
    http.Client? client,
    this.backend,
    this.requestTimeout = const Duration(seconds: 12),
    this.backendTimeout = const Duration(seconds: 4),
  }) : _client = client ?? http.Client();
  final http.Client _client;
  final SupabaseClient? backend;
  final Duration requestTimeout, backendTimeout;
  final Map<String, (DateTime, Map<String, dynamic>)> _cache = {};
  final Map<String, Future<Map<String, dynamic>>> _inFlight = {};
  DateTime _backendRetryAfter = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void> _queue = Future.value();
  DateTime _lastRequest = DateTime.fromMillisecondsSinceEpoch(0);

  // Serialise Jikan requests: at most one request per second per client.
  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
    DateTime deadline,
  ) async {
    final uri = Uri.https('api.jikan.moe', '/v4/$path', query);
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
      final budget = deadline.difference(DateTime.now());
      if (budget <= Duration.zero) throw TimeoutException('Catalog deadline');
      _lastRequest = DateTime.now();
      final response = await _client.get(uri).timeout(budget);
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
  ) {
    final key = Uri.https('api.jikan.moe', '/v4/$path', query).toString();
    final cached = _cache[key];
    if (cached != null &&
        DateTime.now().difference(cached.$1) < const Duration(minutes: 15)) {
      return Future.value(cached.$2);
    }
    final pending = _inFlight[key];
    if (pending != null) return pending;
    final deadline = DateTime.now().add(requestTimeout);
    final operation = _fetch(path, query, deadline)
        .timeout(
          requestTimeout,
          onTimeout: () {
            throw const CatalogException(
              'Die Anime-Quelle antwortet gerade nicht. Bitte versuche es später erneut.',
            );
          },
        )
        .then((value) {
          if (path.endsWith('/full')
              ? value['data'] is! Map
              : value['data'] is! List) {
            throw const CatalogException(
              'Die Anime-Quelle liefert gerade ungültige Daten.',
            );
          }
          _cache[key] = (DateTime.now(), value);
          return value;
        })
        .whenComplete(() {
          _inFlight.remove(key);
        });
    _inFlight[key] = operation;
    return operation;
  }

  Future<Map<String, dynamic>> _fetch(
    String path,
    Map<String, String> query,
    DateTime deadline,
  ) async {
    // The server keeps provider credentials private and can use MAL + Jikan.
    if (backend != null && DateTime.now().isAfter(_backendRetryAfter)) {
      try {
        final result = await backend!.functions
            .invoke('catalog', body: {'path': path, 'query': query})
            .timeout(backendTimeout);
        if (result.status == 200 && result.data is Map) {
          return Map<String, dynamic>.from(result.data as Map);
        }
      } catch (_) {
        /* The read-only public catalog still works if the backend is unavailable. */
      }
      // Avoid repeating a slow, failed gateway attempt for every subsequent page.
      _backendRetryAfter = DateTime.now().add(const Duration(minutes: 1));
    }
    return _get(path, query, deadline);
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
