enum NotificationType {
  dhikr,
  ayah,
  duaa,
  hadith,
  reminder,
}

class NotificationContent {
  final String id;
  final NotificationType type;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final String? sourceLabel;
  final Map<String, dynamic> payload;

  const NotificationContent({
    required this.id,
    required this.type,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    this.sourceLabel,
    this.payload = const {},
  });
}
