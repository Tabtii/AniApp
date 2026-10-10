class ReleaseEvent {
  ReleaseEvent(this.data);
  final Map<String, dynamic> data;
  String? get image => data['image_url'] as String?;
  String get title => data['title'] as String? ?? 'Anime';
  int? get animeId => (data['mal_id'] as num?)?.toInt();
  String get kind => data['kind'] as String? ?? 'japan';
  String? get language => data['audio_language'] as String?;
  String get region => data['region'] as String? ?? 'JP';
  String get status => data['status'] as String? ?? 'announced';
  DateTime? get startsAt =>
      DateTime.tryParse(data['starts_at'] as String? ?? '')?.toLocal();
  // A calendar date is not a midnight timestamp and must not change timezone.
  DateTime? get startsOn =>
      DateTime.tryParse(data['starts_on'] as String? ?? '');
  DateTime? get date => startsAt ?? startsOn;
  String? get note => data['release_note'] as String?;
  DateTime? get checkedAt =>
      DateTime.tryParse(data['checked_at'] as String? ?? '')?.toLocal();
  bool isUpcoming(DateTime now) {
    if (startsAt != null) {
      return startsAt!.isAfter(now.subtract(const Duration(hours: 24)));
    }
    if (startsOn != null) {
      return !startsOn!.isBefore(DateTime(now.year, now.month, now.day));
    }
    return true;
  }

  String get provider =>
      data['provider'] as String? ?? 'Japanische Ausstrahlung';
  String get source => data['source_url'] as String? ?? '';
  int? get episode => (data['episode'] as num?)?.toInt();
}

class Availability {
  Availability(this.data);
  final Map<String, dynamic> data;
  String get provider => data['provider'] as String;
  String get region => data['region'] as String;
  List<String>? get audio => data['audio_languages'] == null
      ? null
      : List<String>.from(data['audio_languages'] as List);
  List<String>? get subtitles => data['subtitle_languages'] == null
      ? null
      : List<String>.from(data['subtitle_languages'] as List);
  String get status => data['status'] as String;
  String get url =>
      data['watch_url'] as String? ?? data['source_url'] as String? ?? '';
  String get scope => data['scope'] as String? ?? 'series';
  int? get season => (data['season_number'] as num?)?.toInt();
  String? get sourceName => data['source_name'] as String?;
  List<String> get offers => List<String>.from(data['offers'] as List? ?? []);
  int? get episode => (data['episode'] as num?)?.toInt();
  String get checkedAt => data['checked_at'] as String? ?? '';
}
