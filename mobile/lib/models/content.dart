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
  int? get episode => (data['episode'] as num?)?.toInt();
  String get checkedAt => data['checked_at'] as String? ?? '';
}
