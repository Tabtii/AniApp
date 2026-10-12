import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/app_store.dart';
import '../data/list_transfer.dart';
import '../l10n/strings.dart';
import '../models/content.dart';
import 'content_screens.dart';
import 'common.dart';
import 'visuals.dart';

Future<void> shareJson(
  BuildContext context,
  String text,
  String filename,
) async {
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          Uint8List.fromList(utf8.encode(text)),
          mimeType: 'application/json',
        ),
      ],
      fileNameOverrides: [filename],
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

Future<void> importList(BuildContext context, AppStore store) async {
  try {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(
          label: 'Watchlist',
          extensions: ['xml', 'json'],
          uniformTypeIdentifiers: ['public.xml', 'public.json'],
          mimeTypes: ['text/xml', 'application/xml', 'application/json'],
        ),
      ],
    );
    if (file == null) return;
    if (await file.length() > 2 * 1024 * 1024) {
      throw const FormatException('File too large');
    }
    final parsed = parseWatchlist(await file.readAsString());
    if (!context.mounted) return;
    final missing = parsed.entries
        .where((e) => !store.isSaved(e.anime.id))
        .length;
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(context.l10n.importPreview),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.importHint),
              const SizedBox(height: 16),
              Text(
                '${parsed.entries.length} ✓ · $missing + · ${parsed.skipped} ⚠',
              ),
              for (final entry in parsed.entries.take(6))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${entry.anime.title} · ${entry.watched}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(context.l10n.cancelAction),
          ),
          FilledButton(
            onPressed: missing == 0 ? null : () => Navigator.pop(dialog, true),
            child: Text(context.l10n.importAction),
          ),
        ],
      ),
    );
    if (approved != true) return;
    await store.importEntries(parsed.entries);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.importDone)));
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.transferError)));
    }
  }
}

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late Future<List<Map<String, dynamic>>> future;
  @override
  void initState() {
    super.initState();
    future = widget.store.inbox();
  }

  Future<void> refresh() async {
    final next = widget.store.inbox();
    setState(() => future = next);
    try {
      await next;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.notifications),
      actions: [
        IconButton(
          tooltip: context.l10n.refresh,
          onPressed: refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, s) {
        if (s.hasError) {
          return EmptyPanel(
            context.l10n.actionFailed,
            action: TextButton(
              onPressed: refresh,
              child: Text(context.l10n.retry),
            ),
          );
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(context.l10n.notificationHint),
              const SizedBox(height: 8),
              Text(context.l10n.alertTimingHint),
              const SizedBox(height: 20),
              if (s.data!.isEmpty)
                Text(
                  widget.store.signedIn
                      ? context.l10n.inboxEmpty
                      : context.l10n.followSignIn,
                ),
              for (final row in s.data!)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            row['read_at'] == null
                                ? Icons.notifications_active_outlined
                                : Icons.notifications_none,
                          ),
                          title: Text(switch (row['kind']) {
                            'changed' => context.l10n.alertChanged,
                            'scheduled_today' => context.l10n.alertToday,
                            'scheduled_now' => context.l10n.alertNow,
                            'withdrawn' => context.l10n.alertWithdrawn,
                            _ => context.l10n.alertAnnouncement,
                          }),
                          subtitle: Text(
                            shortDate(
                              DateTime.tryParse(
                                row['created_at'] as String? ?? '',
                              ),
                              context,
                            ),
                          ),
                          trailing: row['read_at'] != null
                              ? null
                              : IconButton(
                                  tooltip: '✓',
                                  onPressed: () => perform(context, () async {
                                    await widget.store.markRead(
                                      row['id'] as String,
                                    );
                                    await refresh();
                                  }),
                                  icon: const Icon(Icons.done),
                                ),
                        ),
                        if (row['superseded'] == true)
                          Text(context.l10n.alertSuperseded),
                        if (row['superseded'] != true &&
                            row['kind'] != 'withdrawn')
                          ReleaseTile(
                            event: ReleaseEvent(
                              Map<String, dynamic>.from(row['event'] as Map),
                            ),
                            store: widget.store,
                          )
                        else
                          Text((row['event'] as Map)['title'] as String? ?? ''),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class FollowDubButton extends StatefulWidget {
  const FollowDubButton({super.key, required this.store, required this.id});
  final AppStore store;
  final int id;
  @override
  State<FollowDubButton> createState() => _FollowDubButtonState();
}

class _FollowDubButtonState extends State<FollowDubButton> {
  bool following = false, busy = false;
  String settings = '';
  @override
  void initState() {
    super.initState();
    widget.store.addListener(changed);
    changed();
  }

  void changed() {
    final key =
        '${widget.store.scope}|${widget.store.region}|${widget.store.dubLanguages}';
    if (settings == key) return;
    settings = key;
    final requested = key;
    widget.store
        .follows(widget.id)
        .then((rows) {
          if (mounted && settings == requested) {
            setState(
              () => following = rows.any(
                (r) => widget.store.dubLanguages.contains(r['audio_language']),
              ),
            );
          }
        })
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    widget.store.removeListener(changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      OutlinedButton.icon(
        onPressed: busy
            ? null
            : () => perform(context, () async {
                if (!widget.store.signedIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.followSignIn)),
                  );
                  return;
                }
                setState(() => busy = true);
                try {
                  await widget.store.followDub(widget.id, !following);
                  if (mounted) setState(() => following = !following);
                } finally {
                  if (mounted) setState(() => busy = false);
                }
              }),
        icon: Icon(
          following ? Icons.notifications_active : Icons.notifications_none,
        ),
        label: Text(
          following ? context.l10n.unfollowDub : context.l10n.followDub,
        ),
      ),
      Text(
        context.l10n.notificationHint,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class SourceHealthScreen extends StatefulWidget {
  const SourceHealthScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<SourceHealthScreen> createState() => _SourceHealthScreenState();
}

class _SourceHealthScreenState extends State<SourceHealthScreen> {
  late Future<List<dynamic>> future;
  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    future = Future.wait([
      widget.store.sourceHealth(),
      widget.store.backend?.from('source_rights').select().order('name') ??
          Future.value(<Map<String, dynamic>>[]),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.sourceHealth),
      actions: [
        IconButton(
          tooltip: context.l10n.refresh,
          onPressed: () => setState(load),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, s) {
        if (s.hasError) return EmptyPanel(context.l10n.actionFailed);
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final health = s.data![0] as List;
        final rights = s.data![1] as List;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final r in rights)
              Card(
                child: ListTile(
                  title: Text(r['name'] as String),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['status'] == 'approved'
                            ? '✓ ${r['status']}'
                            : context.l10n.rightsPending,
                      ),
                      for (final h in health.where(
                        (h) => h['source_key'] == r['source_key'],
                      ))
                        Text(
                          '${h['state']} · ${shortDate(DateTime.tryParse(h['checked_at'] as String? ?? ''), context)}',
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => openSource(context, r['terms_url'] as String),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late Future<dynamic> future;
  @override
  void initState() {
    super.initState();
    future = widget.store.editorial({'action': 'queue'});
  }

  void refresh() {
    setState(() => future = widget.store.editorial({'action': 'queue'}));
  }

  Future<void> review(Map<String, dynamic> row) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ReviewDialog(row: row),
    );
    if (result == null || !mounted) return;
    await perform(context, () async {
      await widget.store.editorial({
        'action': 'review',
        'source_url': row['source_url'],
        'candidate_key': row['candidate_key'],
        'checked_at': row['checked_at'],
        ...result,
      });
      if (mounted) refresh();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.l10n.editorial),
      actions: [
        IconButton(
          onPressed: refresh,
          icon: const Icon(Icons.refresh),
          tooltip: context.l10n.refresh,
        ),
      ],
    ),
    body: FutureBuilder<dynamic>(
      future: future,
      builder: (context, s) {
        if (s.hasError) return EmptyPanel(context.l10n.actionFailed);
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final rows = s.data['candidates'] as List;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (rows.isEmpty) Text(context.l10n.reviewQueueEmpty),
            for (final row in rows)
              Card(
                child: ListTile(
                  title: Text(row['candidate_key'] as String),
                  subtitle: Text('${row['reason']}\n${row['evidence']}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.fact_check_outlined),
                  onTap: () => review(Map<String, dynamic>.from(row as Map)),
                ),
              ),
          ],
        );
      },
    ),
  );
}

Future<void> deleteAccount(BuildContext context, AppStore store) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(context.l10n.deleteAccount),
      content: Text(context.l10n.deleteAccountHint),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog, false),
          child: Text(context.l10n.cancelAction),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: Text(context.l10n.deleteAccount),
        ),
      ],
    ),
  );
  if (confirm != true) return;
  final scope = store.scope;
  await store.editorial({'action': 'delete', 'confirm': 'DELETE'});
  await store.preferences.remove('watch_state_$scope');
  await store.preferences.remove('watchlist_$scope');
  await store.backend!.auth.signOut(scope: SignOutScope.local);
}

