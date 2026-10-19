import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'services.dart';

const emerald = Color(0xFF0B5D45);
const deep = Color(0xFF061A14);
const gold = Color(0xFFD6A63A);
const surface = Color(0xFF0D241D);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final alarms = AlarmService();
  await alarms.init();
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
      appBarTheme: const AppBarTheme(backgroundColor: deep, surfaceTintColor: Colors.transparent),
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
  late final List<Widget> pages = [
    const DashboardPage(),
    const QuranPage(),
    PrayerPage(alarms: widget.alarms),
    const DhikrPage(),
    const MorePage(),
  ];
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: IndexedStack(index: index, children: pages)),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (v) => setState(() => index = v),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Quran'),
        NavigationDestination(icon: Icon(Icons.mosque_outlined), selectedIcon: Icon(Icons.mosque), label: 'Prayer'),
        NavigationDestination(icon: Icon(Icons.fingerprint), selectedIcon: Icon(Icons.fingerprint), label: 'Dhikr'),
        NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'More'),
      ],
    ),
  );
}

Widget glass(BuildContext context, {required Widget child, EdgeInsets padding = const EdgeInsets.all(18)}) => Container(
  padding: padding,
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: .055),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withValues(alpha: .08)),
  ),
  child: child,
);

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override Widget build(BuildContext context) {
    final date = DateTime.now();
    return ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 30), children: [
      Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(17), child: SvgPicture.asset('assets/brand/logo.svg', width: 58, height: 58)),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Assalamu Alaikum', style: TextStyle(color: Colors.white60)),
          Text('HudaWay', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
        ])),
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())), icon: const Icon(Icons.settings_outlined)),
      ]),
      const SizedBox(height: 20),
      glass(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Row(children: [Icon(Icons.auto_awesome, color: gold), SizedBox(width: 8), Text('Ayah of the day', style: TextStyle(color: gold, fontWeight: FontWeight.bold))]),
        SizedBox(height: 12),
        Text('إِنَّ مَعَ الْعُسْرِ يُسْرًا', textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: TextStyle(fontSize: 29, height: 1.8, fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text('Indeed, with hardship comes ease.', style: TextStyle(color: Colors.white70)),
        SizedBox(height: 4),
        Text('Ash-Sharh · 94:6', style: TextStyle(color: Colors.white38, fontSize: 12)),
      ])),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _ActionCard(icon: Icons.menu_book, title: 'Quran', subtitle: 'Read & listen', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranPage())))),
        const SizedBox(width: 12),
        Expanded(child: _ActionCard(icon: Icons.explore, title: 'Qibla', subtitle: 'Find direction', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaPage())))),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _ActionCard(icon: Icons.favorite_outline, title: 'Duas', subtitle: 'Daily adhkar', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DuasPage())))),
        const SizedBox(width: 12),
        Expanded(child: _ActionCard(icon: Icons.nightlight_outlined, title: 'Ramadan', subtitle: 'Fasting tools', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RamadanPage())))),
      ]),
      const SizedBox(height: 14),
      glass(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(children: [const Icon(Icons.calendar_month, color: gold), const SizedBox(width: 10), Expanded(child: Text(DateFormat('EEEE, d MMMM y').format(date))), const Icon(Icons.chevron_right, color: Colors.white38)]),
        const SizedBox(height: 10),
        const Text('Your Quran, prayer times, Qibla, duas and dhikr — designed to work simply every day.', style: TextStyle(color: Colors.white54, height: 1.45)),
      ])),
      const SizedBox(height: 14),
      glass(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _MiniRow(Icons.fingerprint, 'Tasbeeh counter', 'Track your dhikr', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DhikrPage()))),
        _MiniRow(Icons.volume_up_outlined, 'Quran audio', 'Listen to a Surah', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioQuranPage()))),
        _MiniRow(Icons.bookmark_outline, 'Saved ayahs', 'Return to what you saved', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranPage(savedOnly: true)))),
      ])),
    ]);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override Widget build(BuildContext c) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(22), child: glass(c, padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: gold, size: 27), const SizedBox(height: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12))])));
}

