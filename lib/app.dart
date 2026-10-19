import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'services.dart';

const green = Color(0xFF0B5D45);
const dark = Color(0xFF061A14);
const gold = Color(0xFFD6A63A);

class HudaWayApp extends StatelessWidget {
  final AlarmService alarms;
  const HudaWayApp({super.key, required this.alarms});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'HudaWay',
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: dark, colorScheme: ColorScheme.fromSeed(seedColor: green, brightness: Brightness.dark)),
    home: HomeShell(alarms: alarms),
  );
}

class HomeShell extends StatefulWidget {
  final AlarmService alarms;
  const HomeShell({super.key, required this.alarms});
  @override State<HomeShell> createState() => _HomeShellState();
}
class _HomeShellState extends State<HomeShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[DashboardPage(alarms: widget.alarms), const QuranPage(), PrayerPage(alarms: widget.alarms), const DhikrPage(), MorePage(alarms: widget.alarms)];
    return Scaffold(body: SafeArea(child: IndexedStack(index: index, children: pages)), bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Quran'),
      NavigationDestination(icon: Icon(Icons.mosque_outlined), selectedIcon: Icon(Icons.mosque), label: 'Prayer'),
      NavigationDestination(icon: Icon(Icons.fingerprint), selectedIcon: Icon(Icons.fingerprint), label: 'Dhikr'),
      NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'More'),
    ]));
  }
}

Widget box(Widget child) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .055), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white12)), child: child);

