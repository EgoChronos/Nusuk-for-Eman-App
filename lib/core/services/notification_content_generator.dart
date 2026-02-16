import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../../data/models/notification_content.dart';
import '../../data/notification_data.dart';

class NotificationContentGenerator {
  static List<dynamic>? _quranData;

  /// Loads Quran JSON data if not already loaded
  static Future<void> _ensureQuranLoaded() async {
    if (_quranData != null) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/quran.json');
      _quranData = json.decode(jsonString);
    } catch (e) {
      // Fallback if asset missing
      _quranData = [];
    }
  }

  /// Returns a deterministic random index for the day
  /// Ensures users get different content each day, but the same content if they check 2x in a minute
  static int _getDaySeededRandom(int max, {int salt = 0}) {
    if (max <= 0) return 0;
    final now = DateTime.now();
    // Seed with Date + Time + Salt for maximum variety during testing and production
    // This ensures different slots in the same day (and different minutes of testing) get unique items
    final seed = (now.year * 1000000) + (now.month * 10000) + (now.day * 100) + 
                 (now.hour * 60) + now.minute + salt;
    return Random(seed).nextInt(max);
  }

  /// Get random Ayah
  static Future<NotificationContent> getRandomAyah({int salt = 0}) async {
    await _ensureQuranLoaded();
    
    if (_quranData == null || _quranData!.isEmpty) {
      return getRandomDhikr(category: 'general', salt: salt); // Fallback
    }

    // Pick a random surah, then random ayah
    // We strive for short, meaningful ayahs for notifications
    final surahIndex = _getDaySeededRandom(_quranData!.length, salt: salt);
    final surah = _quranData![surahIndex];
    final ayahs = surah['ayahs'] as List;
    
    // Pick ayah
    final ayahIndex = _getDaySeededRandom(ayahs.length, salt: salt + 1);
    final ayah = ayahs[ayahIndex];

    return NotificationContent(
      id: 'ayah_${surah['number']}_${ayah['number']}',
      type: NotificationType.ayah,
      titleAr: 'آية من القرآن الكريم',
      titleEn: 'Verse from the Holy Quran',
      bodyAr: '${ayah['text']} ﴿${surah['name']} : ${ayah['number']}﴾',
      bodyEn: '${surah['englishName']} (${ayah['number']})', // English text not in JSON, using name ref
      sourceLabel: '${surah['name']} - ${ayah['number']}',
      payload: {
        'surahNumber': surah['number'],
        'ayahNumber': ayah['number'],
      },
    );
  }

  /// Get random Dhikr from specific category
  static NotificationContent getRandomDhikr({String category = 'general', int salt = 0}) {
    final list = NotificationData.allDhikr.where((d) => d.category == category).toList();
    if (list.isEmpty) {
      // Fallback to general if empty
      return getRandomDhikr(category: 'general', salt: salt);
    }

    final index = _getDaySeededRandom(list.length, salt: salt);
    final item = list[index];

    return NotificationContent(
      id: 'dhikr_${item.id}',
      type: NotificationType.dhikr,
      titleAr: 'ذكر',
      titleEn: 'Dhikr',
      bodyAr: item.textArabic,
      bodyEn: item.textEnglish,
      sourceLabel: item.reference,
      payload: {
        'dhikrId': item.id,
      },
    );
  }

  /// Get random Hadith
  static NotificationContent getRandomHadith({int salt = 0}) {
    final list = NotificationData.allHadiths;
    final index = _getDaySeededRandom(list.length, salt: salt);
    final item = list[index];

    return NotificationContent(
      id: 'hadith_${item.id}',
      type: NotificationType.hadith,
      titleAr: 'حديث شريف',
      titleEn: 'Hadith',
      bodyAr: item.textArabic,
      bodyEn: item.textEnglish,
      sourceLabel: item.source,
      payload: {
        'hadithId': item.id,
      },
    );
  }

  /// Get random Duaa
  static NotificationContent getRandomDuaa({int salt = 0}) {
    final list = NotificationData.duaas;
    final index = _getDaySeededRandom(list.length, salt: salt);
    final item = list[index];

    return NotificationContent(
      id: 'duaa_$index',
      type: NotificationType.duaa,
      titleAr: 'دعاء',
      titleEn: 'Duaa',
      bodyAr: item['ar']!,
      bodyEn: item['en']!,
      sourceLabel: 'Duaa for Eman',
      payload: {
        'duaaIndex': index,
      },
    );
  }

  // Reminder templates
  static NotificationContent getReminder(String type) {
    switch (type) {
      case 'morning':
        return const NotificationContent(
          id: 'rem_morning',
          type: NotificationType.reminder,
          titleAr: 'أذكار الصباح',
          titleEn: 'Morning Adhkar',
          bodyAr: 'حان وقت أذكار الصباح، بداية يومك بذكر الله نور وبركة 🌅',
          bodyEn: 'Time for Morning Adhkar. Start your day with the remembrance of Allah.',
          payload: {'target': 'dhikr_morning'},
        );
      case 'evening':
        return const NotificationContent(
          id: 'rem_evening',
          type: NotificationType.reminder,
          titleAr: 'أذكار المساء',
          titleEn: 'Evening Adhkar',
          bodyAr: 'أمسينا وأمسى الملك لله. لا تنس أذكار المساء 🌙',
          bodyEn: 'We have reached the evening. Do not forget your Evening Adhkar.',
          payload: {'target': 'dhikr_evening'},
        );
      case 'sleep':
        return const NotificationContent(
          id: 'rem_sleep',
          type: NotificationType.reminder,
          titleAr: 'أذكار النوم',
          titleEn: 'Sleep Adhkar',
          bodyAr: 'باسمك ربي وضعت جنبي.. اختم يومك بذكر الله 😴',
          bodyEn: 'End your day with the remembrance of Allah before you sleep.',
          payload: {'target': 'dhikr_sleep'},
        );
      case 'morning_eman': // New specialized morning reminder
        return const NotificationContent(
          id: 'rem_morning_eman',
          type: NotificationType.duaa, // Set as Duaa type for action button logic
          titleAr: 'صباح الخير لإيمان 🌸',
          titleEn: 'Morning for Eman 🌸',
          bodyAr: 'لا تنسَ إطلاق يومك بالدعاء لإيمان.. اللهم اجعل يومها في الجنة أجمل.',
          bodyEn: 'Don\'t forget Eman in your day. May Allah make her day in Jannah even more beautiful.',
          payload: {'target': 'duaa'},
        );
      case 'kahf':
        return const NotificationContent(
          id: 'rem_kahf',
          type: NotificationType.reminder,
          titleAr: 'سورة الكهف',
          titleEn: 'Surah Al-Kahf',
          bodyAr: 'نور ما بين الجمعتين. لا تنس قراءة سورة الكهف 📖',
          bodyEn: 'Light between the two Fridays. Do not forget to read Surah Al-Kahf.',
          payload: {'target': 'quran_18'},
        );
      case 'duaa_eman':
        return const NotificationContent(
          id: 'rem_duaa_eman',
          type: NotificationType.duaa,
          titleAr: 'دعاء لإيمان 🤲',
          titleEn: 'Duaa for Eman 🤲',
          bodyAr: 'لا تنسَ الدعاء لإيمان محمد طايع بالرحمة والمغفرة.. اللهم اغفر لها وارحمها',
          bodyEn: 'Remember Eman Mohammed Tayee in your duaa. O Allah, forgive her and have mercy on her.',
          payload: {'target': 'duaa'},
        );
      default:
        return const NotificationContent(
          id: 'rem_general',
          type: NotificationType.reminder,
          titleAr: 'ذكر الله',
          titleEn: 'Remember Allah',
          bodyAr: 'ألا بذكر الله تطمئن القلوب ❤️',
          bodyEn: 'Verily, in the remembrance of Allah do hearts find rest.',
          payload: {'target': 'home'},
        );
    }
  }
}
