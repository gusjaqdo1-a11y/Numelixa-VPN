import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'services.dart';

const emerald = Color(0xFF0B5D45);
const deep = Color(0xFF061A14);
const gold = Color(0xFFD6A63A);

class HudaWayApp extends StatelessWidget {
  final AlarmService alarms;
  const HudaWayApp({super.key, required this.alarms});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'HudaWay',
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: deep, colorScheme: ColorScheme.fromSeed(seedColor: emerald, brightness: Brightness.dark)),
    home: HomeShell(alarms: alarms),
  );
}

class HomeShell extends StatefulWidget {
  final AlarmService alarms;
  const HomeShell({super.key, required this.alarms});
  @override State<HomeShell> createState() => _HomeShellState();
}
class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  @override Widget build(BuildContext context) {
    final pages = <Widget>[DashboardPage(alarms: widget.alarms), const QuranPage(), PrayerPage(alarms: widget.alarms), const DhikrPage(), MorePage(alarms: widget.alarms)];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: tab, children: pages)),
      bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Quran'),
        NavigationDestination(icon: Icon(Icons.mosque_outlined), selectedIcon: Icon(Icons.mosque), label: 'Prayer'),
        NavigationDestination(icon: Icon(Icons.fingerprint), label: 'Dhikr'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'More'),
      ]),
    );
  }
}

Widget panel(Widget child) => Container(
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .055), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white12)),
  child: child,
);

class DashboardPage extends StatefulWidget {
  final AlarmService alarms;
  const DashboardPage({super.key, required this.alarms});
  @override State<DashboardPage> createState() => _DashboardPageState();
}
class _DashboardPageState extends State<DashboardPage> {
  List<PrayerEntry>? prayers;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final s = PrayerService();
      await s.localZone();
      final p = await s.location();
      if (p != null && mounted) setState(() => prayers = s.calculate(p.latitude, p.longitude, DateTime.now()));
    } catch (_) {}
  }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Row(children: [Container(width: 58, height: 58, decoration: BoxDecoration(color: emerald, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.mosque, color: gold, size: 30)), const SizedBox(width: 14), const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Assalamu Alaikum', style: TextStyle(color: Colors.white60)), Text('HudaWay', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900))])]),
    const SizedBox(height: 20),
    panel(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(Icons.auto_awesome, color: gold), SizedBox(width: 8), Text('Ayah of the Day', style: TextStyle(color: gold, fontWeight: FontWeight.bold))]), SizedBox(height: 12), Text('إِنَّ مَعَ الْعُسْرِ يُسْرًا', textAlign: TextAlign.right, style: TextStyle(fontSize: 29, height: 1.8, fontWeight: FontWeight.w700)), SizedBox(height: 6), Text('Indeed, with hardship comes ease.', style: TextStyle(color: Colors.white70)), Text('Ash-Sharh 94:6', style: TextStyle(color: Colors.white38, fontSize: 12))])),
    const SizedBox(height: 14),
    panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Today’s Prayer Times', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 10), if (prayers == null) const Text('Allow location to see prayer times.', style: TextStyle(color: Colors.white54)) else ...prayers!.where((p) => p.name != 'Sunrise').map((p) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Text(p.name), const Spacer(), Text(DateFormat('h:mm a').format(p.time), style: const TextStyle(color: gold, fontWeight: FontWeight.bold))])))])),
    const SizedBox(height: 14),
    GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5, children: [
      _tile(context, Icons.menu_book, 'Quran', '114 Surahs', const QuranPage()),
      _tile(context, Icons.explore, 'Qibla', 'Live compass', const QiblaPage()),
      _tile(context, Icons.favorite_outline, 'Duas', 'Daily adhkar', const DuasPage()),
      _tile(context, Icons.nightlight_outlined, 'Ramadan', 'Fasting tools', const RamadanPage()),
    ]),
  ]);
  Widget _tile(BuildContext c, IconData icon, String title, String sub, Widget page) => InkWell(onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => page)), borderRadius: BorderRadius.circular(22), child: panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: gold, size: 28), const Spacer(), Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12))])));
}

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});
  @override State<QuranPage> createState() => _QuranPageState();
}
class _QuranPageState extends State<QuranPage> {
  late Future<List<Surah>> future;
  String query = '';
  @override void initState() { super.initState(); future = QuranService().load(); }
  @override Widget build(BuildContext context) => FutureBuilder<List<Surah>>(
    future: future,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snap.hasError || !snap.hasData) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.menu_book, color: gold, size: 64), const SizedBox(height: 16), const Text('Quran data could not be loaded', textAlign: TextAlign.center, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Please retry. The app also has an online fallback.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)), const SizedBox(height: 16), FilledButton.icon(onPressed: () => setState(() => future = QuranService().load()), icon: const Icon(Icons.refresh), label: const Text('Retry'))])));
      final all = snap.data!;
      final q = query.trim().toLowerCase();
      final list = q.isEmpty ? all : all.where((s) => s.englishName.toLowerCase().contains(q) || s.name.contains(query.trim()) || s.number.toString() == q).toList();
      return ListView(padding: const EdgeInsets.all(18), children: [const Text('Quran Kareem', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const Text('القرآن الكريم', style: TextStyle(color: gold, fontSize: 19)), const SizedBox(height: 16), TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search Surah by name or number')), const SizedBox(height: 14), panel(const Text('114 Surahs  •  6236 Ayahs', style: TextStyle(fontWeight: FontWeight.w700))), const SizedBox(height: 10), ...list.map((s) => Card(color: Colors.white.withValues(alpha: .04), child: ListTile(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(surah: s))), leading: CircleAvatar(backgroundColor: emerald, child: Text('${s.number}')), title: Text(s.englishName, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${s.revelationType} • ${s.verses.length} Ayahs'), trailing: Text(s.name, style: const TextStyle(fontSize: 18))))), if (list.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No Surah found')))]);
    },
  );
}