class DashboardPage extends StatefulWidget {
  final AlarmService alarms;
  const DashboardPage({super.key, required this.alarms});
  @override State<DashboardPage> createState() => _DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage> {
  List<PrayerEntry>? prayers;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { final s = PrayerService(); await s.localZone(); final p = await s.location(); if (p != null && mounted) setState(() => prayers = s.calculate(p.latitude, p.longitude, DateTime.now())); } catch (_) {} }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Assalamu Alaikum', style: TextStyle(color: Colors.white60)),
    const Text('HudaWay', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
    const SizedBox(height: 18),
    box(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ayah of the Day', style: TextStyle(color: gold, fontWeight: FontWeight.bold)), SizedBox(height: 12), Text('إِنَّ مَعَ الْعُسْرِ يُسْرًا', textAlign: TextAlign.right, style: TextStyle(fontSize: 28, height: 1.8, fontWeight: FontWeight.bold)), SizedBox(height: 6), Text('Indeed, with hardship comes ease.'), Text('Ash-Sharh 94:6', style: TextStyle(color: Colors.white38))])),
    const SizedBox(height: 14),
    box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Today’s Prayer Times', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), if (prayers == null) const Text('Allow location to calculate prayer times.', style: TextStyle(color: Colors.white54)) else ...prayers!.where((p) => p.name != 'Sunrise').map((p) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Text(p.name), const Spacer(), Text(DateFormat('h:mm a').format(p.time), style: const TextStyle(color: gold, fontWeight: FontWeight.bold))])))])),
    const SizedBox(height: 14),
    GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5, children: [
      _tile(context, Icons.menu_book, 'Quran', const QuranPage()),
      _tile(context, Icons.explore, 'Qibla', const QiblaPage()),
      _tile(context, Icons.favorite_outline, 'Duas', const DuasPage()),
      _tile(context, Icons.nightlight_outlined, 'Ramadan', const RamadanPage()),
    ])
  ]);
  Widget _tile(BuildContext c, IconData icon, String title, Widget page) => InkWell(onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => page)), child: box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: gold, size: 30), const Spacer(), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))])));
}

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});
  @override State<QuranPage> createState() => _QuranPageState();
}
class _QuranPageState extends State<QuranPage> {
  late Future<List<Surah>> future;
  String query = '';
  @override void initState() { super.initState(); future = QuranService().load(); }
  @override Widget build(BuildContext context) => FutureBuilder<List<Surah>>(future: future, builder: (context, snap) {
    if (!snap.hasData && !snap.hasError) return const Center(child: CircularProgressIndicator());
    if (snap.hasError) return Center(child: FilledButton.icon(onPressed: () => setState(() => future = QuranService().load()), icon: const Icon(Icons.refresh), label: const Text('Retry Quran')));
    final all = snap.data!;
    final q = query.trim().toLowerCase();
    final list = q.isEmpty ? all : all.where((s) => s.englishName.toLowerCase().contains(q) || s.name.contains(query.trim()) || s.number.toString() == q).toList();
    return ListView(padding: const EdgeInsets.all(18), children: [const Text('Quran Kareem', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const Text('القرآن الكريم', style: TextStyle(color: gold, fontSize: 20)), const SizedBox(height: 14), TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search Surah')), const SizedBox(height: 12), box(const Text('114 Surahs • 6236 Ayahs')), const SizedBox(height: 8), ...list.map((s) => Card(child: ListTile(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(surah: s))), leading: CircleAvatar(backgroundColor: green, child: Text('${s.number}')), title: Text(s.englishName), subtitle: Text('${s.verses.length} Ayahs'), trailing: Text(s.name, style: const TextStyle(fontSize: 18)))))]);
  });
}

class ReaderPage extends StatefulWidget {
  final Surah surah;
  const ReaderPage({super.key, required this.surah});
  @override State<ReaderPage> createState() => _ReaderPageState();
}
class _ReaderPageState extends State<ReaderPage> {
  final AudioPlayer player = AudioPlayer();
  double fontSize = 28;
  int? playing;
  @override void dispose() { player.dispose(); super.dispose(); }
  Future<void> play(Ayah ayah) async { try { if (playing == ayah.number) { await player.stop(); if (mounted) setState(() => playing = null); return; } await player.stop(); await player.play(UrlSource('https://cdn.islamic.network/quran/audio/128/ar.alafasy/${ayah.number}.mp3')); if (mounted) setState(() => playing = ayah.number); } catch (_) {} }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(widget.surah.englishName), actions: [IconButton(onPressed: () => setState(() => fontSize = math.min(42, fontSize + 2)), icon: const Icon(Icons.text_increase)), IconButton(onPressed: () => setState(() => fontSize = math.max(20, fontSize - 2)), icon: const Icon(Icons.text_decrease))]), body: ListView(padding: const EdgeInsets.all(16), children: [box(Column(children: [Text(widget.surah.name, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)), Text(widget.surah.translation, style: const TextStyle(color: Colors.white54))])), const SizedBox(height: 10), ...widget.surah.verses.map((a) => Padding(padding: const EdgeInsets.only(bottom: 10), child: box(Column(children: [Row(children: [CircleAvatar(backgroundColor: green, radius: 15, child: Text('${a.numberInSurah}')), const Spacer(), IconButton(onPressed: () => play(a), icon: Icon(playing == a.number ? Icons.stop_circle : Icons.play_circle_outline, color: gold))]), Text(a.text, textAlign: TextAlign.right, style: TextStyle(fontSize: fontSize, height: 1.9, fontWeight: FontWeight.w600))])))]));
}

class PrayerPage extends StatefulWidget {
  final AlarmService alarms;
  const PrayerPage({super.key, required this.alarms});
  @override State<PrayerPage> createState() => _PrayerPageState();
}
class _PrayerPageState extends State<PrayerPage> {
  List<PrayerEntry>? prayers;
  bool loading = false;
  @override void initState() { super.initState(); load(); }
  Future<void> load() async { if (loading) return; setState(() => loading = true); try { final s = PrayerService(); await s.localZone(); final p = await s.location(); if (p == null) throw Exception('Location permission or GPS is disabled.'); final list = s.calculate(p.latitude, p.longitude, DateTime.now()); await widget.alarms.scheduleAll(list); if (mounted) setState(() => prayers = list); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } finally { if (mounted) setState(() => loading = false); } }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [Row(children: [const Expanded(child: Text('Prayer Times', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))), IconButton(onPressed: loading ? null : load, icon: const Icon(Icons.refresh, color: gold))]), if (prayers == null) box(Column(children: [const Icon(Icons.location_on, color: gold, size: 48), const SizedBox(height: 10), const Text('Use your location for accurate prayer times.', textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: loading ? null : load, child: Text(loading ? 'Loading…' : 'Use my location'))])) else ...prayers!.map((p) => Padding(padding: const EdgeInsets.only(bottom: 8), child: box(Row(children: [Icon(p.name == 'Sunrise' ? Icons.wb_sunny : Icons.mosque, color: gold), const SizedBox(width: 12), Expanded(child: Text('${p.name}\n${p.arabic}')), Text(DateFormat('h:mm a').format(p.time), style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 17))])))]);
}

