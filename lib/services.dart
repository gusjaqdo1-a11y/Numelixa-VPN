import 'dart:convert';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'models.dart';

class QuranService {
  Future<List<Surah>> load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/quran.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final surahs = ((json['data']?['surahs'] as List?) ?? const [])
          .map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList();
      if (surahs.length == 114) return surahs;
    } catch (_) {}
    final response = await http.get(Uri.parse('https://api.alquran.cloud/v1/quran/quran-uthmani'));
    if (response.statusCode != 200) throw Exception('Quran data unavailable');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ((json['data']?['surahs'] as List?) ?? const [])
        .map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class PrayerService {
  Future<Position?> location() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
  }

  List<PrayerEntry> calculate(double latitude, double longitude, DateTime date) {
    final coordinates = Coordinates(latitude, longitude);
    final params = CalculationMethodParameters.muslimWorldLeague()..madhab = Madhab.shafi;
    final times = PrayerTimes(coordinates: coordinates, date: date, calculationParameters: params, precision: true);
    return [
      PrayerEntry(name: 'Fajr', arabic: 'الفجر', time: times.fajr),
      PrayerEntry(name: 'Sunrise', arabic: 'الشروق', time: times.sunrise),
      PrayerEntry(name: 'Dhuhr', arabic: 'الظهر', time: times.dhuhr),
      PrayerEntry(name: 'Asr', arabic: 'العصر', time: times.asr),
      PrayerEntry(name: 'Maghrib', arabic: 'المغرب', time: times.maghrib),
      PrayerEntry(name: 'Isha', arabic: 'العشاء', time: times.isha),
    ];
  }
}

class AlarmService {
  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {}
    const settings = InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'));
    await plugin.initialize(settings: settings);
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    ready = true;
  }

  Future<void> schedulePrayer(PrayerEntry prayer) async {
    if (!ready || prayer.name == 'Sunrise') return;
    final now = tz.TZDateTime.now(tz.local);
    var date = tz.TZDateTime(tz.local, prayer.time.year, prayer.time.month, prayer.time.day, prayer.time.hour, prayer.time.minute);
    if (date.isBefore(now)) date = date.add(const Duration(days: 1));
    await plugin.zonedSchedule(
      id: prayer.name.hashCode.abs() % 100000,
      title: '${prayer.name} — وقت الصلاة',
      body: 'Waqtiga salaadda ${prayer.name} ayaa galay.',
      scheduledDate: date,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('prayer_times', 'Prayer Times', channelDescription: 'Prayer time alerts', importance: Importance.max, priority: Priority.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleAll(List<PrayerEntry> prayers) async {
    await plugin.cancelAll();
    for (final prayer in prayers) {
      await schedulePrayer(prayer);
    }
  }
}

class Preferences {
  static Future<void> saveLastAyah(int surah, int ayah) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('lastSurah', surah);
    await p.setInt('lastAyah', ayah);
  }

  static Future<(int, int)> lastAyah() async {
    final p = await SharedPreferences.getInstance();
    return (p.getInt('lastSurah') ?? 1, p.getInt('lastAyah') ?? 1);
  }
}