class _MiniRow extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  const _MiniRow(this.icon, this.title, this.subtitle, this.onTap);
  @override Widget build(BuildContext c) => ListTile(contentPadding: EdgeInsets.zero, onTap: onTap, leading: CircleAvatar(backgroundColor: emerald, child: Icon(icon, color: Colors.white)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)), trailing: const Icon(Icons.chevron_right, color: Colors.white38));
}

class QuranPage extends StatefulWidget {
  final bool savedOnly;
  const QuranPage({super.key, this.savedOnly = false});
  @override State<QuranPage> createState() => _QuranPageState();
}
class _QuranPageState extends State<QuranPage> {
  final service = QuranService();
  late Future<List<Surah>> future;
  String query = '';
  @override void initState() { super.initState(); future = service.load(); }
  @override Widget build(BuildContext context) => FutureBuilder<List<Surah>>(
    future: future,
    builder: (c, s) {
      if (s.hasError) return _ErrorView(message: 'Quran data could not be loaded.', retry: () => setState(() => future = service.load()));
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final list = s.data!.where((x) => x.englishName.toLowerCase().contains(query.toLowerCase()) || x.name.contains(query)).toList();
      return ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 30), children: [
        Row(children: [Expanded(child: Text(widget.savedOnly ? 'Saved Ayahs' : 'Quran', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900))), if (widget.savedOnly) IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
        const Text('القرآن الكريم', style: TextStyle(color: gold, fontSize: 18)),
        const SizedBox(height: 18),
        TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search a Surah')),
        const SizedBox(height: 14),
        if (!widget.savedOnly) ...[
          glass(c, child: Row(children: [const Icon(Icons.collections_bookmark_outlined, color: gold), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('114 Surahs', style: TextStyle(fontWeight: FontWeight.w800)), Text('Read offline after the Quran data is bundled', style: TextStyle(color: Colors.white54, fontSize: 12))]))])),
          const SizedBox(height: 12),
        ],
        ...list.map((surah) => Card(color: Colors.white.withValues(alpha: .04), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), child: ListTile(
          onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => ReaderPage(surah: surah))),
          leading: CircleAvatar(backgroundColor: emerald, child: Text('${surah.number}')),
          title: Text(surah.englishName, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${surah.revelationType} · ${surah.ayahs} Ayahs', style: const TextStyle(color: Colors.white54)),
          trailing: Text(surah.name, style: const TextStyle(fontSize: 18)),
        ))),
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
  final AudioPlayer player = AudioPlayer();
  int? playing;
  final Set<String> saved = {};
  @override void dispose() { player.dispose(); super.dispose(); }
  Future<void> play(Ayah ayah) async {
    final url = 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${ayah.number}.mp3';
    if (playing == ayah.number) { await player.stop(); setState(() => playing = null); return; }
    await player.stop();
    await player.play(UrlSource(url));
    setState(() => playing = ayah.number);
    player.onPlayerComplete.first.then((_) { if (mounted) setState(() => playing = null); });
  }
  @override Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text(widget.surah.englishName), actions: [IconButton(onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => AudioQuranPage(surahNumber: widget.surah.number))), icon: const Icon(Icons.headphones))]),
    body: ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 30), children: [
      glass(c, child: Column(children: [Text(widget.surah.name, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(widget.surah.translation, style: const TextStyle(color: Colors.white54)), const SizedBox(height: 8), Text('${widget.surah.revelationType} · ${widget.surah.ayahs} verses', style: const TextStyle(color: gold, fontSize: 12))])),
      const SizedBox(height: 14),
      ...widget.surah.verses.map((a) => Padding(padding: const EdgeInsets.only(bottom: 13), child: glass(c, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [CircleAvatar(radius: 15, backgroundColor: emerald, child: Text('${a.numberInSurah}', style: const TextStyle(fontSize: 11))), const Spacer(), IconButton(onPressed: () async { final key = '${widget.surah.number}:${a.numberInSurah}'; setState(() { saved.contains(key) ? saved.remove(key) : saved.add(key); }); await Preferences.saveLastAyah(widget.surah.number, a.numberInSurah); }, icon: Icon(saved.contains('${widget.surah.number}:${a.numberInSurah}') ? Icons.bookmark : Icons.bookmark_border, color: gold)), IconButton(onPressed: () => play(a), icon: Icon(playing == a.number ? Icons.stop_circle : Icons.play_circle_outline, color: gold))]),
        const SizedBox(height: 8), Text(a.text, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(fontSize: 27, height: 1.9, fontWeight: FontWeight.w600)),
      ])))),
    ]),
  );
}