class QiblaPage extends StatefulWidget { const QiblaPage({super.key}); @override State<QiblaPage> createState() => _QiblaPageState(); }
class _QiblaPageState extends State<QiblaPage> {
  StreamSubscription<CompassEvent>? subscription;
  double? heading;
  double? qibla;
  @override void initState() { super.initState(); _start(); }
  double bearing(double lat, double lon) { const kLat = 21.422487; const kLon = 39.826206; final a = lat * math.pi / 180; final b = kLat * math.pi / 180; final d = (kLon - lon) * math.pi / 180; return (math.atan2(math.sin(d) * math.cos(b), math.cos(a) * math.sin(b) - math.sin(a) * math.cos(b) * math.cos(d)) * 180 / math.pi + 360) % 360; }
  Future<void> _start() async { try { final p = await PrayerService().location(); if (p == null) return; if (mounted) setState(() => qibla = bearing(p.latitude, p.longitude)); subscription = FlutterCompass.events?.listen((e) { if (mounted && e.heading != null) setState(() => heading = e.heading); }); } catch (_) {} }
  @override void dispose() { subscription?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) { final angle = ((qibla ?? 0) - (heading ?? 0)) * math.pi / 180; return Scaffold(appBar: AppBar(title: const Text('Qibla Finder')), body: Center(child: ListView(padding: const EdgeInsets.all(20), children: [box(Column(children: [const Text('QIBLA', style: TextStyle(color: gold, fontWeight: FontWeight.bold, letterSpacing: 3)), const SizedBox(height: 12), Text(qibla == null ? 'Location unavailable' : '${qibla!.toStringAsFixed(1)}° from North', style: const TextStyle(fontSize: 20)), const SizedBox(height: 20), Transform.rotate(angle: angle, child: const Icon(Icons.navigation, size: 180, color: gold)), const SizedBox(height: 12), const Text('Keep the phone flat and calibrate the compass.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))]))]))); }
}

class DhikrPage extends StatefulWidget { const DhikrPage({super.key}); @override State<DhikrPage> createState() => _DhikrPageState(); }
class _DhikrPageState extends State<DhikrPage> { int count = 0; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Dhikr & Tasbeeh')), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('سُبْحَانَ اللَّهِ', style: TextStyle(fontSize: 30)), const SizedBox(height: 20), Text('$count', style: const TextStyle(fontSize: 70, fontWeight: FontWeight.w900, color: gold)), const SizedBox(height: 20), FilledButton(onPressed: () => setState(() => count++), child: const Padding(padding: EdgeInsets.all(20), child: Text('TAP', style: TextStyle(fontSize: 22)))), TextButton(onPressed: () => setState(() => count = 0), child: const Text('Reset'))]))); }

class DuasPage extends StatelessWidget { const DuasPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Duas & Adhkar')), body: ListView(padding: const EdgeInsets.all(18), children: const [DuaCard('Morning', 'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا'), DuaCard('Forgiveness', 'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ'), DuaCard('Protection', 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ')]); }
class DuaCard extends StatelessWidget { final String title; final String text; const DuaCard(this.title, this.text, {super.key}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: gold, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text(text, textAlign: TextAlign.right, style: const TextStyle(fontSize: 24, height: 1.8))]))); }

class RamadanPage extends StatelessWidget { const RamadanPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Ramadan')), body: ListView(padding: const EdgeInsets.all(18), children: [box(const Column(children: [Icon(Icons.nightlight_round, color: gold, size: 55), SizedBox(height: 14), Text('Ramadan Tools', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('Use Prayer Times for Fajr and Maghrib to follow your daily fasting schedule.', textAlign: TextAlign.center)]))]); }

class MorePage extends StatefulWidget { final AlarmService alarms; const MorePage({super.key, required this.alarms}); @override State<MorePage> createState() => _MorePageState(); }
class _MorePageState extends State<MorePage> { String sound = 'adhan_kuwait'; @override void initState() { super.initState(); _load(); } Future<void> _load() async { final s = await AlarmService.sound(); if (mounted) setState(() => sound = s); } @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [const Text('More', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 12), ListTile(leading: const Icon(Icons.explore, color: gold), title: const Text('Qibla'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaPage()))), ListTile(leading: const Icon(Icons.favorite, color: gold), title: const Text('Duas'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DuasPage()))), const Divider(), const ListTile(title: Text('Adhan Sound', style: TextStyle(fontWeight: FontWeight.bold))), RadioListTile<String>(value: 'adhan_kuwait', groupValue: sound, title: const Text('Kuwait'), onChanged: (v) async { if (v != null) { await AlarmService.setSound(v); setState(() => sound = v); }}), RadioListTile<String>(value: 'adhan_dubai', groupValue: sound, title: const Text('Dubai'), onChanged: (v) async { if (v != null) { await AlarmService.setSound(v); setState(() => sound = v); }}), RadioListTile<String>(value: 'adhan_fajr', groupValue: sound, title: const Text('Fajr'), onChanged: (v) async { if (v != null) { await AlarmService.setSound(v); setState(() => sound = v); }})]); }
