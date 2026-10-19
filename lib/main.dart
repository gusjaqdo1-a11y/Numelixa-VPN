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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final alarms = AlarmService();
  try { await alarms.init(); } catch (_) {}
  runApp(HudaWayApp(alarms: alarms));
}

class HudaWayApp extends StatelessWidget {
  final AlarmService alarms;
  const HudaWayApp({super.key, required this.alarms});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'HudaWay',
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deep,
      colorScheme: ColorScheme.fromSeed(seedColor: emerald, brightness: Brightness.dark),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: .055),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    ),
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
    final pages = <Widget>[
      const DashboardPage(), const QuranPage(), PrayerPage(alarms: widget.alarms), const DhikrPage(), const MorePage(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Quran'),
          NavigationDestination(icon: Icon(Icons.mosque_outlined), selectedIcon: Icon(Icons.mosque), label: 'Prayer'),
          NavigationDestination(icon: Icon(Icons.fingerprint), label: 'Dhikr'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'More'),
        ],
      ),
    );
  }
}

Widget panel({required Widget child, EdgeInsets padding = const EdgeInsets.all(18)}) => Container(
  padding: padding,
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: .055),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withValues(alpha: .08)),
  ),
  child: child,
);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
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
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const SizedBox(height: 8),
    Row(children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(color: emerald, borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.auto_awesome, color: gold, size: 30)),
      const SizedBox(width: 14),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Assalamu Alaikum', style: TextStyle(color: Colors.white60)), Text('HudaWay', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900))])),
    ]),
    const SizedBox(height: 22),
    panel(child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(Icons.auto_awesome, color: gold), SizedBox(width: 8), Text('Ayah of the day', style: TextStyle(color: gold, fontWeight: FontWeight.bold))]),
      SizedBox(height: 12),
      Text('إِنَّ مَعَ الْعُسْرِ يُسْرًا', textAlign: TextAlign.right, style: TextStyle(fontSize: 29, height: 1.8, fontWeight: FontWeight.w700)),
      SizedBox(height: 8), Text('Indeed, with hardship comes ease.', style: TextStyle(color: Colors.white70)),
      SizedBox(height: 4), Text('Ash-Sharh · 94:6', style: TextStyle(color: Colors.white38, fontSize: 12)),
    ])),
    const SizedBox(height: 14),
    if (prayers == null) panel(child: const Text('Allow location in Prayer to calculate today’s prayer times.'))
    else panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Today’s Prayer Times', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      ...prayers!.where((p) => p.name != 'Sunrise').map((p) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [Text(p.name), const Spacer(), Text(DateFormat('h:mm a').format(p.time), style: const TextStyle(color: gold, fontWeight: FontWeight.bold))]),
      )),
    ])),
    const SizedBox(height: 14),
    GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2,
      mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.55,
      children: [
        _quick(context, Icons.menu_book, 'Quran', '114 Surahs', const QuranPage()),
        _quick(context, Icons.explore, 'Qibla', 'Live compass', const QiblaPage()),
        _quick(context, Icons.favorite_outline, 'Duas', 'Daily adhkar', const DuasPage()),
        _quick(context, Icons.nightlight_outlined, 'Ramadan', 'Fasting tools', const RamadanPage()),
      ],
    ),
  ]);
  Widget _quick(BuildContext context, IconData icon, String title, String subtitle, Widget page) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    borderRadius: BorderRadius.circular(22),
    child: panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: gold, size: 27), const Spacer(), Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12))])),
  );
}

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});
  @override State<QuranPage> createState() => _QuranPageState();
}
class _QuranPageState extends State<QuranPage> {
  late Future<List<Surah>> future;
  String query = '';
  @override void initState() { super.initState(); future = QuranService().load(); }
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Surah>>(
    future: future,
    builder: (context, snap) {
      if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.menu_book_outlined, color: gold, size: 60), const SizedBox(height: 16),
        const Text('Quran data could not be loaded', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16), FilledButton.icon(onPressed: () => setState(() => future = QuranService().load()), icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ])));
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final all = snap.data!;
      final q = query.trim().toLowerCase();
      final list = q.isEmpty ? all : all.where((s) => s.englishName.toLowerCase().contains(q) || s.name.contains(query.trim()) || s.number.toString() == q).toList();
      return ListView(padding: const EdgeInsets.all(18), children: [
        const Text('Quran Kareem', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const Text('القرآن الكريم', style: TextStyle(color: gold, fontSize: 19)), const SizedBox(height: 16),
        TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search Surah by name or number')),
        const SizedBox(height: 14),
        panel(child: Text('${all.length} Surahs · ${all.fold<int>(0, (n, s) => n + s.verses.length)} Ayahs', style: const TextStyle(fontWeight: FontWeight.w700))),
        const SizedBox(height: 10),
        ...list.map((s) => Card(color: Colors.white.withValues(alpha: .04), child: ListTile(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(surah: s))),
          leading: CircleAvatar(backgroundColor: emerald, child: Text('${s.number}')),
          title: Text(s.englishName, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${s.revelationType} · ${s.verses.length} Ayahs'),
          trailing: Text(s.name, style: const TextStyle(fontSize: 18)),
        ))),
        if (list.isEmpty) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('No Surah found'))),
      ]);
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
  double fontSize = 28;
  @override void dispose() { audio.dispose(); super.dispose(); }
  Future<void> play(Ayah ayah) async {
    try {
      if (playing == ayah.number) { await audio.stop(); if (mounted) setState(() => playing = null); return; }
      await audio.stop();
      await audio.play(UrlSource('https://cdn.islamic.network/quran/audio/128/ar.alafasy/${ayah.number}.mp3'));
      if (mounted) setState(() => playing = ayah.number);
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio could not be played.'))); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.surah.englishName), actions: [
      IconButton(onPressed: () => setState(() => fontSize = math.min(42, fontSize + 2)), icon: const Icon(Icons.text_increase)),
      IconButton(onPressed: () => setState(() => fontSize = math.max(20, fontSize - 2)), icon: const Icon(Icons.text_decrease)),
    ]),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      panel(child: Column(children: [Text(widget.surah.name, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)), Text(widget.surah.translation, style: const TextStyle(color: Colors.white54)), const SizedBox(height: 7), Text('${widget.surah.revelationType} · ${widget.surah.verses.length} verses', style: const TextStyle(color: gold, fontSize: 12))])),
      const SizedBox(height: 12),
      ...widget.surah.verses.map((ayah) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [CircleAvatar(radius: 15, backgroundColor: emerald, child: Text('${ayah.numberInSurah}', style: const TextStyle(fontSize: 11))), const Spacer(), IconButton(onPressed: () => play(ayah), icon: Icon(playing == ayah.number ? Icons.stop_circle : Icons.play_circle_outline, color: gold))]),
          Text(ayah.text, textAlign: TextAlign.right, style: TextStyle(fontSize: fontSize, height: 1.95, fontWeight: FontWeight.w600)),
        ])),
      )),
    ],
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
      final s = PrayerService(); await s.localZone(); final p = await s.location();
      if (p == null) throw Exception('Location permission or GPS is unavailable.');
      final list = s.calculate(p.latitude, p.longitude, DateTime.now());
      await widget.alarms.scheduleAll(list);
      if (mounted) setState(() { prayers = list; locationText = '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}'; });
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
    finally { if (mounted) setState(() => loading = false); }
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Row(children: [const Expanded(child: Text('Prayer Times', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))), IconButton(onPressed: loading ? null : load, icon: const Icon(Icons.my_location, color: gold))]),
    Text(locationText, style: const TextStyle(color: Colors.white54)), const SizedBox(height: 12),
    panel(child: const Row(children: [Icon(Icons.calculate_outlined, color: gold), SizedBox(width: 10), Expanded(child: Text('Muslim World League · Shafi Asr', style: TextStyle(fontWeight: FontWeight.w700)))])),
    const SizedBox(height: 14),
    if (prayers == null) panel(child: Column(children: [const Icon(Icons.location_on_outlined, color: gold, size: 48), const SizedBox(height: 10), const Text('Enable location to calculate local prayer times.', textAlign: TextAlign.center), const SizedBox(height: 14), FilledButton(onPressed: loading ? null : load, child: Text(loading ? 'Finding location…' : 'Use my location'))]))
    else ...prayers!.map((p) => Padding(padding: const EdgeInsets.only(bottom: 9), child: panel(child: Row(children: [CircleAvatar(backgroundColor: p.name == 'Sunrise' ? Colors.white12 : emerald, child: Icon(p.name == 'Sunrise' ? Icons.wb_sunny_outlined : Icons.mosque_outlined, size: 20)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)), Text(p.arabic, style: const TextStyle(color: Colors.white54))])), Text(DateFormat('h:mm a').format(p.time), style: const TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.w900)), if (p.name != 'Sunrise') const Padding(padding: EdgeInsets.only(left: 7), child: Icon(Icons.notifications_active_outlined, size: 17, color: gold))])))),
  ]);
}

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});
  @override State<QiblaPage> createState() => _QiblaPageState();
}
class _QiblaPageState extends State<QiblaPage> {
  StreamSubscription<CompassEvent>? subscription;
  double? heading;
  double? qibla;
  String status = 'Finding your location…';
  double bearing(double lat, double lon) {
    const klat = 21.422487, klon = 39.826206;
    final a = lat * math.pi / 180, b = klat * math.pi / 180, d = (klon - lon) * math.pi / 180;
    final y = math.sin(d) * math.cos(b);
    final x = math.cos(a) * math.sin(b) - math.sin(a) * math.cos(b) * math.cos(d);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }
  @override void initState() { super.initState(); _start(); }
  Future<void> _start() async {
    try {
      final p = await PrayerService().location();
      if (p == null) { if (mounted) setState(() => status = 'Location permission and GPS are required.'); return; }
      if (mounted) setState(() { qibla = bearing(p.latitude, p.longitude); status = 'Qibla direction from your current location'; });
      subscription = FlutterCompass.events?.listen((e) { if (mounted && e.heading != null) setState(() => heading = e.heading); });
    } catch (e) { if (mounted) setState(() => status = 'Compass unavailable: $e'); }
  }
  @override void dispose() { subscription?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final angle = ((qibla ?? 0) - (heading ?? 0)) * math.pi / 180;
    return Scaffold(appBar: AppBar(title: const Text('Qibla')), body: ListView(padding: const EdgeInsets.all(22), children: [panel(child: Column(children: [
      const Text('QIBLA DIRECTION', style: TextStyle(color: gold, fontWeight: FontWeight.w800, letterSpacing: 2)), const SizedBox(height: 8),
      Text(qibla == null ? '—' : '${qibla!.toStringAsFixed(1)}° from North', style: const TextStyle(color: Colors.white70)), const SizedBox(height: 26),
      SizedBox(height: 300, child: Stack(alignment: Alignment.center, children: [
        Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .035), border: Border.all(color: gold.withValues(alpha: .5), width: 2))),
        const Positioned(top: 8, child: Text('N', style: TextStyle(color: gold, fontWeight: FontWeight.bold))),
        Transform.rotate(angle: angle, child: CustomPaint(size: const Size(230, 230), painter: QiblaPainter())), const Icon(Icons.location_on, color: gold, size: 30),
      ])), const SizedBox(height: 14), Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)),
      if (heading == null) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Calibrate the compass by moving the phone in a figure-eight.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12))),
    ]))]));
  }
}
class QiblaPainter extends CustomPainter {
  @override void paint(Canvas c, Size s) { final p = Paint()..color = gold; final x = s.width / 2, y = s.height / 2; c.drawPath(Path()..moveTo(x, 10)..lineTo(x - 14, y)..lineTo(x, y - 8)..lineTo(x + 14, y)..close(), p); }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DhikrPage extends StatefulWidget {
  const DhikrPage({super.key});
  @override State<DhikrPage> createState() => _DhikrPageState();
}
class _DhikrPageState extends State<DhikrPage> {
  int count = 0, target = 33;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('Tasbeeh', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 14),
    panel(child: Column(children: [const Text('سُبْحَانَ اللّٰهِ', style: TextStyle(fontSize: 32)), const SizedBox(height: 8), Text('$count / $target', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: gold)), const SizedBox(height: 15),
      GestureDetector(onTap: () => setState(() { count++; if (count > target) count = 1; }), child: Container(width: 190, height: 190, decoration: const BoxDecoration(shape: BoxShape.circle, color: emerald), child: const Center(child: Text('TAP', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900))))),
      const SizedBox(height: 16), Wrap(spacing: 8, children: [for (final n in [33, 99, 100]) ChoiceChip(label: Text('$n'), selected: target == n, onSelected: (_) => setState(() => target = n))]),
    ])),
  ]);
}

