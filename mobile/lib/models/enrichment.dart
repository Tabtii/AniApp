import 'content.dart';

class AnimeEnrichment {
  const AnimeEnrichment(this.data);
  final Map<String, dynamic> data;
  static const empty = AnimeEnrichment({});
  Map<String, dynamic> get dub =>
      Map<String, dynamic>.from(data['dub'] as Map? ?? {});
  Map<String, dynamic> get streaming =>
      Map<String, dynamic>.from(data['streaming'] as Map? ?? {});
  Map<String, dynamic> get anilist =>
      Map<String, dynamic>.from(data['anilist'] as Map? ?? {});
  Map<String, dynamic> get kitsu =>
      Map<String, dynamic>.from(data['kitsu'] as Map? ?? {});
  String? get overview => streaming['overview'] as String?;
  String? get banner =>
      anilist['banner'] as String? ?? kitsu['banner'] as String?;
  String? get synopsis => kitsu['synopsis'] as String?;
  ReleaseEvent? get nextRelease => anilist['next_release'] is Map
      ? ReleaseEvent(Map<String, dynamic>.from(anilist['next_release'] as Map))
      : null;
  List<Availability> get providers => (streaming['providers'] as List? ?? [])
      .map((e) => Availability(Map<String, dynamic>.from(e as Map)))
      .toList();
}

List<ReleaseEvent> mergeJapanSchedule(
  List<ReleaseEvent> existing,
  List<ReleaseEvent> anilist,
) {
  final paused = existing
      .where(
        (e) => e.kind == 'japan' && e.status == 'delayed' && e.date == null,
      )
      .map((e) => e.animeId)
      .toSet();
  anilist = anilist.where((e) => !paused.contains(e.animeId)).toList();
  final ids = anilist.map((e) => e.animeId).toSet();
  final result = [
    ...existing.where(
      (e) =>
          !(e.kind == 'japan' &&
              e.provider == 'Tenrai / MyAnimeList' &&
              (ids.contains(e.animeId) || paused.contains(e.animeId))),
    ),
    ...anilist,
  ];
  result.sort(
    (a, b) => a.date == null
        ? (b.date == null ? a.title.compareTo(b.title) : 1)
        : b.date == null
        ? -1
        : a.date!.compareTo(b.date!),
  );
  return result;
}
