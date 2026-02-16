/// Represents a Hadith entry
class Hadith {
  final int id;
  final String category;       // patience, illness, death, mercy
  final String textArabic;
  final String textEnglish;
  final String source;         // e.g. "Sahih Muslim", "Sahih Bukhari"
  final String? narrator;

  const Hadith({
    required this.id,
    required this.category,
    required this.textArabic,
    required this.textEnglish,
    required this.source,
    this.narrator,
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      id: json['id'] as int,
      category: json['category'] as String,
      textArabic: json['textArabic'] as String,
      textEnglish: json['textEnglish'] as String,
      source: json['source'] as String,
      narrator: json['narrator'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'textArabic': textArabic,
    'textEnglish': textEnglish,
    'source': source,
    'narrator': narrator,
  };
}
