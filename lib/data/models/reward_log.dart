/// Tracks user's deeds for the reward tracker
/// Supabase-ready: can sync to cloud with user ID
class RewardLog {
  int quranPagesRead;
  int dhikrCount;
  int duaaCount;
  int listeningMinutes;
  DateTime lastUpdated;

  RewardLog({
    this.quranPagesRead = 0,
    this.dhikrCount = 0,
    this.duaaCount = 0,
    this.listeningMinutes = 0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory RewardLog.fromJson(Map<String, dynamic> json) {
    return RewardLog(
      quranPagesRead: json['quranPagesRead'] as int? ?? 0,
      dhikrCount: json['dhikrCount'] as int? ?? 0,
      duaaCount: json['duaaCount'] as int? ?? 0,
      listeningMinutes: json['listeningMinutes'] as int? ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'quranPagesRead': quranPagesRead,
    'dhikrCount': dhikrCount,
    'duaaCount': duaaCount,
    'listeningMinutes': listeningMinutes,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  RewardLog copyWith({
    int? quranPagesRead,
    int? dhikrCount,
    int? duaaCount,
    int? listeningMinutes,
  }) {
    return RewardLog(
      quranPagesRead: quranPagesRead ?? this.quranPagesRead,
      dhikrCount: dhikrCount ?? this.dhikrCount,
      duaaCount: duaaCount ?? this.duaaCount,
      listeningMinutes: listeningMinutes ?? this.listeningMinutes,
    );
  }
}
