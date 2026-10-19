import 'dart:convert';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'models.dart';

class QuranService {
  static const String _url = 'https://api.alquran.cloud/v1/quran/quran-uthmani';
  List<Surah> _parse(dynamic body) {
    dynamic root = body is String ? jsonDecode(body.replaceFirst('\ufeff', '')) : body;
    if (root is! Map) throw const FormatException('Invalid Quran response');
    dynamic raw = root['data'] is Map ? root['data']['surahs'] : null;
    raw ??= root['surahs'];
    if (raw is! List || raw.length != 114) throw const FormatException('Expected exactly 114 Surahs');
    final result = <Surah>[];
    for (final item in raw) {
      if (item is! Map) throw const FormatException('Invalid Surah entry');
      final map = Map<String, dynamic>.from(item);
      if (map['ayahs'] is! List || (map['ayahs'] as List).isEmpty) throw const FormatException('Invalid Ayah data');
      result.add(Surah.fromJson(map));
    }
    final total = result.fold<int>(0, (sum, s) => sum + s.verses.length);
    if (total != 6236) throw FormatException('Quran Ayah count is $total, expected 6236');
    return result;
  }
  Future<List<Surah>> load() async {
    Object? localError;
    try { return _parse(await rootBundle.loadString('assets/data/quran.json')); } catch (e) { localError = e; }
    try {
      final r = await http.get(Uri.parse(_url), headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 20));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      return _parse(r.body);
    } catch (e) { throw Exception('Quran unavailable. Bundled: $localError; online: $e'); }
  }
}

class PrayerService {
  Future<Position?> location() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return null;
    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)).timeout(const Duration(seconds: 20));
  }
  Future<tz.Location> localZone() async {
    tz.initializeTimeZones();
    try { final info = await FlutterTimezone.getLocalTimezone(); final loc = tz.getLocation(info.identifier); tz.setLocalLocation(loc); return loc; } catch (_) { return tz.local; }
  }
  CalculationParameters _params(String method, Madhab madhab, Coordinates coordinates) {
    final params = switch (method) {
      'Egyptian' => CalculationMethodParameters.egyptian(),
      'Karachi' => CalculationMethodParameters.karachi(),
      'Umm al-Qura' => CalculationMethodParameters.ummAlQura(),
      'Dubai' => CalculationMethodParameters.dubai(),
      'Qatar' => CalculationMethodParameters.qatar(),
      'Kuwait' => CalculationMethodParameters.kuwait(),
      'ISNA' => CalculationMethodParameters.northAmerica(),
      _ => CalculationMethodParameters.muslimWorldLeague(),
    };
    params.madhab = madhab;
    params.highLatitudeRule = HighLatitudeRule.recommended(coordinates);
    return params;
  }
  List<PrayerEntry> calculate(double latitude, double longitude, DateTime date, {String method = 'Muslim World League', Madhab madhab = Madhab.shafi}) {
    final coordinates = Coordinates(latitude, longitude);
    final params = _params(method, madhab, coordinates);
    final localDate = tz.TZDateTime(tz.local, date.year, date.month, date.day);
    final times = PrayerTimes(coordinates: coordinates, date: localDate, calculationParameters: params, precision: true);
    DateTime local(DateTime value) => tz.TZDateTime.from(value.toUtc(), tz.local);
    return [
      PrayerEntry(name: 'Fajr', arabic: 'الفجر', time: local(times.fajr)),
      PrayerEntry(name: 'Sunrise', arabic: 'الشروق', time: local(times.sunrise)),
      PrayerEntry(name: 'Dhuhr', arabic: 'الظهر', time: local(times.dhuhr)),
      PrayerEntry(name: 'Asr', arabic: 'العصر', time: local(times.asr)),
      PrayerEntry(name: 'Maghrib', arabic: 'المغرب', time: local(times.maghrib)),
      PrayerEntry(name: 'Isha', arabic: 'العشاء', time: local(times.isha)),
    ];
  }
  Future<String> reversePlace(double latitude, double longitude) async {
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude&zoom=10&accept-language=en');
      final r = await http.get(uri, headers: const {'User-Agent': 'HudaWay/1.0 (Muslim prayer app)'}).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body) as Map<String, dynamic>;
        final a = (d['address'] as Map?)?.cast<String, dynamic>();
        final country = '${a?['country'] ?? ''}'.trim();
        final city = '${a?['city'] ?? a?['town'] ?? a?['village'] ?? a?['state'] ?? ''}'.trim();
        if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
        if (country.isNotEmpty) return country;
      }
    } catch (_) {}
    return 'Current location';
  }
}

