/// Represents a Surah in the Qur'an
class Surah {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String revelationType; // "Meccan" or "Medinan"
  final int ayahCount;
  final List<Ayah> ayahs;

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.revelationType,
    required this.ayahCount,
    this.ayahs = const [],
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] as int,
      nameArabic: json['name'] as String,
      nameEnglish: json['englishName'] as String,
      revelationType: json['revelationType'] as String? ?? 'Meccan',
      ayahCount: json['ayahCount'] as int? ??
          (json['ayahs'] as List?)?.length ?? 0,
      ayahs: (json['ayahs'] as List?)
              ?.asMap()
              .entries
              .map((e) => Ayah.fromJson(e.value as Map<String, dynamic>, e.key + 1))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'name': nameArabic,
    'englishName': nameEnglish,
    'revelationType': revelationType,
    'ayahCount': ayahCount,
    'ayahs': ayahs.map((a) => a.toJson()).toList(),
  };
}

/// Represents a single Ayah
class Ayah {
  final int numberInSurah;
  final String text;
  final int? juz;
  final int? page;

  const Ayah({
    required this.numberInSurah,
    required this.text,
    this.juz,
    this.page,
  });

  factory Ayah.fromJson(Map<String, dynamic> json, [int? index]) {
    return Ayah(
      numberInSurah: json['numberInSurah'] as int? ?? index ?? 1,
      text: json['text'] as String,
      juz: json['juz'] as int?,
      page: json['page'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'numberInSurah': numberInSurah,
    'text': text,
    'juz': juz,
    'page': page,
  };
}