class DuasPage extends StatelessWidget {
  const DuasPage({super.key});
  @override Widget build(BuildContext context) {
    const items = [('Morning', 'اللَّهُمَّ بِكَ أَصْبَحْنَا', 'O Allah, by You we enter the morning.'), ('Protection', 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ', 'I seek refuge in the perfect words of Allah.'), ('Forgiveness', 'رَبِّ اغْفِرْ لِي', 'My Lord, forgive me.'), ('Guidance', 'رَبِّ زِدْنِي عِلْمًا', 'My Lord, increase me in knowledge.')];
    return ListView(padding: const EdgeInsets.all(18), children: [const Text('Duas & Adhkar', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 12), ...items.map((x) => Padding(padding: const EdgeInsets.only(bottom: 10), child: panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(x.$1, style: const TextStyle(color: gold, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(x.$2, textAlign: TextAlign.right, style: const TextStyle(fontSize: 25, height: 1.8)), const SizedBox(height: 7), Text(x.$3, style: const TextStyle(color: Colors.white60))]))))]);
  }
}

class RamadanPage extends StatelessWidget {
  const RamadanPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Ramadan')), body: ListView(padding: const EdgeInsets.all(18), children: [panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.nightlight_round, color: gold, size: 42), const SizedBox(height: 12), const Text('Ramadan tools', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 8), const Text('Suhoor and Iftar reminders, Quran goals and daily worship tools.', style: TextStyle(color: Colors.white60, height: 1.5))]))]));
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    const Text('More', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 14),
    ListTile(leading: const Icon(Icons.explore, color: gold), title: const Text('Qibla'), subtitle: const Text('Live direction to the Kaaba'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaPage()))),
    ListTile(leading: const Icon(Icons.favorite, color: gold), title: const Text('Duas & Adhkar'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DuasPage()))),
    ListTile(leading: const Icon(Icons.nightlight, color: gold), title: const Text('Ramadan'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RamadanPage()))),
    panel(child: const Text('HudaWay · Muslim companion', style: TextStyle(color: Colors.white54))),
  ]);
}