class ReaderPage extends StatefulWidget {
  final Surah surah;
  const ReaderPage({super.key, required this.surah});
  @override State<ReaderPage> createState() => _ReaderPageState();
}
class _ReaderPageState extends State<ReaderPage> {
  final AudioPlayer audio = AudioPlayer();
  int? playing;
  double size = 28;
  @override void dispose() { audio.dispose(); super.dispose(); }
  Future<void> playAyah(Ayah a) async {
    try {
      if (playing == a.number) { await audio.stop(); if (mounted) setState(() => playing = null); return; }
      await audio.stop();
      await audio.play(UrlSource('https://cdn.islamic.network/quran/audio/128/ar.alafasy/${a.number}.mp3'));
      if (mounted) setState(() => playing = a.number);
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio could not be played.'))); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.surah.englishName), actions: [IconButton(onPressed: () => setState(() => size = math.min(42, size + 2)), icon: const Icon(Icons.text_increase)), IconButton(onPressed: () => setState(() => size = math.max(20, size - 2)), icon: const Icon(Icons.text_decrease))]),
    body: ListView(padding: const EdgeInsets.all(16), children: [panel(Column(children: [Text(widget.surah.name, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)), Text(widget.surah.translation, style: const TextStyle(color: Colors.white54)), const SizedBox(height: 6), Text('${widget.surah.revelationType} • ${widget.surah.verses.length} verses', style: const TextStyle(color: gold, fontSize: 12))])), const SizedBox(height: 12), ...widget.surah.verses.map((a) => Padding(padding: const EdgeInsets.only(bottom: 10), child: panel(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [CircleAvatar(radius: 15, backgroundColor: emerald, child: Text('${a.numberInSurah}', style: const TextStyle(fontSize: 11))), const Spacer(), IconButton(onPressed: () => playAyah(a), icon: Icon(playing == a.number ? Icons.stop_circle : Icons.play_circle_outline, color: gold))]), Text(a.text, textAlign: TextAlign.right, style: TextStyle(fontSize: size, height: 1.95, fontWeight: FontWeight.w600))])))]),
  );
}

