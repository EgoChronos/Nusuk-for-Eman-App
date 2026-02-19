import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

class PrayerService {
  PrayerTimes? getPrayerTimes({
    required Position position,
    CalculationMethod method = CalculationMethod.muslim_world_league,
    Madhab madhab = Madhab.shafi,
    DateTime? date,
  }) {
    final myCoordinates = Coordinates(position.latitude, position.longitude);
    final params = method.getParameters();
    params.madhab = madhab;
    
    final DateComponents dateComponents = DateComponents.from(date ?? DateTime.now());

    return PrayerTimes(myCoordinates, dateComponents, params);
  }

  // Helper to get next prayer
  Prayer? getNextPrayer(PrayerTimes times) {
    return times.nextPrayer();
  }
  
  // Helper to get time for a specific prayer
  DateTime? getTimeForPrayer(PrayerTimes times, Prayer prayer) {
    return times.timeForPrayer(prayer);
  }
}
