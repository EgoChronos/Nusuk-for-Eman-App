/// Represents a Dhikr item
class Dhikr {
  final int id;
  final String category;     // morning, evening, afterPrayer, sleep, general
  final String textArabic;
  final String textEnglish;
  final String? reference;
  final int targetCount;      // How many times to repeat

  const Dhikr({
    required this.id,
    required this.category,
    required this.textArabic,
    required this.textEnglish,
    this.reference,
    this.targetCount = 33,
  });

  factory Dhikr.fromJson(Map<String, dynamic> json) {
    return Dhikr(
      id: json['id'] as int,
      category: json['category'] as String,
      textArabic: json['textArabic'] as String,
      textEnglish: json['textEnglish'] as String,
      reference: json['reference'] as String?,
      targetCount: json['targetCount'] as int? ?? 33,
    );
  }
}

/// Represents a dhikr category
class DhikrCategory {
  final String id;
  final String nameArabic;
  final String nameEnglish;
  final String icon;

  const DhikrCategory({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.icon,
  });
}