class PrayerPage extends StatefulWidget {
  final AlarmService alarms;
  const PrayerPage({super.key, required this.alarms});
  @override State<PrayerPage> createState() => _PrayerPageState();
}
class _PrayerPageState extends State<PrayerPage> {
  List<PrayerEntry>? prayers;
  bool loading = false;
  String locationText = 'Location not loaded';
  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final service = PrayerService();
      await service.localZone();
      final p = await service.location();
      if (p == null) throw Exception('Enable GPS and location permission.');
      final list = service.calculate(p.latitude, p.longitude, DateTime.now());
      await widget.alarms.scheduleAll(list);
      if (mounted) setState(() { prayers = list; locationText = '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}'; });
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    finally { if (mounted) setState(() => loading = false); }
  }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Row(children: [const Expanded(child: Text('Prayer Times', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))), IconButton(onPressed: loading ? null : load, icon: const Icon(Icons.refresh, color: gold))]),
    Text(locationText, style: const TextStyle(color: Colors.white54)),
    const SizedBox(height: 14),
    if (prayers == null) panel(Column(children: [const Icon(Icons.location_on_outlined, color: gold, size: 48), const SizedBox(height: 10), const Text('Allow location to calculate prayer times and schedule Adhan.', textAlign: TextAlign.center), const SizedBox(height: 14), FilledButton(onPressed: loading ? null : load, child: Text(loading ? 'Finding location…' : 'Use my location'))])) else ...prayers!.map((p) => Padding(padding: const EdgeInsets.only(bottom: 9), child: panel(Row(children: [CircleAvatar(backgroundColor: emerald, child: Icon(p.name == 'Sunrise' ? Icons.wb_sunny_outlined : Icons.mosque_outlined, size: 20)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)), Text(p.arabic, style: const TextStyle(color: Colors.white54))])), Text(DateFormat('h:mm a').format(p.time), style: const TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.w900))])))]);
}

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});
  @override State<QiblaPage> createState() => _QiblaPageState();
}
class _QiblaPageState extends State<QiblaPage> {
  StreamSubscription<CompassEvent>? sub;
  double? heading;
  double? qibla;
  String status = 'Finding your location…';
  double bearing(double lat, double lon) {
    const klat = 21.422487;
    const klon = 39.826206;
    final a = lat * math.pi / 180;
    final b = klat * math.pi / 180;
    final d = (klon - lon) * math.pi / 180;
    return (math.atan2(math.sin(d) * math.cos(b), math.cos(a) * math.sin(b) - math.sin(a) * math.cos(b) * math.cos(d)) * 180 / math.pi + 360) % 360;
  }
  @override void initState() { super.initState(); _start(); }
  Future<void> _start() async {
    try {
      final p = await PrayerService().location();
      if (p == null) { if (mounted) setState(() => status = 'Location permission and GPS are required.'); return; }
      if (mounted) setState(() { qibla = bearing(p.latitude, p.longitude); status = 'Hold the phone flat and rotate slowly for calibration.'; });
      sub = FlutterCompass.events?.listen((e) { if (mounted && e.heading != null) setState(() => heading = e.heading); });
    } catch (e) { if (mounted) setState(() => status = 'Compass unavailable: $e'); }
  }
  @override void dispose() { sub?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final angle = ((qibla ?? 0) - (heading ?? 0)) * math.pi / 180;
    return Scaffold(appBar: AppBar(title: const Text('Qibla Finder')), body: ListView(padding: const EdgeInsets.all(20), children: [panel(Column(children: [const Text('QIBLA DIRECTION', style: TextStyle(color: gold, fontWeight: FontWeight.w800, letterSpacing: 2)), const SizedBox(height: 8), Text(qibla == null ? '—' : '${qibla!.toStringAsFixed(1)}° from North', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 20), SizedBox(width: 280, height: 280, child: Stack(alignment: Alignment.center, children: [Container(width: 230, height: 230, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2)), child: const Icon(Icons.explore_outlined, color: Colors.white24, size: 170)), Transform.rotate(angle: angle, child: const Icon(Icons.navigation, color: gold, size: 82))])), const SizedBox(height: 18), Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54))]))]));
  }
}

