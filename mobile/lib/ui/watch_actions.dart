import 'package:flutter/material.dart';
import '../data/app_store.dart';
import '../l10n/strings.dart';
import '../models/anime.dart';
import 'common.dart';

Future<void> incrementWithUndo(
  BuildContext context,
  AppStore store,
  WatchEntry entry,
) => perform(context, () async {
  final token = await store.changeProgressWithUndo(entry, 1);
  if (!context.mounted || token == null) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      showCloseIcon: false,
      persist: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.progressSaved),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: Text(context.l10n.undo),
              onPressed: () => perform(context, () async {
                messenger.hideCurrentSnackBar();
                final restored = await store.undoProgress(token);
                if (!restored && context.mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(context.l10n.undoUnavailable)),
                  );
                }
              }),
            ),
          ),
        ],
      ),
    ),
  );
});

class WatchProgress extends StatelessWidget {
  const WatchProgress({super.key, required this.store, required this.entry});
  final AppStore store;
  final WatchEntry entry;

  @override
  Widget build(BuildContext context) {
    final total = entry.anime.episodes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (total != null && total > 0)
          LinearProgressIndicator(
            value: (entry.watched / total).clamp(0, 1),
            borderRadius: BorderRadius.circular(4),
            semanticsLabel:
                '${context.l10n.sortProgress}: ${entry.watched} / $total',
          ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _ProgressDialog(store: store, entry: entry),
              ),
              child: Text('${entry.watched} / ${total ?? '?'}'),
            ),
            IconButton(
              tooltip: context.l10n.oneLess,
              onPressed: entry.watched == 0
                  ? null
                  : () =>
                        perform(context, () => store.changeProgress(entry, -1)),
              icon: const Icon(Icons.remove_rounded),
            ),
            IconButton.filledTonal(
              tooltip: context.l10n.oneWatched,
              onPressed: total != null && total > 0 && entry.watched >= total
                  ? null
                  : () => incrementWithUndo(context, store, entry),
              icon: const Icon(Icons.add_rounded),
            ),
            PopupMenuButton<String>(
              tooltip: context.l10n.watchActions,
              onSelected: (value) async {
                if (value == 'remove') {
                  final scope = store.scope;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialog) => AlertDialog(
                      title: Text(context.l10n.removeAnime),
                      content: Text(context.l10n.removeProgress),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialog, false),
                          child: Text(context.l10n.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialog, true),
                          child: Text(context.l10n.remove),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true &&
                      context.mounted &&
                      scope == store.scope) {
                    await perform(context, () => store.remove(entry.anime.id));
                  }
                } else {
                  await perform(
                    context,
                    () => store.setStatus(
                      entry.anime.id,
                      WatchStatus.parse(value),
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                for (final status in WatchStatus.values)
                  CheckedPopupMenuItem(
                    value: status.name,
                    checked: status == entry.status,
                    child: Text(watchStatusLabel(context, status)),
                  ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'remove',
                  child: Text(context.l10n.remove),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressDialog extends StatefulWidget {
  const _ProgressDialog({required this.store, required this.entry});
  final AppStore store;
  final WatchEntry entry;
  @override
  State<_ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  late final controller = TextEditingController(
    text: '${widget.entry.watched}',
  );
  late final scope = widget.store.scope;
  bool invalid = false;
  bool saving = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.editProgress),
    content: TextField(
      controller: controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: context.l10n.sortProgress,
        errorText: invalid ? context.l10n.progressInvalid : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: saving
            ? null
            : () async {
                final value = int.tryParse(controller.text.trim());
                final total = widget.entry.anime.episodes;
                if (value == null ||
                    value < 0 ||
                    value > (total != null && total > 0 ? total : 1000000)) {
                  setState(() => invalid = true);
                  return;
                }
                if (scope != widget.store.scope) {
                  Navigator.pop(context);
                  return;
                }
                setState(() => saving = true);
                try {
                  await widget.store.setWatched(widget.entry.anime.id, value);
                  if (context.mounted) Navigator.pop(context);
                } catch (_) {
                  if (mounted) {
                    setState(() {
                      saving = false;
                      invalid = true;
                    });
                  }
                }
              },
        child: Text(context.l10n.saveChanges),
      ),
    ],
  );
}

class SyncStatus extends StatelessWidget {
  const SyncStatus({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) {
    final conflicts = store.conflicts;
    if (conflicts.isEmpty &&
        store.pendingChanges == 0 &&
        store.watchError == null) {
      return const SizedBox.shrink();
    }
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conflicts.isNotEmpty
                  ? context.l10n.conflictHeading
                  : '${context.l10n.syncPending}: ${store.pendingChanges}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (store.watchError != null)
              Text(watchErrorText(context, store.watchError!)),
            if (conflicts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(context.l10n.conflictHint),
              for (final conflict in conflicts)
                Builder(
                  builder: (context) {
                    final local = store.entries
                        .where((e) => e.anime.id == conflict.id)
                        .firstOrNull;
                    String describe(WatchEntry? entry) => entry == null
                        ? context.l10n.entryRemoved
                        : '${entry.watched} / ${entry.anime.episodes ?? '?'} · ${watchStatusLabel(context, entry.status)}';
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            local?.anime.title ??
                                conflict.remote?.anime.title ??
                                '#${conflict.id}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${context.l10n.localVersion}: ${describe(local)}',
                          ),
                          Text(
                            '${context.l10n.cloudVersion}: ${describe(conflict.remote)}',
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () => perform(
                                  context,
                                  () => store.resolveConflict(
                                    conflict,
                                    keepLocal: false,
                                  ),
                                ),
                                child: Text(context.l10n.useCloud),
                              ),
                              TextButton(
                                onPressed: () => perform(
                                  context,
                                  () => store.resolveConflict(
                                    conflict,
                                    keepLocal: true,
                                  ),
                                ),
                                child: Text(context.l10n.keepLocal),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ] else
              TextButton.icon(
                onPressed: store.syncing ? null : store.refreshWatchlist,
                icon: const Icon(Icons.sync),
                label: Text(context.l10n.retrySync),
              ),
          ],
        ),
      ),
    );
  }
}
