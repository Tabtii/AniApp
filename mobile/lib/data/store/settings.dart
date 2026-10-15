part of '../app_store.dart';

// Device-local preferences: languages, country, providers and display options.
mixin _Settings on ChangeNotifier {
  SharedPreferences get preferences;
  String Function() get _deviceLanguage;
  void _notify();

  List<String> get providers => preferences.getStringList('providers') ?? [];
  List<String> get mutedSources =>
      preferences.getStringList('muted_sources') ?? [];
  bool get spoilerSafe => preferences.getBool('spoiler_safe') ?? false;
  bool get personalNews => preferences.getBool('personal_news') ?? false;
  Future<void> setPreference(String key, Object value) async {
    if (value is bool) await preferences.setBool(key, value);
    if (value is List<String>) await preferences.setStringList(key, value);
    _notify();
  }

  String get region {
    final value = preferences.getString('region');
    return ['DE', 'AT', 'CH', 'US', 'GB'].contains(value) ? value! : 'DE';
  }

  String get appLanguage {
    final value = preferences.getString('app_language');
    return AppStore.supportedLanguages.contains(value) ? value! : 'system';
  }

  String get resolvedAppLanguage => appLanguage == 'system'
      ? (_deviceLanguage() == 'de' ? 'de' : 'en')
      : appLanguage;

  String get newsLanguage {
    final value = preferences.getString('news_language');
    return [...AppStore.supportedLanguages, 'both'].contains(value)
        ? value!
        : 'app';
  }

  List<String> get newsLanguages => newsLanguage == 'both'
      ? AppStore.supportedLanguages
      : [newsLanguage == 'app' ? resolvedAppLanguage : newsLanguage];

  List<String> get dubLanguages {
    final saved = preferences.getStringList('dub_languages');
    final valid = AppStore.supportedLanguages
        .where((l) => saved?.contains(l) ?? false)
        .toList();
    if (valid.isNotEmpty) return valid;
    final legacy = preferences.getString('language');
    return [
      AppStore.supportedLanguages.contains(legacy)
          ? legacy!
          : resolvedAppLanguage,
    ];
  }

  // Kept for single-language enrichment requests; never used for news or UI.
  String get language => dubLanguages.first;
  String get languageMode => preferences.getString('language_mode') ?? 'any';

  Future<void> setAppLanguage(String value) async {
    if (![...AppStore.supportedLanguages, 'system'].contains(value)) return;
    await preferences.setStringList('dub_languages', dubLanguages);
    await preferences.setString('app_language', value);
    _notify();
  }

  Future<void> setNewsLanguage(String value) async {
    if (![...AppStore.supportedLanguages, 'both', 'app'].contains(value)) {
      return;
    }
    await preferences.setString('news_language', value);
    _notify();
  }

  Future<void> setDubLanguages(List<String> values) async {
    final valid = AppStore.supportedLanguages.where(values.contains).toList();
    if (valid.isEmpty) return;
    await preferences.setStringList('dub_languages', valid);
    _notify();
  }

  Future<void> setRegion(String value) async {
    if (!['DE', 'AT', 'CH', 'US', 'GB'].contains(value)) return;
    await preferences.setString('region', value);
    _notify();
  }

  Future<void> setCalendarMode(String value) async {
    if (!['any', 'dub'].contains(value)) return;
    await preferences.setString('language_mode', value);
    _notify();
  }
}
