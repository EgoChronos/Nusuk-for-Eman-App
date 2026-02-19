import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../../debug_logger.dart';

class ScheduleManager {
  /// Schedules a one-shot alarm.
  /// 
  /// [id] matches the [callback] encoded ID requirement if needed.
  /// [alarmClock] is true by default for precision.
  Future<void> scheduleOneShot({
    required DateTime time,
    required int id,
    required Function callback,
    bool alarmClock = true,
    bool wakeup = true,
    bool rescheduleOnReboot = true,
  }) async {
    DebugLogger.log('ScheduleManager: Scheduling one-shot id=$id at $time');
    await AndroidAlarmManager.oneShotAt(
      time,
      id,
      callback,
      exact: true,
      wakeup: wakeup,
      alarmClock: alarmClock,
      rescheduleOnReboot: rescheduleOnReboot,
    );
  }

  /// Cancel a specific alarm schedule
  Future<void> cancel(int id) async {
    await AndroidAlarmManager.cancel(id);
  }
}
