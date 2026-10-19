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
  static const _url = 'https://api.alquran.cloud/v1/quran/quran-uthmani';

  List<Surah> _parse(dynamic body) {
    final root = body is String ? jsonDecode(body) : body;
    final list = (root is Map ? root['data']?['surahs'] : null) as List?;
    if (list == null || list.length != 114) throw const FormatException('Invalid Quran dataset');
    final surahs = list.map((e) => Surah.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final total = surahs.fold<int>(0, (n, s) => n + s.verses.length);
    if (total < 6200) throw const FormatException('Incomplete Quran dataset');
    return surahs;
  }

  Future<List<Surah>> load() async {
    // Prefer the bundled, offline copy. The CI build refreshes this file from Al Quran Cloud.
    try {
      final raw = await rootBundle.loadString('assets/data/quran.json');
      return _parse(raw);
    } catch (_) {
      // Network fallback makes the app recover even if an old APK had a bad asset.
      final response = await http.get(Uri.parse(_url), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw Exception('Quran data unavailable (${response.statusCode})');
      return _parse(response.body);
    }
  }
}

class PrayerService {
  Future<Position?> location() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 25)).timeout(const Duration(seconds: 15));
  }

  Future<tz.Location> localZone() async {
    tz.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      final id = zone.identifier;
      final location = tz.getLocation(id);
      tz.setLocalLocation(location);
      return location;
    } catch (_) {
      return tz.local;
    }
  }

  List<PrayerEntry> calculate(double latitude, double longitude, DateTime date, {Madhab madhab = Madhab.shafi}) {
    final coordinates = Coordinates(latitude, longitude);
    final params = CalculationMethodParameters.muslimWorldLeague()
      ..madhab = madhab
      ..highLatitudeRule = HighLatitudeRule.recommended(coordinates);
    final times = PrayerTimes(coordinates: coordinates, date: date, calculationParameters: params, precision: true);
    final zone = tz.local;
    DateTime local(DateTime utc) => tz.TZDateTime.from(utc.toUtc(), zone);
    return [
      PrayerEntry(name: 'Fajr', arabic: 'الفجر', time: local(times.fajr)),
      PrayerEntry(name: 'Sunrise', arabic: 'الشروق', time: local(times.sunrise)),
      PrayerEntry(name: 'Dhuhr', arabic: 'الظهر', time: local(times.dhuhr)),
      PrayerEntry(name: 'Asr', arabic: 'العصر', time: local(times.asr)),
      PrayerEntry(name: 'Maghrib', arabic: 'المغرب', time: local(times.maghrib)),
      PrayerEntry(name: 'Isha', arabic: 'العشاء', time: local(times.isha)),
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
    if (date.isBefore(now)) date = tz.TZDateTime(tz.local, now.year, now.month, now.day, prayer.time.hour, prayer.time.minute).add(const Duration(days: 1));
    await plugin.zonedSchedule(
      id: prayer.name.hashCode.abs() % 100000,
      title: 'HudaWay • ${prayer.name}',
      body: 'Waqtiga salaadda ${prayer.name} ayaa galay.',
      scheduledDate: date,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('adhan_prayer', 'Adhan & Prayer Times', channelDescription: 'Prayer time notifications', importance: Importance.max, priority: Priority.high, playSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleAll(List<PrayerEntry> prayers) async {
    if (!ready) return;
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

  static Future<void> setPrayerMethod(String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('prayerMethod', value);
  }

  static Future<String> prayerMethod() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('prayerMethod') ?? 'MWL';
  }
}
