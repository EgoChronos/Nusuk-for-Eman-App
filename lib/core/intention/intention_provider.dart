import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Intention types for dedicating deeds
enum IntentionType {
  forHer,       // Sadaqah for إيمان محمد طايع (default)
  forAllDeceased, // For all deceased Muslims
  forSelf,      // For self
  general,      // General remembrance (no specific dedication)
}

/// Manages the user's intention state
/// Supabase-ready: this provider can be extended to sync intention to cloud
class IntentionNotifier extends StateNotifier<IntentionType> {
  final Box _settingsBox;

  IntentionNotifier(this._settingsBox)
      : super(_loadInitial(_settingsBox));

  static IntentionType _loadInitial(Box box) {
    final saved = box.get('intention', defaultValue: 'forHer');
    return IntentionType.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => IntentionType.forHer,
    );
  }

  void setIntention(IntentionType type) {
    state = type;
    _settingsBox.put('intention', type.name);
  }

  Future<void> confirmIntention() async {
    await _settingsBox.put('has_confirmed_intention', true);
  }

  bool get isFirstLaunch => !_settingsBox.containsKey('intention');
  bool get hasConfirmedIntention => _settingsBox.get('has_confirmed_intention', defaultValue: false);

  String getDedicationText({bool arabic = true}) {
    switch (state) {
      case IntentionType.forHer:
        return arabic
            ? '🤍 هذا العمل صدقة لروح إيمان محمد طايع'
            : '🤍 This deed is gifted to Eman Mohammed Tayee';
      case IntentionType.forAllDeceased:
        return arabic
            ? '🤍 لجميع أموات المسلمين'
            : '🤍 For all deceased Muslims';
      case IntentionType.forSelf:
        return '';
      case IntentionType.general:
        return arabic
            ? '🤍 ذكر الله'
            : '🤍 Remembrance of Allah';
    }
  }
}

/// Provider for intention state
/// Supabase-ready: wrap with AsyncNotifierProvider for cloud sync
final intentionProvider =
    StateNotifierProvider<IntentionNotifier, IntentionType>((ref) {
  throw UnimplementedError('Must be overridden with settingsBox');
});