class DhikrPage extends StatefulWidget {
  const DhikrPage({super.key});
  @override State<DhikrPage> createState() => _DhikrPageState();
}
class _DhikrPageState extends State<DhikrPage> {
  int count = 0;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [const Text('Dhikr & Tasbeeh', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 20), panel(Column(children: [const Text('سُبْحَانَ اللهِ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)), const SizedBox(height: 20), Text('$count', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: gold)), const SizedBox(height: 18), FilledButton(onPressed: () => setState(() => count++), child: const Padding(padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14), child: Text('TASBEEH'))), TextButton(onPressed: () => setState(() => count = 0), child: const Text('Reset'))]))]);
}

class DuasPage extends StatelessWidget {
  const DuasPage({super.key});
  @override Widget build(BuildContext context) {
    const items = [
      ('Morning', 'اللَّهُمَّ بِكَ أَصْبَحْنَا', 'O Allah, by You we enter the morning.'),
      ('Forgiveness', 'رَبِّي اغْفِرْ لِي', 'My Lord, forgive me.'),
      ('Protection', 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ', 'I seek refuge in the perfect words of Allah.'),
    ];
    return Scaffold(appBar: AppBar(title: const Text('Duas & Adhkar')), body: ListView.separated(padding: const EdgeInsets.all(18), itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(height: 12), itemBuilder: (_, i) => panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(items[i].$1, style: const TextStyle(color: gold, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text(items[i].$2, textAlign: TextAlign.right, style: const TextStyle(fontSize: 25, height: 1.8)), const SizedBox(height: 8), Text(items[i].$3, style: const TextStyle(color: Colors.white60))]))));
  }
}

class RamadanPage extends StatelessWidget {
  const RamadanPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Ramadan')), body: ListView(padding: const EdgeInsets.all(18), children: [panel(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ramadan Tools', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), SizedBox(height: 12), Text('Use your local Fajr and Maghrib times for Suhoor and Iftar. HudaWay can schedule daily Adhan notifications from the Prayer section.'), SizedBox(height: 14), Icon(Icons.nightlight_round, color: gold, size: 48)]))]));
}

class MorePage extends StatelessWidget {
  final AlarmService alarms;
  const MorePage({super.key, required this.alarms});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('More', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
    const SizedBox(height: 16),
    panel(Column(children: [
      const ListTile(leading: Icon(Icons.explore, color: gold), title: Text('Qibla Finder'), subtitle: Text('Find the direction to the Kaaba')),
      ListTile(leading: const Icon(Icons.volume_up, color: gold), title: const Text('Adhan Sound'), subtitle: const Text('Choose your preferred Adhan'), trailing: FutureBuilder<String>(future: AlarmService.sound(), builder: (_, snapshot) => DropdownButton<String>(value: ['adhan_kuwait', 'adhan_dubai', 'adhan_fajr'].contains(snapshot.data) ? snapshot.data : 'adhan_kuwait', items: const [DropdownMenuItem(value: 'adhan_kuwait', child: Text('Kuwait')), DropdownMenuItem(value: 'adhan_dubai', child: Text('Dubai')), DropdownMenuItem(value: 'adhan_fajr', child: Text('Fajr'))], onChanged: (value) async { if (value == null) return; await AlarmService.setSound(value); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adhan sound saved.'))); }))),
      const ListTile(leading: Icon(Icons.shield_outlined, color: gold), title: Text('HudaWay'), subtitle: Text('A privacy-friendly Muslim companion')),
    ])),
  ]);
}
