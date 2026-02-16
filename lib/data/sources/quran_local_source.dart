import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/surah.dart';

/// Loads Qur'an data from bundled JSON asset
/// Supabase-ready: can be swapped with SupabaseQuranSource
class QuranLocalSource {
  List<Surah>? _cachedSurahs;

  Future<List<Surah>> loadSurahs() async {
    if (_cachedSurahs != null) return _cachedSurahs!;

    final String jsonString =
        await rootBundle.loadString('assets/data/quran.json');
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

    _cachedSurahs = jsonList
        .map((e) => Surah.fromJson(e as Map<String, dynamic>))
        .toList();

    return _cachedSurahs!;
  }

  Future<Surah> loadSurah(int number) async {
    final surahs = await loadSurahs();
    return surahs.firstWhere((s) => s.number == number);
  }

  void clearCache() {
    _cachedSurahs = null;
  }
}
