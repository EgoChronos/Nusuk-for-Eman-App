import '../models/surah.dart';
import '../sources/quran_local_source.dart';
import '../sources/hive_storage.dart';

/// Repository for Qur'an data and reading progress
/// Supabase-ready: add cloud sync methods here
class QuranRepository {
  final QuranLocalSource _localSource;
  final HiveStorage _storage;

  QuranRepository(this._localSource, this._storage);

  Future<List<Surah>> getSurahs() => _localSource.loadSurahs();

  Future<Surah> getSurah(int number) => _localSource.loadSurah(number);

  // Reading progress
  Map<String, dynamic>? getLastReadPosition() =>
      _storage.getLastReadPosition();

  Future<void> saveLastReadPosition(int surah, int ayah) =>
      _storage.saveLastReadPosition(surah, ayah);

  Set<int> getReadAyahs(int surahNumber) =>
      _storage.getReadAyahs(surahNumber);

  Future<void> markAyahRead(int surahNumber, int ayahNumber) =>
      _storage.markAyahRead(surahNumber, ayahNumber);

  int getTotalAyahsRead() => _storage.getTotalAyahsRead();

  // Bookmarks
  List<int> getBookmarkedSurahs() => _storage.getBookmarkedSurahs();

  Future<void> toggleBookmark(int surahNumber) =>
      _storage.toggleBookmark(surahNumber);

  bool isBookmarked(int surahNumber) =>
      _storage.getBookmarkedSurahs().contains(surahNumber);
}