class AlarmService {
  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;
  Future<void> init() async {
    tz.initializeTimeZones();
    try { final info = await FlutterTimezone.getLocalTimezone(); tz.setLocalLocation(tz.getLocation(info.identifier)); } catch (_) {}
    const settings = InitializationSettings(android: AndroidInitializationSettings('@drawable/hudaway_logo'));
    await plugin.initialize(settings: settings);
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    ready = true;
  }
  static Future<String> sound() async { final p = await SharedPreferences.getInstance(); return p.getString('adhanSound') ?? 'adhan_kuwait'; }
  static Future<void> setSound(String value) async { final p = await SharedPreferences.getInstance(); await p.setString('adhanSound', value); }
  Future<void> _schedule(PrayerEntry prayer, int id) async {
    if (!ready || prayer.name == 'Sunrise') return;
    final selected = await sound();
    final soundName = selected == 'adhan_fajr' ? 'adhan_fajr' : selected == 'adhan_dubai' ? 'adhan_dubai' : 'adhan_kuwait';
    final date = tz.TZDateTime(tz.local, prayer.time.year, prayer.time.month, prayer.time.day, prayer.time.hour, prayer.time.minute);
    if (!date.isAfter(tz.TZDateTime.now(tz.local))) return;
    await plugin.zonedSchedule(id: id, title: 'HudaWay • ${prayer.name}', body: 'Waqtiga salaadda ${prayer.name} ayaa galay.', scheduledDate: date, notificationDetails: NotificationDetails(android: AndroidNotificationDetails('adhan_$soundName', 'Adhan • ${soundName.replaceAll('_', ' ')}', channelDescription: 'HudaWay prayer Adhan', importance: Importance.max, priority: Priority.max, playSound: true, sound: RawResourceAndroidNotificationSound(soundName), visibility: NotificationVisibility.public)), androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
  }
  Future<void> scheduleNextDays(PrayerService service, {int days = 7}) async {
    if (!ready || !(await Preferences.alarmsEnabled())) return;
    await service.localZone();
    final pos = await service.location();
    if (pos == null) return;
    await plugin.cancelAll();
    final method = await Preferences.prayerMethod();
    final m = await Preferences.madhabValue();
    for (var i = 0; i < days; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final prayers = service.calculate(pos.latitude, pos.longitude, date, method: method, madhab: m);
      for (var j = 0; j < prayers.length; j++) {
        final id = (date.year * 100000 + date.month * 1000 + date.day * 10 + j).abs();
        await _schedule(prayers[j], id);
      }
    }
  }
  Future<void> refreshStoredSchedule() async { try { await scheduleNextDays(PrayerService(), days: 7); } catch (_) {} }
  Future<void> showLockCalendar(String dateText) async {
    if (!ready) return;
    await plugin.show(id: 9901, title: 'HudaWay • Arabic Calendar', body: dateText, notificationDetails: const NotificationDetails(android: AndroidNotificationDetails('hudaway_calendar', 'HudaWay Calendar', channelDescription: 'Hijri date on the lock screen', importance: Importance.low, priority: Priority.low, ongoing: true, autoCancel: false, playSound: false, visibility: NotificationVisibility.public)));
  }
  Future<void> hideLockCalendar() async { if (ready) await plugin.cancel(9901); }
}

class Preferences {
  static Future<void> setPrayerMethod(String value) async { final p = await SharedPreferences.getInstance(); await p.setString('prayerMethod', value); }
  static Future<String> prayerMethod() async { final p = await SharedPreferences.getInstance(); return p.getString('prayerMethod') ?? 'Muslim World League'; }
  static Future<void> setMadhab(String value) async { final p = await SharedPreferences.getInstance(); await p.setString('madhab', value); }
  static Future<String> madhab() async { final p = await SharedPreferences.getInstance(); return p.getString('madhab') ?? 'Shafi'; }
  static Future<Madhab> madhabValue() async => (await madhab()) == 'Hanafi' ? Madhab.hanafi : Madhab.shafi;
  static Future<void> setAlarmsEnabled(bool value) async { final p = await SharedPreferences.getInstance(); await p.setBool('alarmsEnabled', value); }
  static Future<bool> alarmsEnabled() async { final p = await SharedPreferences.getInstance(); return p.getBool('alarmsEnabled') ?? true; }
  static Future<void> setLockCalendar(bool value) async { final p = await SharedPreferences.getInstance(); await p.setBool('lockCalendar', value); }
  static Future<bool> lockCalendar() async { final p = await SharedPreferences.getInstance(); return p.getBool('lockCalendar') ?? false; }
}
