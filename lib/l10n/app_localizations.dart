import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Nusuk for Eman'**
  String get appName;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @quranTitle.
  ///
  /// In en, this message translates to:
  /// **'Qur\'an'**
  String get quranTitle;

  /// No description provided for @audioTitle.
  ///
  /// In en, this message translates to:
  /// **'Listen to Qur\'an'**
  String get audioTitle;

  /// No description provided for @dhikrTitle.
  ///
  /// In en, this message translates to:
  /// **'Dhikr'**
  String get dhikrTitle;

  /// No description provided for @hadithTitle.
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get hadithTitle;

  /// No description provided for @duaaTitle.
  ///
  /// In en, this message translates to:
  /// **'Duaa'**
  String get duaaTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueReading;

  /// No description provided for @listenFullQuran.
  ///
  /// In en, this message translates to:
  /// **'Listen Full Qur\'an'**
  String get listenFullQuran;

  /// No description provided for @todaysDhikr.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Dhikr'**
  String get todaysDhikr;

  /// No description provided for @makeDuaa.
  ///
  /// In en, this message translates to:
  /// **'Make Duaa'**
  String get makeDuaa;

  /// No description provided for @giftedToSoul.
  ///
  /// In en, this message translates to:
  /// **'This deed is gifted to Eman Mohammed Tayee'**
  String get giftedToSoul;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @enableNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Turn on/off all notifications'**
  String get enableNotificationsDesc;

  /// No description provided for @remindersSection.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersSection;

  /// No description provided for @morningAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Morning Adhkar'**
  String get morningAdhkar;

  /// No description provided for @eveningAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Evening Adhkar'**
  String get eveningAdhkar;

  /// No description provided for @sleepAdhkar.
  ///
  /// In en, this message translates to:
  /// **'Sleep Adhkar'**
  String get sleepAdhkar;

  /// No description provided for @surahKahf.
  ///
  /// In en, this message translates to:
  /// **'Surah Al-Kahf'**
  String get surahKahf;

  /// No description provided for @inspirationsSection.
  ///
  /// In en, this message translates to:
  /// **'Inspirations'**
  String get inspirationsSection;

  /// No description provided for @floatingContent.
  ///
  /// In en, this message translates to:
  /// **'Floating Content'**
  String get floatingContent;

  /// No description provided for @floatingContentDesc.
  ///
  /// In en, this message translates to:
  /// **'Random Verses, Hadiths, and Duaas throughout the day'**
  String get floatingContentDesc;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @freqLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get freqLow;

  /// No description provided for @freqMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get freqMedium;

  /// No description provided for @freqHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get freqHigh;

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset Progress'**
  String get resetProgress;

  /// No description provided for @resetProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear all counters and bookmarks'**
  String get resetProgressDesc;

  /// No description provided for @resetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Progress?'**
  String get resetConfirmTitle;

  /// No description provided for @resetConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This will clear all reading progress, bookmarks, and counters. This cannot be undone.'**
  String get resetConfirmContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themeTitle;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get darkModeDesc;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @fontSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSizeTitle;

  /// No description provided for @manageNotifications.
  ///
  /// In en, this message translates to:
  /// **'Manage Notifications'**
  String get manageNotifications;

  /// No description provided for @manageNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Configure reminders & content'**
  String get manageNotificationsDesc;

  /// No description provided for @myStats.
  ///
  /// In en, this message translates to:
  /// **'My Lifetime Stats'**
  String get myStats;

  /// No description provided for @ayahsRead.
  ///
  /// In en, this message translates to:
  /// **'Ayahs Read'**
  String get ayahsRead;

  /// No description provided for @dhikrTasbeeh.
  ///
  /// In en, this message translates to:
  /// **'Dhikr & Tasbeeh'**
  String get dhikrTasbeeh;

  /// No description provided for @duaasMade.
  ///
  /// In en, this message translates to:
  /// **'Duaas Made'**
  String get duaasMade;

  /// No description provided for @listeningTime.
  ///
  /// In en, this message translates to:
  /// **'Listening Time'**
  String get listeningTime;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @surahsTab.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get surahsTab;

  /// No description provided for @bookmarksTab.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarksTab;

  /// No description provided for @ayahCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs read'**
  String ayahCountLabel(int count);

  /// No description provided for @khatmaProgress.
  ///
  /// In en, this message translates to:
  /// **'Khatma progress'**
  String get khatmaProgress;

  /// No description provided for @newKhatma.
  ///
  /// In en, this message translates to:
  /// **'New Khatma'**
  String get newKhatma;

  /// No description provided for @khatmaResetNote.
  ///
  /// In en, this message translates to:
  /// **'Reading progress resets at the start of each Hijri month'**
  String get khatmaResetNote;

  /// No description provided for @searchQuranHint.
  ///
  /// In en, this message translates to:
  /// **'Search for Surah or Ayah...'**
  String get searchQuranHint;

  /// No description provided for @noBookmarksYet.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarksYet;

  /// No description provided for @markSurahRead.
  ///
  /// In en, this message translates to:
  /// **'Mark entire surah as read'**
  String get markSurahRead;

  /// No description provided for @alreadyFullyRead.
  ///
  /// In en, this message translates to:
  /// **'Already fully read'**
  String get alreadyFullyRead;

  /// No description provided for @lovedByEman.
  ///
  /// In en, this message translates to:
  /// **'Loved by Eman'**
  String get lovedByEman;

  /// No description provided for @continueFromLeftOff.
  ///
  /// In en, this message translates to:
  /// **'Continue from where you left off'**
  String get continueFromLeftOff;

  /// No description provided for @tasbeehToday.
  ///
  /// In en, this message translates to:
  /// **'{count} tasbeeh today'**
  String tasbeehToday(int count);

  /// No description provided for @globalImpact.
  ///
  /// In en, this message translates to:
  /// **'Global Impact'**
  String get globalImpact;

  /// No description provided for @liveUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Live updates from all users around the world'**
  String get liveUpdatesDesc;

  /// No description provided for @lastSavedUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last saved update'**
  String get lastSavedUpdate;

  /// No description provided for @statQuran.
  ///
  /// In en, this message translates to:
  /// **'Qur\'an'**
  String get statQuran;

  /// No description provided for @ayahNumberHeader.
  ///
  /// In en, this message translates to:
  /// **'Ayah {count}'**
  String ayahNumberHeader(int count);

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// No description provided for @alreadyRead.
  ///
  /// In en, this message translates to:
  /// **'Already Read'**
  String get alreadyRead;

  /// No description provided for @bookmarkAyah.
  ///
  /// In en, this message translates to:
  /// **'Bookmark Ayah'**
  String get bookmarkAyah;

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove Bookmark'**
  String get removeBookmark;

  /// No description provided for @readUntilHere.
  ///
  /// In en, this message translates to:
  /// **'Read until here'**
  String get readUntilHere;

  /// No description provided for @markPreviousAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all previous ayahs as read'**
  String get markPreviousAsRead;

  /// No description provided for @surahMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'Surah marked as fully read'**
  String get surahMarkedRead;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
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
