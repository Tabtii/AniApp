import 'anime.dart';

/// A conflicting edit stays on disk until the user chooses a version.
class WatchConflict {
  const WatchConflict({required this.id, this.remote, this.revision});
  final int id;
  final WatchEntry? remote;
  final String? revision;

  Map<String, dynamic> toJson() => {
    'id': id,
    'remote': remote?.toJson(),
    'revision': revision,
  };

  factory WatchConflict.fromJson(Map<String, dynamic> value) => WatchConflict(
    id: (value['id'] as num).toInt(),
    remote: value['remote'] == null
        ? null
        : WatchEntry.fromJson(
            Map<String, dynamic>.from(value['remote'] as Map),
          ),
    revision: value['revision'] as String?,
  );
}

/// Undo is valid only for the last local change to this title in this session.
class ProgressUndo {
  const ProgressUndo(this.before, this.session, this.edit);
  final WatchEntry before;
  final int session;
  final int edit;
}