class ReviewDialog extends StatefulWidget {
  const ReviewDialog({super.key, required this.row});
  final Map<String, dynamic> row;
  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  late final TextEditingController event;
  final note = TextEditingController();
  String? error;
  @override
  void initState() {
    super.initState();
    event = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(
        (widget.row['proposal'] as Map)['event'] ??
            {
              'mal_id': null,
              'title': '',
              'episode': null,
              'kind': 'dub',
              'starts_on': null,
              'starts_at': null,
              'provider': '',
              'region': '',
              'audio_language': '',
              'status': 'announced',
              'source_url': widget.row['source_url'],
            },
      ),
    );
  }

  @override
  void dispose() {
    event.dispose();
    note.dispose();
    super.dispose();
  }

  void submit(bool approve) {
    try {
      if (note.text.trim().isEmpty) throw const FormatException();
      final value = approve ? jsonDecode(event.text) : null;
      if (approve && value is! Map) throw const FormatException();
      Navigator.pop(context, <String, dynamic>{
        'approve': approve,
        'event': value,
        'note': note.text.trim(),
      });
    } catch (_) {
      setState(() => error = context.l10n.actionFailed);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.editorial),
    content: SizedBox(
      width: 600,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.reviewHint),
            TextButton(
              onPressed: () =>
                  openSource(context, widget.row['source_url'] as String),
              child: Text(context.l10n.readOriginal),
            ),
            SelectableText(widget.row['evidence'] as String? ?? ''),
            const SizedBox(height: 12),
            TextField(
              controller: event,
              minLines: 6,
              maxLines: 15,
              decoration: const InputDecoration(labelText: 'Event JSON'),
            ),
            TextField(
              controller: note,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: context.l10n.reviewNote,
                errorText: error,
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancelAction),
      ),
      TextButton(
        onPressed: () => submit(false),
        child: Text(context.l10n.rejectReview),
      ),
      FilledButton(
        onPressed: () => submit(true),
        child: Text(context.l10n.approveReview),
      ),
    ],
  );
}
