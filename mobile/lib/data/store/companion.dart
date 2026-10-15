part of '../app_store.dart';

// Account-bound companion features: inbox, dub follows, reviewer access.
mixin _Companion on _Settings {
  SupabaseClient? get backend;
  bool get signedIn;
  String? get _userId;
  int get _sessionVersion;
  bool get _disposed;

  bool get isReviewer => _isReviewer;
  int unreadCount = 0;
  Future<void> refreshUnreadCount() async {
    final session = _sessionVersion;
    if (!signedIn || backend == null) {
      unreadCount = 0;
      _notify();
      return;
    }
    try {
      final rows = await backend!
          .from('release_inbox')
          .select('id')
          .eq('user_id', _userId!)
          .isFilter('read_at', null)
          .eq('superseded', false)
          .limit(100)
          .timeout(const Duration(seconds: 10));
      if (session == _sessionVersion && !_disposed) {
        unreadCount = rows.length;
        _notify();
      }
    } catch (_) {
      /* An optional badge never blocks local progress. */
    }
  }

  bool _isReviewer = false;
  Future<void> checkReviewer() async {
    _isReviewer = false;
    if (signedIn) {
      final version = _sessionVersion;
      try {
        final response = await backend!.functions.invoke(
          'companion-account',
          body: {'action': 'role'},
        );
        if (version == _sessionVersion) {
          _isReviewer = response.data?['reviewer'] == true;
        }
      } catch (_) {
        /* Optional editorial access never blocks the app. */
      }
    }
    _notify();
  }

  Future<List<Map<String, dynamic>>> inbox() async {
    if (!signedIn || backend == null) return [];
    return await backend!
        .from('release_inbox')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false)
        .limit(60);
  }

  Future<void> markRead(String id) async {
    if (signedIn) {
      await backend!
          .from('release_inbox')
          .update({'read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id)
          .eq('user_id', _userId!);
      await refreshUnreadCount();
    }
  }

  Future<List<Map<String, dynamic>>> follows(int id) async {
    if (!signedIn) return [];
    return await backend!
        .from('dub_follows')
        .select()
        .eq('user_id', _userId!)
        .eq('mal_id', id)
        .eq('region', region);
  }

  Future<void> followDub(int id, bool enabled) async {
    if (!signedIn) {
      throw StateError('Bitte melde dich für Dub-Mitteilungen an.');
    }
    if (enabled) {
      await backend!.from('dub_follows').upsert([
        for (final lang in dubLanguages)
          {
            'user_id': _userId!,
            'mal_id': id,
            'region': region,
            'audio_language': lang,
          },
      ], onConflict: 'user_id,mal_id,region,audio_language');
    } else {
      await backend!
          .from('dub_follows')
          .delete()
          .eq('user_id', _userId!)
          .eq('mal_id', id)
          .eq('region', region);
    }
    _notify();
  }

  Future<List<Map<String, dynamic>>> sourceHealth() async => backend == null
      ? []
      : await backend!.from('source_status').select().order('source_key');
  Future<dynamic> editorial(Map<String, dynamic> body) async {
    final result = await backend!.functions.invoke(
      'companion-account',
      body: body,
    );
    if (result.status != 200) throw StateError('Anfrage fehlgeschlagen');
    return result.data;
  }
}
