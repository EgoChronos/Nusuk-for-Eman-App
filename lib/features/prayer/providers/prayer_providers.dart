import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import '../../../core/services/location_service.dart';
import '../../../core/providers.dart';
import '../../../../data/sources/hive_storage.dart';

// Service Providers
final locationServiceProvider = Provider((ref) => LocationService());
// prayerServiceProvider is removed as it's no longer used after the 'service' variable was removed from prayerTimesProvider.

// 1. Location State
final prayerLocationProvider = StateNotifierProvider<LocationNotifier, AsyncValue<Position>>((ref) {
  return LocationNotifier(ref.read(locationServiceProvider));
});

class LocationNotifier extends StateNotifier<AsyncValue<Position>> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(const AsyncValue.loading()) {
    refreshLocation();
  }

  Future<void> refreshLocation() async {
    state = const AsyncValue.loading();
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        state = AsyncValue.data(position);
      } else {
        state = const AsyncValue.error('locationError', StackTrace.empty);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// 2. Calculation Settings (From Hive)
// TODO: Connect to Hive later. For now, use defaults or in-memory state.
final calculationMethodProvider = StateNotifierProvider<CalculationMethodNotifier, CalculationMethod>((ref) {
  final storage = ref.watch(hiveStorageProvider);
  return CalculationMethodNotifier(storage, ref);
});

class CalculationMethodNotifier extends StateNotifier<CalculationMethod> {
  final HiveStorage _storage;
  final Ref _ref;
  CalculationMethodNotifier(this._storage, this._ref) 
      : super(CalculationMethod.values[_storage.getPrayerCalculationMethod()]);

  Future<void> setMethod(CalculationMethod method) async {
    await _storage.setPrayerCalculationMethod(method.index);
    state = method;
    _ref.read(notificationServiceProvider).reScheduleAll();
  }
}

final madhabProvider = StateNotifierProvider<MadhabNotifier, Madhab>((ref) {
  final storage = ref.watch(hiveStorageProvider);
  return MadhabNotifier(storage, ref);
});

class MadhabNotifier extends StateNotifier<Madhab> {
  final HiveStorage _storage;
  final Ref _ref;
  MadhabNotifier(this._storage, this._ref) 
      : super(Madhab.values[_storage.getPrayerMadhab()]);

  Future<void> setMadhab(Madhab madhab) async {
    await _storage.setPrayerMadhab(madhab.index);
    state = madhab;
    _ref.read(notificationServiceProvider).reScheduleAll();
  }
}

// 2.1 Notification Settings
final athanSoundProvider = StateNotifierProvider<AthanSoundNotifier, String>((ref) {
  final storage = ref.watch(hiveStorageProvider);
  return AthanSoundNotifier(storage, ref);
});

class AthanSoundNotifier extends StateNotifier<String> {
  final HiveStorage _storage;
  final Ref _ref;
  AthanSoundNotifier(this._storage, this._ref) : super(_storage.getAthanSound());

  Future<void> setSound(String sound) async {
    await _storage.setAthanSound(sound);
    state = sound;
    _ref.read(notificationServiceProvider).reScheduleAll();
  }
}

final prePrayerReminderProvider = StateNotifierProvider<PrePrayerReminderNotifier, int>((ref) {
  final storage = ref.watch(hiveStorageProvider);
  return PrePrayerReminderNotifier(storage, ref);
});

class PrePrayerReminderNotifier extends StateNotifier<int> {
  final HiveStorage _storage;
  final Ref _ref;
  PrePrayerReminderNotifier(this._storage, this._ref) : super(_storage.getPrePrayerReminderMinutes());

  Future<void> setMinutes(int minutes) async {
    await _storage.setPrePrayerReminderMinutes(minutes);
    state = minutes;
    _ref.read(notificationServiceProvider).reScheduleAll();
  }
}

final sunriseAlertProvider = StateNotifierProvider<SunriseAlertNotifier, bool>((ref) {
  final storage = ref.watch(hiveStorageProvider);
  return SunriseAlertNotifier(storage, ref);
});

class SunriseAlertNotifier extends StateNotifier<bool> {
  final HiveStorage _storage;
  final Ref _ref;
  SunriseAlertNotifier(this._storage, this._ref) : super(_storage.isSunriseAlertEnabled());

  Future<void> setEnabled(bool enabled) async {
    await _storage.setSunriseAlertEnabled(enabled);
    state = enabled;
    _ref.read(notificationServiceProvider).reScheduleAll();
  }
}


// 3. Computed Prayer Times
final prayerTimesProvider = Provider<AsyncValue<PrayerTimes>>((ref) {
  final locationAsync = ref.watch(prayerLocationProvider);
  final method = ref.watch(calculationMethodProvider);
  final madhab = ref.watch(madhabProvider);
  // final service = ref.watch(prayerServiceProvider); // Removed as per instruction

  return locationAsync.when(
    data: (position) {
      final coordinates = Coordinates(position.latitude, position.longitude);
      final params = method.getParameters();
      params.madhab = madhab;
      
      final date = DateComponents.from(DateTime.now());
      return AsyncValue.data(PrayerTimes(coordinates, date, params));
    },
    loading: () => const AsyncValue.loading(),
    error: (err, st) => AsyncValue.error(err, st),
  );
});

// 4. Next Prayer Provider
final nextPrayerProvider = Provider<AsyncValue<Prayer>>((ref) {
  final timesAsync = ref.watch(prayerTimesProvider);
  
  return timesAsync.when(
    data: (times) {
      final next = times.nextPrayer();
      if (next == Prayer.none) {
        // If all today's prayers passed, the next is tomorrow's Fajr
        return const AsyncValue.data(Prayer.fajr);
      }
      return AsyncValue.data(next);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, st) => AsyncValue.error(err, st),
  );
});

// A provider for tomorrow's prayer times (for nighttime countdown)
final tomorrowPrayerTimesProvider = Provider<AsyncValue<PrayerTimes>>((ref) {
  final locationAsync = ref.watch(prayerLocationProvider);
  final method = ref.watch(calculationMethodProvider);
  final madhab = ref.watch(madhabProvider);

  return locationAsync.when(
    data: (position) {
      final coordinates = Coordinates(position.latitude, position.longitude);
      final params = method.getParameters();
      params.madhab = madhab;
      
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final date = DateComponents.from(tomorrow);
      return AsyncValue.data(PrayerTimes(coordinates, date, params));
    },
    loading: () => const AsyncValue.loading(),
    error: (err, st) => AsyncValue.error(err, st),
  );
});
