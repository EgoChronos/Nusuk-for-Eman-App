import 'package:hive_flutter/hive_flutter.dart';
import '../models/reward_log.dart';

/// Hive-based local storage
/// Supabase-ready: implement a SupabaseStorage with same interface to swap
class HiveStorage {
  static const String _settingsBox = 'settings';
  static const String _progressBox = 'progress';
  static const String _bookmarksBox = 'bookmarks';
  static const String _downloadsBox = 'downloads';

  late Box settingsBox;
  late Box progressBox;
  late Box bookmarksBox;
  late Box downloadsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    settingsBox = await Hive.openBox(_settingsBox);
    progressBox = await Hive.openBox(_progressBox);
    bookmarksBox = await Hive.openBox(_bookmarksBox);
    downloadsBox = await Hive.openBox(_downloadsBox);
  }

  // ── Downloads ─────────────────────────────────────────
  String? getDownloadedPath(String reciterId, int surahNumber) {
    return downloadsBox.get('${reciterId}_$surahNumber');
  }

  Future<void> saveDownloadPath(String reciterId, int surahNumber, String path) =>
      downloadsBox.put('${reciterId}_$surahNumber', path);

  bool isDownloaded(String reciterId, int surahNumber) =>
      downloadsBox.containsKey('${reciterId}_$surahNumber');

  Future<void> removeDownload(String reciterId, int surahNumber) =>
      downloadsBox.delete('${reciterId}_$surahNumber');

  // ── Settings ──────────────────────────────────────────
  bool get isFirstLaunch => !settingsBox.containsKey('intention');
  bool get hasConfirmedIntention => settingsBox.get('has_confirmed_intention', defaultValue: false);

  String getLanguage() => settingsBox.get('language', defaultValue: 'ar');
  Future<void> setLanguage(String lang) => settingsBox.put('language', lang);

  double getFontSize() =>
      (settingsBox.get('fontSize', defaultValue: 28.0) as num).toDouble();
  Future<void> setFontSize(double size) => settingsBox.put('fontSize', size);

  bool isDarkMode() => settingsBox.get('darkMode', defaultValue: false);
  Future<void> setDarkMode(bool dark) => settingsBox.put('darkMode', dark);

  // ── Navigation ────────────────────────────────────────
  String? getPendingNavigation() => settingsBox.get('pending_navigation');
  Future<void> setPendingNavigation(String? route) => settingsBox.put('pending_navigation', route);

  // ── Reading Progress ──────────────────────────────────
  Map<String, dynamic>? getLastReadPosition() {
    final data = progressBox.get('lastRead');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> saveLastReadPosition(int surahNumber, int ayahNumber) =>
      progressBox.put('lastRead', {
        'surah': surahNumber,
        'ayah': ayahNumber,
        'timestamp': DateTime.now().toIso8601String(),
      });

  // ── Bookmarks ─────────────────────────────────────────
  List<int> getBookmarkedSurahs() {
    // We now store String keys for ayah bookmarks, so we must filter for int keys
    return bookmarksBox.keys.whereType<int>().toList();
  }

  bool isBookmarked(int surahNumber) {
    return bookmarksBox.containsKey(surahNumber);
  }

  Future<void> toggleBookmark(int surahNumber) async {
    if (bookmarksBox.containsKey(surahNumber)) {
      await bookmarksBox.delete(surahNumber);
    } else {
      await bookmarksBox.put(surahNumber, true);
    }
  }

  // ── Khatma Progress ───────────────────────────────────
  Set<int> getReadAyahs(int surahNumber) {
    final data = progressBox.get('read_$surahNumber');
    if (data == null) return {};
    return Set<int>.from(data as List);
  }

  Future<void> markAyahRead(int surahNumber, int ayahNumber) async {
    final read = getReadAyahs(surahNumber);
    if (!read.contains(ayahNumber)) {
      read.add(ayahNumber);
      await progressBox.put('read_$surahNumber', read.toList());
      await incrementTotalAyahLifeCount(1);
    }
  }

  Future<void> markAyahRangeRead(int surahNumber, int start, int end) async {
    final read = getReadAyahs(surahNumber);
    int newlyRead = 0;
    for (int i = start; i <= end; i++) {
      if (!read.contains(i)) {
        read.add(i);
        newlyRead++;
      }
    }
    if (newlyRead > 0) {
      await progressBox.put('read_$surahNumber', read.toList());
      await incrementTotalAyahLifeCount(newlyRead);
    }
  }

  // ── Ayah Bookmarks ────────────────────────────────────
  // Stored as 'ayah_bookmarks_$surah' -> List<int>
  Set<int> getBookmarkedAyahs(int surahNumber) {
    final data = bookmarksBox.get('ayah_bookmarks_$surahNumber');
    if (data == null) return {};
    return Set<int>.from(data as List);
  }

  bool isAyahBookmarked(int surahNumber, int ayahNumber) {
    return getBookmarkedAyahs(surahNumber).contains(ayahNumber);
  }

  Future<void> toggleAyahBookmark(int surahNumber, int ayahNumber) async {
    final bookmarks = getBookmarkedAyahs(surahNumber);
    if (bookmarks.contains(ayahNumber)) {
      bookmarks.remove(ayahNumber);
    } else {
      bookmarks.add(ayahNumber);
    }
    await bookmarksBox.put('ayah_bookmarks_$surahNumber', bookmarks.toList());
  }
  
  // REMOVED: Hijri months are no longer tracked for reset purposes.

  // --- Prayer Settings ---
  int getPrayerCalculationMethod() => 
      settingsBox.get('prayerCalcMethod', defaultValue: 3); // 3 = Muslim World League

  Future<void> setPrayerCalculationMethod(int index) => 
      settingsBox.put('prayerCalcMethod', index);

  int getPrayerMadhab() => 
      settingsBox.get('prayerMadhab', defaultValue: 1); // 1 = Shafi (includes Maliki, Hanbali)

  Future<void> setPrayerMadhab(int index) => 
      settingsBox.put('prayerMadhab', index);

  // --- Hijri reset check (Legacy/Cleanup) ---
  /// Global lifetime ayah total — never reset by monthly Hijri reset
  int getTotalAyahLifeCount() =>
      settingsBox.get('totalAyahsRead', defaultValue: 0);

  Future<void> incrementTotalAyahLifeCount(int count) async {
    final current = getTotalAyahLifeCount();
    await settingsBox.put('totalAyahsRead', current + count);
    await addPendingSync(ayahs: count);
  }

  int getTotalAyahsRead() {
    int total = 0;
    for (int i = 1; i <= 114; i++) {
      total += getReadAyahs(i).length;
    }
    return total;
  }

  // ── Reward Log ────────────────────────────────────────
  RewardLog getRewardLog() {
    final data = progressBox.get('rewardLog');
    if (data == null) return RewardLog();
    return RewardLog.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> saveRewardLog(RewardLog log) =>
      progressBox.put('rewardLog', log.toJson());

  // ── Dhikr Counter ─────────────────────────────────────
  int getDhikrCount(String dhikrId) =>
      progressBox.get('dhikr_$dhikrId', defaultValue: 0);

  Future<void> setDhikrCount(String dhikrId, int count) =>
      progressBox.put('dhikr_$dhikrId', count);

  /// Global lifetime dhikr total — never reset by daily auto-reset
  int getTotalDhikrCount() =>
      progressBox.get('dhikr_total', defaultValue: 0);

  Future<void> incrementTotalDhikr() async {
    final current = getTotalDhikrCount();
    await progressBox.put('dhikr_total', current + 1);
    await addPendingSync(dhikr: 1);
  }

  /// Clear per-item dhikr counts (daily reset). Preserves dhikr_total & tasbeeh_total.
  Future<void> clearAllDhikrCounts() async {
    final keysToDelete = progressBox.keys
        .where((k) {
          final key = k.toString();
          return key.startsWith('dhikr_') && key != 'dhikr_total';
        })
        .toList();
    for (final key in keysToDelete) {
      await progressBox.delete(key);
    }
  }

  int getTasbeehCount() =>
      progressBox.get('tasbeeh_total', defaultValue: 0);

  Future<void> incrementTasbeeh() async {
    final current = getTasbeehCount();
    await progressBox.put('tasbeeh_total', current + 1);
    await addPendingSync(dhikr: 1);
  }

  int getTotalDhikrAllTime() {
    return getTotalDhikrCount() + getTasbeehCount();
  }

  // ── Duaa Counter ──────────────────────────────────────
  int getDuaaCount() =>
      progressBox.get('duaa_total', defaultValue: 0);

  int getDuaaCountToday() {
    final lastDate = progressBox.get('duaa_last_date', defaultValue: '');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastDate != today) return 0;
    return progressBox.get('duaa_today', defaultValue: 0);
  }

  Future<void> incrementDuaa() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = progressBox.get('duaa_last_date', defaultValue: '');

    if (lastDate != today) {
      await progressBox.put('duaa_today', 1);
      await progressBox.put('duaa_last_date', today);
    } else {
      final current = progressBox.get('duaa_today', defaultValue: 0) as int;
      await progressBox.put('duaa_today', current + 1);
    }

    final total = getDuaaCount();
    await progressBox.put('duaa_total', total + 1);
    await addPendingSync(duaa: 1);
  }

  // ── Audio Progress ────────────────────────────────────
  Map<String, dynamic>? getLastAudioPosition() {
    final data = progressBox.get('lastAudio');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> saveLastAudioPosition(
    String reciterId,
    int surahNumber,
    int positionMs,
  ) => progressBox.put('lastAudio', {
    'reciter': reciterId,
    'surah': surahNumber,
    'position': positionMs,
    'timestamp': DateTime.now().toIso8601String(),
  });

  int getListeningSeconds() {
    // Migrate from old 'listening_minutes' key if it exists
    final oldMinutes = progressBox.get('listening_minutes');
    if (oldMinutes != null && oldMinutes is int && oldMinutes > 0) {
      final migrated = (progressBox.get('listening_seconds', defaultValue: 0) as int) + oldMinutes * 60;
      progressBox.put('listening_seconds', migrated);
      progressBox.delete('listening_minutes');
      return migrated;
    }
    return progressBox.get('listening_seconds', defaultValue: 0);
  }

  Future<void> addListeningSeconds(int seconds) async {
    final current = getListeningSeconds();
    await progressBox.put('listening_seconds', current + seconds);
  }

  // ── Pending Sync Queue (offline increments) ─────────
  Future<void> addPendingSync({int ayahs = 0, int dhikr = 0, int seconds = 0, int duaa = 0}) async {
    if (ayahs > 0) {
      final cur = progressBox.get('pending_ayahs', defaultValue: 0) as int;
      await progressBox.put('pending_ayahs', cur + ayahs);
    }
    if (dhikr > 0) {
      final cur = progressBox.get('pending_dhikr', defaultValue: 0) as int;
      await progressBox.put('pending_dhikr', cur + dhikr);
    }
    if (seconds > 0) {
      final cur = progressBox.get('pending_seconds', defaultValue: 0) as int;
      await progressBox.put('pending_seconds', cur + seconds);
    }
    if (duaa > 0) {
      final cur = progressBox.get('pending_duaa', defaultValue: 0) as int;
      await progressBox.put('pending_duaa', cur + duaa);
    }
  }

  Map<String, int> getPendingSync() {
    return {
      'ayahs': progressBox.get('pending_ayahs', defaultValue: 0) as int,
      'dhikr': progressBox.get('pending_dhikr', defaultValue: 0) as int,
      'seconds': progressBox.get('pending_seconds', defaultValue: 0) as int,
      'duaa': progressBox.get('pending_duaa', defaultValue: 0) as int,
    };
  }

  bool hasPendingSync() {
    final p = getPendingSync();
    return p['ayahs']! > 0 || p['dhikr']! > 0 || p['seconds']! > 0 || p['duaa']! > 0;
  }

  Future<void> clearPendingSync() async {
    await progressBox.put('pending_ayahs', 0);
    await progressBox.put('pending_dhikr', 0);
    await progressBox.put('pending_seconds', 0);
    await progressBox.put('pending_duaa', 0);
  }

  // ── Cached Global Stats (last-known snapshot) ──────
  Future<void> cacheGlobalStats(Map<String, dynamic> data) async {
    await settingsBox.put('cached_global_ayahs', data['ayahs_read'] ?? 0);
    await settingsBox.put('cached_global_dhikr', data['dhikr_count'] ?? 0);
    await settingsBox.put('cached_global_seconds', data['listening_seconds'] ?? 0);
    await settingsBox.put('cached_global_duaa', data['duaa_count'] ?? 0);
  }

  Map<String, dynamic>? getCachedGlobalStats() {
    if (!settingsBox.containsKey('cached_global_ayahs')) return null;
    return {
      'ayahs_read': settingsBox.get('cached_global_ayahs', defaultValue: 0),
      'dhikr_count': settingsBox.get('cached_global_dhikr', defaultValue: 0),
      'listening_seconds': settingsBox.get('cached_global_seconds', defaultValue: 0),
      'duaa_count': settingsBox.get('cached_global_duaa', defaultValue: 0),
    };
  }

  // ── Reset ─────────────────────────────────────────────
  Future<void> resetReadingProgress() async {
    // Clear all reading progress but keep bookmarks/settings
    // We iterate keys? Or just clear specific keys if we knew them.
    // Since we use 'read_$surahNumber', we can iterate 1-114.
    for (int i = 1; i <= 114; i++) {
        await progressBox.delete('read_$i');
    }
    await progressBox.delete('lastRead');
    // Keep rewardLog and others? "mark shall be auto resets" implies reading marks.
    // "Reward" is lifetime? "Every good deed here is gifted".
    // I'll keep rewardLog.
  }

  Future<void> resetAllProgress() async {
    await progressBox.clear();
    await bookmarksBox.clear();
  }

  // ── Dhikr Reset ───────────────────────────────────────
  int? getLastDhikrResetDay() {
    return settingsBox.get('last_dhikr_reset_day');
  }

  Future<void> setLastDhikrResetDay(int day) async {
    await settingsBox.put('last_dhikr_reset_day', day);
  }
  // ── Notifications ──────────────────────────────────────────────────────────

  Map<String, dynamic> getNotificationSettings() {
    return {
      'enabled': settingsBox.get('notif_enabled', defaultValue: true),
      'morning': settingsBox.get('notif_morning', defaultValue: true),
      'evening': settingsBox.get('notif_evening', defaultValue: true),
      'sleep': settingsBox.get('notif_sleep', defaultValue: true),
      'kahf': settingsBox.get('notif_kahf', defaultValue: true),
      'floating': settingsBox.get('notif_floating', defaultValue: true), // Content
      'frequency': settingsBox.get('notif_frequency', defaultValue: 'medium'),
    };
  }

  Future<void> setNotificationSetting(String key, bool value) async {
    await settingsBox.put('notif_$key', value);
  }
  
  Future<void> setNotificationFrequency(String frequency) async {
    await settingsBox.put('notif_frequency', frequency);
  }

  Future<void> setConfirmedIntention(bool confirmed) async {
    await settingsBox.put('has_confirmed_intention', confirmed);
  }

  // --- Prayer Notification Settings ---
  String getAthanSound() => 
      settingsBox.get('prayerAthanSound', defaultValue: 'athan_aqsa');

  Future<void> setAthanSound(String sound) => 
      settingsBox.put('prayerAthanSound', sound);

  int getPrePrayerReminderMinutes() => 
      settingsBox.get('prayerPreReminder', defaultValue: 0); // 0 = Off

  Future<void> setPrePrayerReminderMinutes(int minutes) => 
      settingsBox.put('prayerPreReminder', minutes);

  bool isSunriseAlertEnabled() => 
      settingsBox.get('prayerSunriseAlert', defaultValue: true);

  Future<void> setSunriseAlertEnabled(bool enabled) => 
      settingsBox.put('prayerSunriseAlert', enabled);
}