class PrayerPage extends StatefulWidget {
  final AlarmService alarms;
  const PrayerPage({super.key, required this.alarms});
  @override State<PrayerPage> createState() => _PrayerPageState();
}
class _PrayerPageState extends State<PrayerPage> {
  final service = PrayerService();
  List<PrayerEntry>? prayers;
  String place = 'Location not set';
  bool loading = false;
  Future<void> load() async {
    setState(() => loading = true);
    final p = await service.location();
    if (p != null) {
      prayers = service.calculate(p.latitude, p.longitude, DateTime.now());
      await widget.alarms.scheduleAll(prayers!);
      place = '${p.latitude.toStringAsFixed(2)}, ${p.longitude.toStringAsFixed(2)}';
    }
    if (mounted) setState(() => loading = false);
  }
  @override Widget build(BuildContext c) => ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 30), children: [
    Row(children: [const Expanded(child: Text('Prayer Times', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))), IconButton(onPressed: loading ? null : load, icon: const Icon(Icons.my_location, color: gold))]),
    Text(place, style: const TextStyle(color: Colors.white54)),
    const SizedBox(height: 18),
    if (prayers == null) glass(c, child: Column(children: [const Icon(Icons.location_on_outlined, size: 55, color: gold), const SizedBox(height: 10), const Text('Use your location for accurate local prayer times.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)), const SizedBox(height: 14), FilledButton.icon(onPressed: loading ? null : load, icon: const Icon(Icons.gps_fixed), label: Text(loading ? 'Loading...' : 'Use my location'))]))
    else ...[
      _NextPrayerCard(prayers: prayers!),
      const SizedBox(height: 12),
      ...prayers!.map((p) => Padding(padding: const EdgeInsets.only(bottom: 9), child: glass(c, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13), child: Row(children: [CircleAvatar(backgroundColor: emerald, child: Icon(_icon(p.name), size: 19)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)), Text(p.arabic, textDirection: TextDirection.rtl, style: const TextStyle(color: gold, fontSize: 12))])), Text(DateFormat('h:mm a').format(p.time), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))])))),
      glass(c, child: const Row(children: [Icon(Icons.notifications_active_outlined, color: gold), SizedBox(width: 12), Expanded(child: Text('Prayer alerts are scheduled locally. Android may require notification and exact-alarm permission.', style: TextStyle(color: Colors.white54, height: 1.4)))])),
    ],
  ]);
  IconData _icon(String n) => switch (n) { 'Fajr' => Icons.wb_twilight, 'Sunrise' => Icons.wb_sunny_outlined, 'Dhuhr' => Icons.sunny, 'Asr' => Icons.wb_sunny, 'Maghrib' => Icons.nights_stay_outlined, _ => Icons.dark_mode_outlined };
}

