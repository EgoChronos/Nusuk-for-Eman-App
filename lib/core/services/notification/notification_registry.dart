
import 'scheduling/schedule_manager.dart';
import '../../../../data/sources/hive_storage.dart';

abstract class NotificationScheduleProvider {
  /// Unique identifier for this provider
  String get id;
  
  /// Returns a list of tasks to be scheduled.
  /// This method is called when we need to reschedule everything (app init, reboot, settings change).
  Future<void> schedule(ScheduleManager manager, HiveStorage storage);
}

class NotificationRegistry {
  final List<NotificationScheduleProvider> _providers = [];
  final ScheduleManager _scheduleManager;
  final HiveStorage _storage;

  NotificationRegistry(this._scheduleManager, this._storage);

  void register(NotificationScheduleProvider provider) {
    _providers.add(provider);
  }

  Future<void> rescheduleAll() async {
    for (final provider in _providers) {
      await provider.schedule(_scheduleManager, _storage);
    }
  }
}
