// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Nusuk for Eman';

  @override
  String get homeTitle => 'Home';

  @override
  String get quranTitle => 'Qur\'an';

  @override
  String get audioTitle => 'Listen to Qur\'an';

  @override
  String get dhikrTitle => 'Dhikr';

  @override
  String get hadithTitle => 'Hadith';

  @override
  String get duaaTitle => 'Duaa';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get continueReading => 'Continue Reading';

  @override
  String get listenFullQuran => 'Listen Full Qur\'an';

  @override
  String get todaysDhikr => 'Today\'s Dhikr';

  @override
  String get makeDuaa => 'Make Duaa';

  @override
  String get giftedToSoul => 'This deed is gifted to Eman Mohammed Tayee';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get aboutApp => 'About App';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get enableNotificationsDesc => 'Turn on/off all notifications';

  @override
  String get remindersSection => 'Reminders';

  @override
  String get morningAdhkar => 'Morning Adhkar';

  @override
  String get eveningAdhkar => 'Evening Adhkar';

  @override
  String get sleepAdhkar => 'Sleep Adhkar';

  @override
  String get surahKahf => 'Surah Al-Kahf';

  @override
  String get inspirationsSection => 'Inspirations';

  @override
  String get floatingContent => 'Floating Content';

  @override
  String get floatingContentDesc =>
      'Random Verses, Hadiths, and Duaas throughout the day';

  @override
  String get frequency => 'Frequency';

  @override
  String get freqLow => 'Low';

  @override
  String get freqMedium => 'Medium';

  @override
  String get freqHigh => 'High';

  @override
  String get resetProgress => 'Reset Progress';

  @override
  String get resetProgressDesc => 'Clear all counters and bookmarks';

  @override
  String get resetConfirmTitle => 'Reset Progress?';

  @override
  String get resetConfirmContent =>
      'This will clear all reading progress, bookmarks, and counters. This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get themeTitle => 'Appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeDesc => 'Use dark theme';

  @override
  String get languageTitle => 'Language';

  @override
  String get fontSizeTitle => 'Font Size';

  @override
  String get manageNotifications => 'Manage Notifications';

  @override
  String get manageNotificationsDesc => 'Configure reminders & content';

  @override
  String get myStats => 'My Lifetime Stats';

  @override
  String get ayahsRead => 'Ayahs Read';

  @override
  String get dhikrTasbeeh => 'Dhikr & Tasbeeh';

  @override
  String get duaasMade => 'Duaas Made';

  @override
  String get listeningTime => 'Listening Time';

  @override
  String get privacy => 'Privacy';

  @override
  String get surahsTab => 'Surahs';

  @override
  String get bookmarksTab => 'Bookmarks';

  @override
  String ayahCountLabel(int count) {
    return '$count ayahs read';
  }

  @override
  String get khatmaProgress => 'Khatma progress';

  @override
  String get newKhatma => 'New Khatma';

  @override
  String get khatmaResetNote =>
      'Reading progress resets at the start of each Hijri month';

  @override
  String get searchQuranHint => 'Search for Surah or Ayah...';

  @override
  String get noBookmarksYet => 'No bookmarks yet';

  @override
  String get markSurahRead => 'Mark entire surah as read';

  @override
  String get alreadyFullyRead => 'Already fully read';

  @override
  String get lovedByEman => 'Loved by Eman';

  @override
  String get continueFromLeftOff => 'Continue from where you left off';

  @override
  String tasbeehToday(int count) {
    return '$count tasbeeh today';
  }

  @override
  String get globalImpact => 'Global Impact';

  @override
  String get liveUpdatesDesc => 'Live updates from all users around the world';

  @override
  String get lastSavedUpdate => 'Last saved update';

  @override
  String get statQuran => 'Qur\'an';

  @override
  String ayahNumberHeader(int count) {
    return 'Ayah $count';
  }

  @override
  String get markAsRead => 'Mark as Read';

  @override
  String get alreadyRead => 'Already Read';

  @override
  String get bookmarkAyah => 'Bookmark Ayah';

  @override
  String get removeBookmark => 'Remove Bookmark';

  @override
  String get readUntilHere => 'Read until here';

  @override
  String get markPreviousAsRead => 'Mark all previous ayahs as read';

  @override
  String get surahMarkedRead => 'Surah marked as fully read';

  @override
  String get permissionSetupTitle => 'Run Settings';

  @override
  String get permissionSetupDesc =>
      'To ensure reminders and content arrive on time, please enable the following permissions:';

  @override
  String get overlayPermissionTitle => 'Display over other apps';

  @override
  String get overlayPermissionDesc =>
      'Allows the floating window to appear on screen.';

  @override
  String get batteryPermissionTitle => 'Ignore battery restrictions';

  @override
  String get batteryPermissionDesc =>
      'To allow the app to run in the background for reliable notifications';

  @override
  String get appearancePermissionTitle => 'Notification appearance';

  @override
  String get appearancePermissionDesc =>
      'Enable \"Background pop-ups\" and \"Show on lock screen\" for best performance.';

  @override
  String get allPermissionsGranted => 'Great! All permissions are now granted';

  @override
  String permissionBannerAlert(int count) {
    return 'Alert: Setup incomplete ($count/3) ←';
  }

  @override
  String get runSettings => 'Run Settings';

  @override
  String get runSettingsDesc => 'To ensure notifications arrive on time';
}