class _NextPrayerCard extends StatelessWidget {
  final List<PrayerEntry> prayers;
  const _NextPrayerCard({required this.prayers});
  @override Widget build(BuildContext c) {
    final now = DateTime.now();
    final future = prayers.where((p) => p.name != 'Sunrise' && p.time.isAfter(now)).toList();
    final next = future.isNotEmpty ? future.first : prayers.firstWhere((p) => p.name == 'Fajr');
    return glass(c, child: Row(children: [Container(width: 54, height: 54, decoration: BoxDecoration(color: gold.withValues(alpha: .14), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.access_time, color: gold)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Next prayer', style: TextStyle(color: Colors.white54)), Text(next.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))])), Text(DateFormat('h:mm').format(next.time), style: const TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.w800))]));
  }
}

class DhikrPage extends StatefulWidget { const DhikrPage({super.key}); @override State<DhikrPage> createState() => _DhikrPageState(); }
class _DhikrPageState extends State<DhikrPage> {
  int count = 0, target = 33;
  final presets = const [DuaItem(title: 'SubhanAllah', arabic: 'سُبْحَانَ اللَّهِ', meaning: 'Glory be to Allah', target: 33), DuaItem(title: 'Alhamdulillah', arabic: 'الْحَمْدُ لِلَّهِ', meaning: 'All praise is for Allah', target: 33), DuaItem(title: 'Allahu Akbar', arabic: 'اللَّهُ أَكْبَرُ', meaning: 'Allah is the Greatest', target: 34), DuaItem(title: 'La ilaha illallah', arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ', meaning: 'There is no deity except Allah', target: 100)];
  @override Widget build(BuildContext c) => ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 30), children: [const Text('Dhikr & Tasbeeh', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 5), const Text('A calm counter for your daily remembrance.', style: TextStyle(color: Colors.white54)), const SizedBox(height: 20), glass(c, child: Column(children: [Text(presets.firstWhere((x) => x.target == target, orElse: () => presets[0]).arabic, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 24, color: gold)), const SizedBox(height: 6), Text('$count', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900)), Text('of $target', style: const TextStyle(color: Colors.white54)), const SizedBox(height: 16), GestureDetector(onTap: () => setState(() => count = count >= target ? 0 : count + 1), child: Container(width: 190, height: 190, decoration: BoxDecoration(shape: BoxShape.circle, color: emerald, border: Border.all(color: gold, width: 3), boxShadow: [BoxShadow(color: gold.withValues(alpha: .15), blurRadius: 30)]), child: const Center(child: Text('TAP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))))), const SizedBox(height: 12), TextButton.icon(onPressed: () => setState(() => count = 0), icon: const Icon(Icons.refresh), label: const Text('Reset'))])), const SizedBox(height: 18), ...presets.map((d) => Card(color: Colors.white.withValues(alpha: .04), child: ListTile(onTap: () => setState(() { target = d.target; count = 0; }), leading: const Icon(Icons.favorite_border, color: gold), title: Text(d.title), subtitle: Text('${d.meaning} · ${d.target} repetitions'), trailing: target == d.target ? const Icon(Icons.check, color: gold) : null))) ]);
}

class DuasPage extends StatelessWidget {
  const DuasPage({super.key});
  static const groups = [
    ('Morning', 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ', 'We have entered the morning and the dominion belongs to Allah.'),
    ('Evening', 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ', 'We have entered the evening and the dominion belongs to Allah.'),
    ('Before sleep', 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا', 'In Your name, O Allah, I die and I live.'),
    ('After waking', 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا', 'Praise belongs to Allah who gave us life after causing us to die.'),
    ('Before eating', 'بِسْمِ اللَّهِ', 'In the name of Allah.'),
    ('Seeking forgiveness', 'أَسْتَغْفِرُ اللَّهَ', 'I seek forgiveness from Allah.'),
  ];
  @override Widget build(BuildContext c) => Scaffold(appBar: AppBar(title: const Text('Duas & Adhkar')), body: ListView(padding: const EdgeInsets.all(18), children: [glass(c, child: const Text('Daily supplications are presented with Arabic and a simple meaning. For religious study, verify references with a trusted scholar or authenticated source.', style: TextStyle(color: Colors.white60, height: 1.5))), const SizedBox(height: 14), ...groups.map((d) => Padding(padding: const EdgeInsets.only(bottom: 12), child: glass(c, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.$1, style: const TextStyle(color: gold, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(d.$2, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(fontSize: 23, height: 1.7)), const SizedBox(height: 8), Text(d.$3, style: const TextStyle(color: Colors.white70, height: 1.45))])))]));
}

class QiblaPage extends StatefulWidget { const QiblaPage({super.key}); @override State<QiblaPage> createState() => _QiblaPageState(); }
class _QiblaPageState extends State<QiblaPage> {
  double bearing = 0; double? qibla; String status = 'Finding your location...';
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final p = await PrayerService().location(); if (p == null) { if (mounted) setState(() => status = 'Location permission is required.'); return; } final lat1 = p.latitude * math.pi / 180; final lon1 = p.longitude * math.pi / 180; const lat2 = 21.422487 * math.pi / 180; const lon2 = 39.826206 * math.pi / 180; final dLon = lon2 - lon1; final y = math.sin(dLon) * math.cos(lat2); final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon); final b = (math.atan2(y, x) * 180 / math.pi + 360) % 360; if (mounted) setState(() { qibla = b; status = 'Point your phone toward the Kaaba.'; }); }
  @override Widget build(BuildContext c) => Scaffold(appBar: AppBar(title: const Text('Qibla')), body: qibla == null ? Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.explore_outlined, size: 70, color: gold), const SizedBox(height: 16), Text(status, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: _load, child: const Text('Try again'))])) : StreamBuilder<CompassEvent>(stream: FlutterCompass.events, builder: (c, snap) { final heading = snap.data?.heading ?? 0; final rotation = (qibla! - heading) * math.pi / 180; return ListView(padding: const EdgeInsets.all(22), children: [glass(c, child: Column(children: [const Text('QIBLA', style: TextStyle(color: gold, letterSpacing: 3, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text('${qibla!.round()}°', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 20), SizedBox(width: 290, height: 290, child: Stack(alignment: Alignment.center, children: [Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2), color: Colors.white.withValues(alpha: .03))), const Positioned(top: 16, child: Text('N', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))), Transform.rotate(angle: rotation, child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.navigation, color: gold, size: 92), Container(width: 4, height: 45, color: gold)]))])), const SizedBox(height: 18), Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60)), const SizedBox(height: 10), const Text('Keep the phone flat and calibrate the compass away from magnetic interference.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12))]))]); }));
}

class RamadanPage extends StatelessWidget {
  const RamadanPage({super.key});
  @override Widget build(BuildContext c) { final d = DateTime.now(); final year = d.year; final approx = year == 2026 ? 'Ramadan 1447 began around February 18, 2026.' : 'Ramadan dates vary by lunar observation.'; return Scaffold(appBar: AppBar(title: const Text('Ramadan')), body: ListView(padding: const EdgeInsets.all(18), children: [glass(c, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('رمضان كريم', textDirection: TextDirection.rtl, style: TextStyle(fontSize: 30, color: gold, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text(approx, style: const TextStyle(color: Colors.white60)), const SizedBox(height: 10), const Text('Use Prayer Times for your local Fajr and Maghrib times. Local moon-sighting and calculation conventions can differ.', style: TextStyle(color: Colors.white54, height: 1.5))])), const SizedBox(height: 14), _ramadanCard(c, Icons.wb_twilight, 'Suhoor', 'Finish eating and drinking before Fajr.'), _ramadanCard(c, Icons.nights_stay, 'Iftar', 'Break the fast at Maghrib.'), _ramadanCard(c, Icons.menu_book, 'Quran goal', 'Set a daily reading target and continue from your last saved ayah.'), _ramadanCard(c, Icons.favorite, 'Duas', 'Use HudaWay daily duas and dhikr throughout the month.') ]); }
  Widget _ramadanCard(BuildContext c, IconData i, String t, String s) => Padding(padding: const EdgeInsets.only(bottom: 12), child: glass(c, child: Row(children: [CircleAvatar(backgroundColor: emerald, child: Icon(i)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(s, style: const TextStyle(color: Colors.white54, height: 1.35))]))])));
}

class AudioQuranPage extends StatefulWidget {
  final int? surahNumber;
  const AudioQuranPage({super.key, this.surahNumber});
  @override State<AudioQuranPage> createState() => _AudioQuranPageState();
}
class _AudioQuranPageState extends State<AudioQuranPage> {
  final player = AudioPlayer(); int? current;
  @override void dispose() { player.dispose(); super.dispose(); }
  Future<void> toggle(int n) async { if (current == n) { await player.stop(); setState(() => current = null); return; } await player.stop(); await player.play(UrlSource('https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/$n.mp3')); setState(() => current = n); player.onPlayerComplete.first.then((_) { if (mounted) setState(() => current = null); }); }
  @override Widget build(BuildContext c) => Scaffold(appBar: AppBar(title: const Text('Quran Audio')), body: FutureBuilder<List<Surah>>(future: QuranService().load(), builder: (c, s) { if (!s.hasData) return const Center(child: CircularProgressIndicator()); final list = widget.surahNumber == null ? s.data! : s.data!.where((x) => x.number == widget.surahNumber).toList(); return ListView(padding: const EdgeInsets.all(18), children: [glass(c, child: const Row(children: [Icon(Icons.headphones, color: gold), SizedBox(width: 12), Expanded(child: Text('Stream Quran recitation by Mishary Alafasy. Audio is delivered from the Al Quran Cloud CDN when you press play.', style: TextStyle(color: Colors.white60, height: 1.4)))])), const SizedBox(height: 12), ...list.map((x) => Card(color: Colors.white.withValues(alpha: .04), child: ListTile(leading: CircleAvatar(backgroundColor: emerald, child: Text('${x.number}')), title: Text(x.englishName, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${x.ayahs} verses · ${x.revelationType}', style: const TextStyle(color: Colors.white54)), trailing: IconButton(onPressed: () => toggle(x.number), icon: Icon(current == x.number ? Icons.stop_circle : Icons.play_circle, color: gold, size: 31))))) ]); }));
}

class SettingsPage extends StatefulWidget { const SettingsPage({super.key}); @override State<SettingsPage> createState() => _SettingsPageState(); }
class _SettingsPageState extends State<SettingsPage> {
  bool notifications = true; String method = 'Muslim World League';
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final p = await SharedPreferences.getInstance(); if (mounted) setState(() { notifications = p.getBool('notifications') ?? true; method = p.getString('method') ?? 'Muslim World League'; }); }
  Future<void> _save() async { final p = await SharedPreferences.getInstance(); await p.setBool('notifications', notifications); await p.setString('method', method); }
  @override Widget build(BuildContext c) => Scaffold(appBar: AppBar(title: const Text('Settings')), body: ListView(padding: const EdgeInsets.all(18), children: [glass(c, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), SwitchListTile(contentPadding: EdgeInsets.zero, value: notifications, onChanged: (v) { setState(() => notifications = v); _save(); }, title: const Text('Prayer notifications'), subtitle: const Text('Alerts are scheduled on this device', style: TextStyle(color: Colors.white54)))])), const SizedBox(height: 12), glass(c, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Prayer calculation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 8), DropdownButtonFormField<String>(value: method, decoration: const InputDecoration(), items: const ['Muslim World League', 'Egyptian', 'Karachi', 'Umm Al-Qura'].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(), onChanged: (v) { if (v != null) { setState(() => method = v); _save(); } })])), const SizedBox(height: 12), glass(c, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('About HudaWay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), SizedBox(height: 8), Text('HudaWay is a Muslim companion focused on Quran reading, prayer, Qibla, dhikr, duas and Ramadan tools.', style: TextStyle(color: Colors.white60, height: 1.5)), SizedBox(height: 8), Text('Version 1.0.0', style: TextStyle(color: gold))]))]));
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});
  @override Widget build(BuildContext c) => ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 30), children: [const Text('More', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), const SizedBox(height: 16), _more(c, Icons.explore, 'Qibla', 'Live compass toward the Kaaba', const QiblaPage()), _more(c, Icons.volunteer_activism, 'Duas & Adhkar', 'Morning, evening and daily supplications', const DuasPage()), _more(c, Icons.headphones, 'Quran Audio', 'Listen to Surah recitations', const AudioQuranPage()), _more(c, Icons.nightlight, 'Ramadan', 'Fasting and Ramadan helpers', const RamadanPage()), _more(c, Icons.settings_outlined, 'Settings', 'Notifications and prayer preferences', const SettingsPage()), const SizedBox(height: 10), glass(c, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('HudaWay', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), SizedBox(height: 5), Text('A simple companion for your daily worship.', style: TextStyle(color: Colors.white54)), SizedBox(height: 12), Text('Quran text and audio services are powered through Al Quran Cloud when network access is needed.', style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4))]))]);
  Widget _more(BuildContext c, IconData i, String t, String s, Widget page) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Card(color: Colors.white.withValues(alpha: .04), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), child: ListTile(onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => page)), leading: Icon(i, color: gold), title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(s, style: const TextStyle(color: Colors.white54)), trailing: const Icon(Icons.chevron_right))));
}

class _ErrorView extends StatelessWidget { final String message; final VoidCallback retry; const _ErrorView({required this.message, required this.retry}); @override Widget build(BuildContext c) => Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.cloud_off, size: 58, color: gold), const SizedBox(height: 14), Text(message, textAlign: TextAlign.center), const SizedBox(height: 14), FilledButton(onPressed: retry, child: const Text('Retry'))]))); }
