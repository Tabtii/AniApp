enum WatchStatus {
  planned('Geplant'),
  watching('Schaue ich'),
  completed('Abgeschlossen'),
  paused('Pausiert'),
  dropped('Abgebrochen');

  const WatchStatus(this.label);
  final String label;
  static WatchStatus parse(String? value) => WatchStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => WatchStatus.planned,
  );
}

class Anime {
  const Anime({
    required this.id,
    required this.title,
    this.image,
    this.score,
    this.episodes,
    this.synopsis,
    this.genres = const [],
    this.broadcast,
  });
  final int id;
  final String title;
  final String? image, synopsis, broadcast;
  final double? score;
  final int? episodes;
  final List<String> genres;

  factory Anime.fromJikan(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>?;
    final jpg = images?['jpg'] as Map<String, dynamic>?;
    final broadcast = json['broadcast'] as Map<String, dynamic>?;
    return Anime(
      id: (json['mal_id'] as num).toInt(),
      title:
          (json['title_english'] as String?) ??
          (json['title'] as String?) ??
          'Ohne Titel',
      image: jpg?['large_image_url'] as String? ?? jpg?['image_url'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      episodes: (json['episodes'] as num?)?.toInt(),
      synopsis: json['synopsis'] as String?,
      genres: (json['genres'] as List<dynamic>? ?? [])
          .map((g) => (g as Map)['name'] as String)
          .toList(),
      broadcast: broadcast?['string'] as String?,
    );
  }
  factory Anime.fromJson(Map<String, dynamic> json) => Anime(
    id: (json['id'] as num).toInt(),
    title: json['title'] as String,
    image: json['image'] as String?,
    score: (json['score'] as num?)?.toDouble(),
    episodes: (json['episodes'] as num?)?.toInt(),
    synopsis: json['synopsis'] as String?,
    broadcast: json['broadcast'] as String?,
    genres: List<String>.from(json['genres'] as List? ?? []),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'image': image,
    'score': score,
    'episodes': episodes,
    'synopsis': synopsis,
    'genres': genres,
    'broadcast': broadcast,
  };
}

class WatchEntry {
  const WatchEntry({
    required this.anime,
    this.status = WatchStatus.planned,
    this.watched = 0,
  });
  final Anime anime;
  final WatchStatus status;
  final int watched;
  WatchEntry progress(int delta) {
    final total = anime.episodes;
    final next = (watched + delta).clamp(
      0,
      total != null && total > 0 ? total : 1000000,
    );
    var nextStatus = status;
    if (total != null && total > 0 && next == total) {
      nextStatus = WatchStatus.completed;
    } else if (next > 0 &&
        (status == WatchStatus.planned || status == WatchStatus.completed)) {
      nextStatus = WatchStatus.watching;
    } else if (next == 0 && status == WatchStatus.completed) {
      nextStatus = WatchStatus.planned;
    }
    return WatchEntry(anime: anime, status: nextStatus, watched: next);
  }

  WatchEntry withStatus(WatchStatus value) => WatchEntry(
    anime: anime,
    status: value,
    watched: value == WatchStatus.completed && (anime.episodes ?? 0) > 0
        ? anime.episodes!
        : watched,
  );
  Map<String, dynamic> toJson() => {
    'anime': anime.toJson(),
    'status': status.name,
    'watched': watched,
  };
  factory WatchEntry.fromJson(Map<String, dynamic> json) => WatchEntry(
    anime: Anime.fromJson(Map<String, dynamic>.from(json['anime'] as Map)),
    status: WatchStatus.parse(json['status'] as String?),
    watched: (json['watched'] as num?)?.toInt() ?? 0,
  );
}

class AnimePage {
  const AnimePage(this.items, this.hasNext);
  final List<Anime> items;
  final bool hasNext;
}

String currentSeason(DateTime date) => switch (date.month) {
  <= 3 => 'winter',
  <= 6 => 'spring',
  <= 9 => 'summer',
  _ => 'fall',
};
