import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @openProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get openProfile;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @myList.
  ///
  /// In en, this message translates to:
  /// **'My list'**
  String get myList;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @spring.
  ///
  /// In en, this message translates to:
  /// **'Spring'**
  String get spring;

  /// No description provided for @summer.
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get summer;

  /// No description provided for @autumn.
  ///
  /// In en, this message translates to:
  /// **'Autumn'**
  String get autumn;

  /// No description provided for @allGenres.
  ///
  /// In en, this message translates to:
  /// **'All genres'**
  String get allGenres;

  /// No description provided for @catalogHeading.
  ///
  /// In en, this message translates to:
  /// **'Your next favourite anime.'**
  String get catalogHeading;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Titles, worlds, new stories …'**
  String get searchHint;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @loadingAnime.
  ///
  /// In en, this message translates to:
  /// **'Loading anime …'**
  String get loadingAnime;

  /// No description provided for @noAnime.
  ///
  /// In en, this message translates to:
  /// **'No anime found. Try different search terms or filters.'**
  String get noAnime;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Your search results'**
  String get searchResults;

  /// No description provided for @moreSeason.
  ///
  /// In en, this message translates to:
  /// **'More from this season'**
  String get moreSeason;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @newWorlds.
  ///
  /// In en, this message translates to:
  /// **'Discover new worlds'**
  String get newWorlds;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more anime'**
  String get loadMore;

  /// No description provided for @savedWatchlist.
  ///
  /// In en, this message translates to:
  /// **'In your watchlist'**
  String get savedWatchlist;

  /// No description provided for @addWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Add to watchlist'**
  String get addWatchlist;

  /// No description provided for @discoverAnime.
  ///
  /// In en, this message translates to:
  /// **'Explore anime'**
  String get discoverAnime;

  /// No description provided for @watchlistHeading.
  ///
  /// In en, this message translates to:
  /// **'Your anime. Your pace.'**
  String get watchlistHeading;

  /// No description provided for @myWatchlist.
  ///
  /// In en, this message translates to:
  /// **'My watchlist'**
  String get myWatchlist;

  /// No description provided for @retrySync.
  ///
  /// In en, this message translates to:
  /// **'Retry sync'**
  String get retrySync;

  /// No description provided for @watchlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Save an anime in Discover. Track your next episodes here.'**
  String get watchlistEmpty;

  /// No description provided for @oneLess.
  ///
  /// In en, this message translates to:
  /// **'One episode less'**
  String get oneLess;

  /// No description provided for @oneWatched.
  ///
  /// In en, this message translates to:
  /// **'One episode watched'**
  String get oneWatched;

  /// No description provided for @removeAnime.
  ///
  /// In en, this message translates to:
  /// **'Remove anime?'**
  String get removeAnime;

  /// No description provided for @removeProgress.
  ///
  /// In en, this message translates to:
  /// **'Your saved progress will be removed.'**
  String get removeProgress;

  /// No description provided for @yourProfile.
  ///
  /// In en, this message translates to:
  /// **'YOUR PROFILE'**
  String get yourProfile;

  /// No description provided for @profileHeading.
  ///
  /// In en, this message translates to:
  /// **'Your everyday anime.'**
  String get profileHeading;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get guest;

  /// No description provided for @watchlistCloud.
  ///
  /// In en, this message translates to:
  /// **'Your watchlist syncs with your account.'**
  String get watchlistCloud;

  /// No description provided for @watchlistLocal.
  ///
  /// In en, this message translates to:
  /// **'Your watchlist stays on this device.'**
  String get watchlistLocal;

  /// No description provided for @loginRegister.
  ///
  /// In en, this message translates to:
  /// **'Sign in or register'**
  String get loginRegister;

  /// No description provided for @importGuest.
  ///
  /// In en, this message translates to:
  /// **'Import guest watchlist'**
  String get importGuest;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Streaming country'**
  String get region;

  /// No description provided for @germany.
  ///
  /// In en, this message translates to:
  /// **'Germany'**
  String get germany;

  /// No description provided for @austria.
  ///
  /// In en, this message translates to:
  /// **'Austria'**
  String get austria;

  /// No description provided for @switzerland.
  ///
  /// In en, this message translates to:
  /// **'Switzerland'**
  String get switzerland;

  /// No description provided for @unitedKingdom.
  ///
  /// In en, this message translates to:
  /// **'United Kingdom'**
  String get unitedKingdom;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get systemLanguage;

  /// No description provided for @newsLanguage.
  ///
  /// In en, this message translates to:
  /// **'News language'**
  String get newsLanguage;

  /// No description provided for @followApp.
  ///
  /// In en, this message translates to:
  /// **'Same as app'**
  String get followApp;

  /// No description provided for @bothLanguages.
  ///
  /// In en, this message translates to:
  /// **'German & English'**
  String get bothLanguages;

  /// No description provided for @dubLanguages.
  ///
  /// In en, this message translates to:
  /// **'Preferred dubs'**
  String get dubLanguages;

  /// No description provided for @dubSelectionHint.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one language. News and app language are independent.'**
  String get dubSelectionHint;

  /// No description provided for @calendarDisplay.
  ///
  /// In en, this message translates to:
  /// **'Calendar contents'**
  String get calendarDisplay;

  /// No description provided for @calendarAll.
  ///
  /// In en, this message translates to:
  /// **'Original, streaming & selected dubs'**
  String get calendarAll;

  /// No description provided for @calendarDubs.
  ///
  /// In en, this message translates to:
  /// **'Selected dubs only'**
  String get calendarDubs;

  /// No description provided for @availabilityHint.
  ///
  /// In en, this message translates to:
  /// **'Audio and subtitles are shown separately. Availability can vary by provider, country, season and episode.'**
  String get availabilityHint;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources & notes'**
  String get sources;

  /// No description provided for @nextEpisode.
  ///
  /// In en, this message translates to:
  /// **'Your next episode.'**
  String get nextEpisode;

  /// No description provided for @aboutTimes.
  ///
  /// In en, this message translates to:
  /// **'About release times'**
  String get aboutTimes;

  /// No description provided for @calendarLoadError.
  ///
  /// In en, this message translates to:
  /// **'Release dates could not be loaded.'**
  String get calendarLoadError;

  /// No description provided for @allSeasons.
  ///
  /// In en, this message translates to:
  /// **'All seasons · ongoing series & announced premieres'**
  String get allSeasons;

  /// No description provided for @allProviders.
  ///
  /// In en, this message translates to:
  /// **'All providers'**
  String get allProviders;

  /// No description provided for @allDays.
  ///
  /// In en, this message translates to:
  /// **'All days'**
  String get allDays;

  /// No description provided for @undated.
  ///
  /// In en, this message translates to:
  /// **'TBA'**
  String get undated;

  /// No description provided for @calendarEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled here yet. Choose another day or show all anime.'**
  String get calendarEmpty;

  /// No description provided for @undatedUpper.
  ///
  /// In en, this message translates to:
  /// **'TBA'**
  String get undatedUpper;

  /// No description provided for @noTime.
  ///
  /// In en, this message translates to:
  /// **'NO TIME'**
  String get noTime;

  /// No description provided for @timeUpper.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get timeUpper;

  /// No description provided for @japaneseBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Japanese TV broadcast'**
  String get japaneseBroadcast;

  /// No description provided for @estimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get estimated;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @delayed.
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get delayed;

  /// No description provided for @announced.
  ///
  /// In en, this message translates to:
  /// **'Announced'**
  String get announced;

  /// No description provided for @openDateSource.
  ///
  /// In en, this message translates to:
  /// **'Open release source'**
  String get openDateSource;

  /// No description provided for @newsHeading.
  ///
  /// In en, this message translates to:
  /// **'News from your world.'**
  String get newsHeading;

  /// No description provided for @newsAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'News & announcements'**
  String get newsAnnouncements;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @seasons.
  ///
  /// In en, this message translates to:
  /// **'Seasons'**
  String get seasons;

  /// No description provided for @newsLoadError.
  ///
  /// In en, this message translates to:
  /// **'News could not be loaded.'**
  String get newsLoadError;

  /// No description provided for @newsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No news for this topic in your selected language(s) yet.'**
  String get newsEmpty;

  /// No description provided for @newSeasons.
  ///
  /// In en, this message translates to:
  /// **'New seasons'**
  String get newSeasons;

  /// No description provided for @readOriginal.
  ///
  /// In en, this message translates to:
  /// **'Read original'**
  String get readOriginal;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Anime details'**
  String get detailTitle;

  /// No description provided for @inYourList.
  ///
  /// In en, this message translates to:
  /// **'In your list'**
  String get inYourList;

  /// No description provided for @saveWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Add to my watchlist'**
  String get saveWatchlist;

  /// No description provided for @story.
  ///
  /// In en, this message translates to:
  /// **'The story'**
  String get story;

  /// No description provided for @noSynopsis.
  ///
  /// In en, this message translates to:
  /// **'No description available yet.'**
  String get noSynopsis;

  /// No description provided for @tmdbSynopsis.
  ///
  /// In en, this message translates to:
  /// **'Description: TMDb'**
  String get tmdbSynopsis;

  /// No description provided for @anilistCredit.
  ///
  /// In en, this message translates to:
  /// **'Artwork & episode dates: AniList'**
  String get anilistCredit;

  /// No description provided for @kitsuCredit.
  ///
  /// In en, this message translates to:
  /// **'Additional artwork & details: Kitsu'**
  String get kitsuCredit;

  /// No description provided for @nextJapan.
  ///
  /// In en, this message translates to:
  /// **'Next broadcast in Japan'**
  String get nextJapan;

  /// No description provided for @nextRelease.
  ///
  /// In en, this message translates to:
  /// **'Next release'**
  String get nextRelease;

  /// No description provided for @dateTba.
  ///
  /// In en, this message translates to:
  /// **'Date to be announced'**
  String get dateTba;

  /// No description provided for @weeklyEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated from the regular schedule. Breaks are possible.'**
  String get weeklyEstimate;

  /// No description provided for @pausedTba.
  ///
  /// In en, this message translates to:
  /// **'Paused or delayed – date to be announced'**
  String get pausedTba;

  /// No description provided for @announcedDate.
  ///
  /// In en, this message translates to:
  /// **'Announced date'**
  String get announcedDate;

  /// No description provided for @regularJapan.
  ///
  /// In en, this message translates to:
  /// **'Regular broadcast in Japan'**
  String get regularJapan;

  /// No description provided for @japanNotLocal.
  ///
  /// In en, this message translates to:
  /// **'This is not a confirmed streaming or dub release in your country.'**
  String get japanNotLocal;

  /// No description provided for @noProviders.
  ///
  /// In en, this message translates to:
  /// **'No reliable provider information is available for this title and country yet.'**
  String get noProviders;

  /// No description provided for @malProviders.
  ///
  /// In en, this message translates to:
  /// **'Provider overview on MyAnimeList'**
  String get malProviders;

  /// No description provided for @tmdbUnavailable.
  ///
  /// In en, this message translates to:
  /// **'TMDb / JustWatch is currently unavailable.'**
  String get tmdbUnavailable;

  /// No description provided for @providerCredit.
  ///
  /// In en, this message translates to:
  /// **'Provider information: JustWatch via TMDb. Check availability and languages with the provider.'**
  String get providerCredit;

  /// No description provided for @titleMapping.
  ///
  /// In en, this message translates to:
  /// **'Title mapping: Fribb / anime-lists'**
  String get titleMapping;

  /// No description provided for @reportedAvailable.
  ///
  /// In en, this message translates to:
  /// **'Reported as available'**
  String get reportedAvailable;

  /// No description provided for @movieScope.
  ///
  /// In en, this message translates to:
  /// **'Information applies to this film.'**
  String get movieScope;

  /// No description provided for @seriesScope.
  ///
  /// In en, this message translates to:
  /// **'Information applies to the series; it may vary by season and episode.'**
  String get seriesScope;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @withAds.
  ///
  /// In en, this message translates to:
  /// **'With ads'**
  String get withAds;

  /// No description provided for @rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @noInformation.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get noInformation;

  /// No description provided for @tmdbOffers.
  ///
  /// In en, this message translates to:
  /// **'View offers on TMDb'**
  String get tmdbOffers;

  /// No description provided for @checkProvider.
  ///
  /// In en, this message translates to:
  /// **'Check with provider'**
  String get checkProvider;

  /// No description provided for @startTba.
  ///
  /// In en, this message translates to:
  /// **'Premiere date to be announced'**
  String get startTba;

  /// No description provided for @germanDub.
  ///
  /// In en, this message translates to:
  /// **'German dub'**
  String get germanDub;

  /// No description provided for @partialDub.
  ///
  /// In en, this message translates to:
  /// **'Partially dubbed'**
  String get partialDub;

  /// No description provided for @dubExists.
  ///
  /// In en, this message translates to:
  /// **'Dub exists'**
  String get dubExists;

  /// No description provided for @dubEvidenceHint.
  ///
  /// In en, this message translates to:
  /// **'According to MyDubList. This does not confirm the provider, country or individual episode releases.'**
  String get dubEvidenceHint;

  /// No description provided for @mydubSource.
  ///
  /// In en, this message translates to:
  /// **'Source: MyDubList'**
  String get mydubSource;

  /// No description provided for @japaneseOriginalHint.
  ///
  /// In en, this message translates to:
  /// **'Japanese is the original language of most anime. Check audio options with the provider.'**
  String get japaneseOriginalHint;

  /// No description provided for @mydubUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The additional language source MyDubList is currently unavailable.'**
  String get mydubUnavailable;

  /// No description provided for @languageVaries.
  ///
  /// In en, this message translates to:
  /// **'Audio languages may vary by season and episode.'**
  String get languageVaries;

  /// No description provided for @noDubEvidence.
  ///
  /// In en, this message translates to:
  /// **'No verified dub announcement is recorded for this title and country yet.'**
  String get noDubEvidence;

  /// No description provided for @announcedStart.
  ///
  /// In en, this message translates to:
  /// **'Announced premiere'**
  String get announcedStart;

  /// No description provided for @pastAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'The announced date is in the past. Check current availability with the provider.'**
  String get pastAnnouncement;

  /// No description provided for @viewAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'View announcement'**
  String get viewAnnouncement;

  /// No description provided for @moreAboutSeries.
  ///
  /// In en, this message translates to:
  /// **'More about this series'**
  String get moreAboutSeries;

  /// No description provided for @airing.
  ///
  /// In en, this message translates to:
  /// **'Airing'**
  String get airing;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @dateOpen.
  ///
  /// In en, this message translates to:
  /// **'Date TBA'**
  String get dateOpen;

  /// No description provided for @unreleased.
  ///
  /// In en, this message translates to:
  /// **'Not released yet'**
  String get unreleased;

  /// No description provided for @kitsuDatesHint.
  ///
  /// In en, this message translates to:
  /// **'Information applies to this anime entry; local releases may differ.'**
  String get kitsuDatesHint;

  /// No description provided for @kitsuSource.
  ///
  /// In en, this message translates to:
  /// **'Source: Kitsu'**
  String get kitsuSource;

  /// No description provided for @youtubeTrailer.
  ///
  /// In en, this message translates to:
  /// **'Trailer on YouTube'**
  String get youtubeTrailer;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @repeatPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get repeatPassword;

  /// No description provided for @minPassword.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get minPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get savePassword;

  /// No description provided for @sendLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get sendLink;

  /// No description provided for @backSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backSignIn;

  /// No description provided for @toSignIn.
  ///
  /// In en, this message translates to:
  /// **'Go to sign in'**
  String get toSignIn;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @continueGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueGuest;

  /// No description provided for @guestHint.
  ///
  /// In en, this message translates to:
  /// **'Without an account, your list stays on this device.'**
  String get guestHint;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get enterPassword;

  /// No description provided for @passwordLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordLength;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @checkInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox.'**
  String get checkInbox;

  /// No description provided for @freshStart.
  ///
  /// In en, this message translates to:
  /// **'A fresh start.'**
  String get freshStart;

  /// No description provided for @backReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to return.'**
  String get backReady;

  /// No description provided for @loginRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Your anime.\nYour home.'**
  String get loginRegisterTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Your next episode\nis waiting.'**
  String get loginTitle;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set your new password now.'**
  String get setNewPassword;

  /// No description provided for @recoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you back to your watchlist.'**
  String get recoverySubtitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Collect favourites. Save your progress. Pick up on any device.'**
  String get loginSubtitle;

  /// No description provided for @yourWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Your watchlist'**
  String get yourWatchlist;

  /// No description provided for @allDevices.
  ///
  /// In en, this message translates to:
  /// **'On every device'**
  String get allDevices;

  /// No description provided for @recoverySent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, you will receive a reset link. Open it on this device.'**
  String get recoverySent;

  /// No description provided for @confirmationSent.
  ///
  /// In en, this message translates to:
  /// **'If confirmation is required, you will receive an email. Open the link on this device, then sign in.'**
  String get confirmationSent;

  /// No description provided for @checkSpam.
  ///
  /// In en, this message translates to:
  /// **'Check your spam folder too.'**
  String get checkSpam;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect. Please try again.'**
  String get invalidCredentials;

  /// No description provided for @confirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email using the link first.'**
  String get confirmEmail;

  /// No description provided for @authRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get authRateLimit;

  /// No description provided for @emailNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Email delivery is not enabled yet. You can still use your local watchlist.'**
  String get emailNotEnabled;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password with at least 8 characters.'**
  String get weakPassword;

  /// No description provided for @samePassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a different password from your current one.'**
  String get samePassword;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'That did not work. Check your details and try again.'**
  String get authError;

  /// No description provided for @authTimeout.
  ///
  /// In en, this message translates to:
  /// **'The connection is taking too long. Please try again.'**
  String get authTimeout;

  /// No description provided for @authOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get authOffline;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed.'**
  String get passwordChanged;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Your changes could not be saved. Please try again.'**
  String get actionFailed;

  /// No description provided for @linkFailed.
  ///
  /// In en, this message translates to:
  /// **'The link could not be opened.'**
  String get linkFailed;

  /// No description provided for @enrichmentError.
  ///
  /// In en, this message translates to:
  /// **'Additional language and provider details are currently unavailable.'**
  String get enrichmentError;

  /// No description provided for @detailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Details could not be loaded.'**
  String get detailLoadError;

  /// No description provided for @streamingError.
  ///
  /// In en, this message translates to:
  /// **'Streaming information is currently unavailable.'**
  String get streamingError;

  /// No description provided for @dubLoadError.
  ///
  /// In en, this message translates to:
  /// **'Dub announcements could not be loaded.'**
  String get dubLoadError;

  /// No description provided for @releaseError.
  ///
  /// In en, this message translates to:
  /// **'Release dates are currently unavailable.'**
  String get releaseError;

  /// No description provided for @episodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} episodes'**
  String episodeCount(String count);

  /// No description provided for @episodeNumber.
  ///
  /// In en, this message translates to:
  /// **'Episode {number}'**
  String episodeNumber(String number);

  /// No description provided for @listCount.
  ///
  /// In en, this message translates to:
  /// **'{count} anime in your list'**
  String listCount(String count);

  /// No description provided for @titleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} titles'**
  String titleCount(String count);

  /// No description provided for @allCount.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String allCount(String count);

  /// No description provided for @releaseCalendar.
  ///
  /// In en, this message translates to:
  /// **'Release calendar · {region}'**
  String releaseCalendar(String region);

  /// No description provided for @dubHeading.
  ///
  /// In en, this message translates to:
  /// **'Dub · {language}'**
  String dubHeading(String language);

  /// No description provided for @checkedOn.
  ///
  /// In en, this message translates to:
  /// **'Checked on {date}'**
  String checkedOn(String date);

  /// No description provided for @fetchedOn.
  ///
  /// In en, this message translates to:
  /// **'Fetched: {date}'**
  String fetchedOn(String date);

  /// No description provided for @sourceName.
  ///
  /// In en, this message translates to:
  /// **'Source: {name}'**
  String sourceName(String name);

  /// No description provided for @lastChecked.
  ///
  /// In en, this message translates to:
  /// **'Last checked: {date}'**
  String lastChecked(String date);

  /// No description provided for @audioLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio: {languages}'**
  String audioLabel(String languages);

  /// No description provided for @subtitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtitles: {languages}'**
  String subtitleLabel(String languages);

  /// No description provided for @whereWatch.
  ///
  /// In en, this message translates to:
  /// **'Where to watch · {region}'**
  String whereWatch(String region);

  /// No description provided for @seasonScope.
  ///
  /// In en, this message translates to:
  /// **'Information applies to season {number}; check episode coverage.'**
  String seasonScope(String number);

  /// No description provided for @runtime.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min / episode'**
  String runtime(String minutes);

  /// No description provided for @originalDates.
  ///
  /// In en, this message translates to:
  /// **'Original broadcast: {dates}'**
  String originalDates(String dates);

  /// No description provided for @deviceTime.
  ///
  /// In en, this message translates to:
  /// **'{date} · device time'**
  String deviceTime(String date);

  /// No description provided for @timeUnknown.
  ///
  /// In en, this message translates to:
  /// **'{date} · time TBA'**
  String timeUnknown(String date);

  /// No description provided for @planned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get planned;

  /// No description provided for @watching.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get watching;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @dropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get dropped;

  /// No description provided for @languageDe.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageDe;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageJa.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get languageJa;

  /// No description provided for @calendarHint.
  ///
  /// In en, this message translates to:
  /// **'The calendar includes ongoing anime from all seasons. Provider releases and dubs can continue after the Japanese broadcast ends. Times use your device time zone. Estimated dates come from weekly schedules; breaks and delays are possible. Provider coverage is incomplete. Each event includes its source and check date.'**
  String get calendarHint;

  /// No description provided for @cloudWarning.
  ///
  /// In en, this message translates to:
  /// **'The cloud connection could not start. Your local watchlist is still available.'**
  String get cloudWarning;

  /// No description provided for @catalogRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment and try again.'**
  String get catalogRateLimit;

  /// No description provided for @catalogUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Anime data is currently unavailable.'**
  String get catalogUnavailable;

  /// No description provided for @catalogTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request is taking too long. Please try again.'**
  String get catalogTimeout;

  /// No description provided for @catalogOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Please check your internet.'**
  String get catalogOffline;

  /// No description provided for @catalogNoResponse.
  ///
  /// In en, this message translates to:
  /// **'The anime source is not responding. Please try again later.'**
  String get catalogNoResponse;

  /// No description provided for @catalogInvalid.
  ///
  /// In en, this message translates to:
  /// **'The anime source returned invalid data.'**
  String get catalogInvalid;

  /// No description provided for @localListError.
  ///
  /// In en, this message translates to:
  /// **'Your local watchlist could not be read.'**
  String get localListError;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync is unavailable. Your last saved list remains visible.'**
  String get syncError;

  /// No description provided for @dubsCreditHeading.
  ///
  /// In en, this message translates to:
  /// **'Dubs'**
  String get dubsCreditHeading;

  /// No description provided for @dubCredit.
  ///
  /// In en, this message translates to:
  /// **'Dub data © MyDubList – CC BY 4.0. AniApp uses entries backed by multiple sources or manual confirmation, filtered by title and selected language. Display labels have been translated. Missing entries mean unknown. Evidence that a dub exists does not confirm a provider or an episode release date.'**
  String get dubCredit;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License: CC BY 4.0'**
  String get license;

  /// No description provided for @reportDub.
  ///
  /// In en, this message translates to:
  /// **'Report incorrect dub information'**
  String get reportDub;

  /// No description provided for @kitsuInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional anime information: Kitsu'**
  String get kitsuInfo;

  /// No description provided for @kitsuAttribution.
  ///
  /// In en, this message translates to:
  /// **'Artwork, runtime, episode counts, original broadcast dates and trailers are from Kitsu where indicated. Titles are matched using their recorded MyAnimeList ID. These are not local streaming or dub release dates.'**
  String get kitsuAttribution;

  /// No description provided for @providerDescriptions.
  ///
  /// In en, this message translates to:
  /// **'Providers & descriptions'**
  String get providerDescriptions;

  /// No description provided for @justwatchCredit.
  ///
  /// In en, this message translates to:
  /// **'Streaming offers are from JustWatch via TMDb. Information applies to the displayed country and the matched film, series or season. Audio languages and future episode release dates are not inferred from it. Availability may change.'**
  String get justwatchCredit;

  /// No description provided for @idMapping.
  ///
  /// In en, this message translates to:
  /// **'ID mapping: Fribb / anime-lists'**
  String get idMapping;

  /// No description provided for @catalogCalendarNews.
  ///
  /// In en, this message translates to:
  /// **'Catalog, calendar & news'**
  String get catalogCalendarNews;

  /// No description provided for @catalogAttribution.
  ///
  /// In en, this message translates to:
  /// **'Anime catalog: MyAnimeList via Tenrai or the official API. Episode dates may also come from AniList if enabled for AniApp; each event names its source. Japanese broadcasts and local streaming or dub releases are separate facts.'**
  String get catalogAttribution;

  /// No description provided for @newsAttribution.
  ///
  /// In en, this message translates to:
  /// **'Provider dates: ADN and reviewed announcements, among others. News: Anime2You, AniNews, MyAnimeList and ADN News. The ADN scraper collects public article metadata and short previews. Original sources and fetch dates are shown with the content. Images belong to their rights holders.'**
  String get newsAttribution;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
