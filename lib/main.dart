import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'services.dart';

const emerald = Color(0xFF0B5D45);
const deep = Color(0xFF061A14);
const gold = Color(0xFFD6A63A);

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
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HudaWay',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: deep,
        colorScheme: ColorScheme.fromSeed(seedColor: emerald, brightness: Brightness.dark),
      ),
      home: HomeShell(alarms: alarms),
    );
  }
}

class HomeShell extends StatefulWidget {
  final AlarmService alarms;
  const HomeShell({super.key, required this.alarms});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const DashboardPage(),
      const QuranPage(),
      PrayerPage(alarms: widget.alarms),
      const DhikrPage(),
      const MorePage(),
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

Widget glass(BuildContext context, {required Widget child, EdgeInsets padding = const EdgeInsets.all(18)}) {
  return Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.055),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: child,
  );
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.now();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SvgPicture.asset('assets/brand/logo.svg', width: 58, height: 58),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assalamu Alaikum', style: TextStyle(color: Colors.white60)),
                  Text('HudaWay', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        const SizedBox(height: 20),
        glass(
          context,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Icon(Icons.auto_awesome, color: gold), SizedBox(width: 8), Text('Ayah of the day', style: TextStyle(color: gold, fontWeight: FontWeight.bold))]),
              SizedBox(height: 12),
              Text('إِنَّ مَعَ الْعُسْرِ يُسْرًا', textAlign: TextAlign.right, style: TextStyle(fontSize: 29, height: 1.8, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('Indeed, with hardship comes ease.', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 4),
              Text('Ash-Sharh · 94:6', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _action(context, Icons.menu_book, 'Quran', 'Read & listen', const QuranPage())),
          const SizedBox(width: 12),
          Expanded(child: _action(context, Icons.explore, 'Qibla', 'Find direction', const QiblaPage())),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _action(context, Icons.favorite_outline, 'Duas', 'Daily adhkar', const DuasPage())),
          const SizedBox(width: 12),
          Expanded(child: _action(context, Icons.nightlight_outlined, 'Ramadan', 'Fasting tools', const RamadanPage())),
        ]),
        const SizedBox(height: 14),
        glass(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(children: [const Icon(Icons.calendar_month, color: gold), const SizedBox(width: 10), Expanded(child: Text(DateFormat('EEEE, d MMMM y').format(date)))]),
              const SizedBox(height: 10),
              const Text('Quran, prayer times, Qibla, duas and dhikr — all in one place.', style: TextStyle(color: Colors.white54, height: 1.45)),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _action(BuildContext context, IconData icon, String title, String subtitle, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      borderRadius: BorderRadius.circular(22),
      child: glass(context, padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: gold, size: 28),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ])),
    );
  }
}

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final service = QuranService();
  late Future<List<Surah>> future;
  String query = '';

  @override
  void initState() {
    super.initState();
    future = service.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Surah>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Quran data could not be loaded.'),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => setState(() => future = service.load()), child: const Text('Retry')),
          ]));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final q = query.toLowerCase();
        final list = snapshot.data!.where((s) => s.englishName.toLowerCase().contains(q) || s.name.contains(query)).toList();
        return ListView(padding: const EdgeInsets.all(18), children: [
          const Text('Quran', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('القرآن الكريم', style: TextStyle(color: gold, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search a Surah')),
          const SizedBox(height: 14),
          glass(context, child: const Row(children: [Icon(Icons.collections_bookmark_outlined, color: gold), SizedBox(width: 12), Expanded(child: Text('114 Surahs • Arabic Quran', style: TextStyle(fontWeight: FontWeight.w700)))])),
          const SizedBox(height: 12),
          ...list.map((s) => Card(
            color: Colors.white.withValues(alpha: 0.04),
            child: ListTile(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(surah: s))),
              leading: CircleAvatar(backgroundColor: emerald, child: Text('${s.number}')),
              title: Text(s.englishName, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${s.revelationType} · ${s.ayahs} Ayahs'),
              trailing: Text(s.name, style: const TextStyle(fontSize: 18)),
            ),
          )),
        ]);
      },
    );
  }
}

class ReaderPage extends StatefulWidget {
  final Surah surah;
  const ReaderPage({super.key, required this.surah});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final player = AudioPlayer();
  int? playing;

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> play(Ayah ayah) async {
    if (playing == ayah.number) {
      await player.stop();
      if (mounted) setState(() => playing = null);
      return;
    }
    await player.stop();
    await player.play(UrlSource('https://cdn.islamic.network/quran/audio/128/ar.alafasy/${ayah.number}.mp3'));
    if (mounted) setState(() => playing = ayah.number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.surah.englishName)),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        glass(context, child: Column(children: [
          Text(widget.surah.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(widget.surah.translation, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 8),
          Text('${widget.surah.revelationType} · ${widget.surah.ayahs} verses', style: const TextStyle(color: gold, fontSize: 12)),
        ])),
        const SizedBox(height: 14),
        ...widget.surah.verses.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: glass(context, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              CircleAvatar(radius: 15, backgroundColor: emerald, child: Text('${a.numberInSurah}', style: const TextStyle(fontSize: 11))),
              const Spacer(),
              IconButton(onPressed: () => play(a), icon: Icon(playing == a.number ? Icons.stop_circle : Icons.play_circle_outline, color: gold)),
            ]),
            Text(a.text, textAlign: TextAlign.right, style: const TextStyle(fontSize: 27, height: 1.9, fontWeight: FontWeight.w600)),
          ])),
        )),
      ]),
    );
  }
}

class PrayerPage extends StatefulWidget {
  final AlarmService alarms;
  const PrayerPage({super.key, required this.alarms});

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  List<PrayerEntry>? prayers;
  bool loading = false;
  String place = 'Location not set';

  Future<void> load() async {
    setState(() => loading = true);
    final p = await PrayerService().location();
    if (p != null) {
      final list = PrayerService().calculate(p.latitude, p.longitude, DateTime.now());
      await widget.alarms.scheduleAll(list);
      if (mounted) setState(() { prayers = list; place = '${p.latitude.toStringAsFixed(2)}, ${p.longitude.toStringAsFixed(2)}'; });
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(18), children: [
      Row(children: [const Expanded(child: Text('Prayer Times', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))), IconButton(onPressed: loading ? null : load, icon: const Icon(Icons.my_location, color: gold))]),
      Text(place, style: const TextStyle(color: Colors.white54)),
      const SizedBox(height: 18),
      if (prayers == null)
        glass(context, child: Column(children: [
          const Icon(Icons.location_on_outlined, color: gold, size: 45),
          const SizedBox(height: 10),
          const Text('Allow location to calculate local prayer times.', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: loading ? null : load, child: Text(loading ? 'Finding location…' : 'Use my location')),
        ]))
      else
        ...prayers!.map((p) => Padding(padding: const EdgeInsets.only(bottom: 10), child: glass(context, child: Row(children: [
          CircleAvatar(backgroundColor: emerald, child: const Icon(Icons.mosque_outlined)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)), Text(p.arabic, style: const TextStyle(color: gold))])),
          Text(DateFormat('h:mm a').format(p.time), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        ]))),
    ]);
  }
}

class DhikrPage extends StatefulWidget {
  const DhikrPage({super.key});

  @override
  State<DhikrPage> createState() => _DhikrPageState();
}

class _DhikrPageState extends State<DhikrPage> {
  int count = 0;
  int target = 33;
  String dhikr = 'SubhanAllah';

  @override
  Widget build(BuildContext context) {
    const options = ['SubhanAllah', 'Alhamdulillah', 'Allahu Akbar', 'La ilaha illallah', 'Astaghfirullah'];
    return ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Tasbeeh', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
      const SizedBox(height: 18),
      DropdownButtonFormField<String>(
        initialValue: dhikr,
        decoration: const InputDecoration(labelText: 'Dhikr'),
        items: options.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
        onChanged: (v) => setState(() => dhikr = v ?? dhikr),
      ),
      const SizedBox(height: 14),
      glass(context, child: Column(children: [
        Text(dhikr, style: const TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Text('$count', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900)),
        Text('Target $target', style: const TextStyle(color: Colors.white54)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => setState(() => count = count >= target ? 0 : count + 1),
          child: Container(width: 190, height: 190, decoration: BoxDecoration(shape: BoxShape.circle, color: emerald, border: Border.all(color: gold, width: 2)), child: const Center(child: Text('TAP', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)))),
        ),
        const SizedBox(height: 18),
        Wrap(spacing: 8, children: [33, 34, 99, 100].map((x) => ChoiceChip(label: Text('$x'), selected: target == x, onSelected: (_) => setState(() { target = x; count = 0; }))).toList()),
        TextButton(onPressed: () => setState(() => count = 0), child: const Text('Reset')),
      ])),
    ]);
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Explore', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
      const SizedBox(height: 16),
      _menu(context, Icons.explore, 'Qibla', 'Find the direction of the Kaaba', const QiblaPage()),
      _menu(context, Icons.favorite, 'Duas & Adhkar', 'Daily supplications', const DuasPage()),
      _menu(context, Icons.nightlight, 'Ramadan', 'Fasting and worship tools', const RamadanPage()),
      _menu(context, Icons.headphones, 'Quran Audio', 'Listen to recitations', const AudioQuranPage()),
      _menu(context, Icons.settings_outlined, 'Settings', 'App settings', const SettingsPage()),
    ]);
  }

  static Widget _menu(BuildContext context, IconData icon, String title, String subtitle, Widget page) {
    return Card(child: ListTile(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      leading: CircleAvatar(backgroundColor: emerald, child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ));
  }
}

class DuasPage extends StatelessWidget {
  const DuasPage({super.key});
  static const groups = <List<String>>[
    ['Morning', 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ', 'We have entered the morning and the dominion belongs to Allah.'],
    ['Evening', 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ', 'We have entered the evening and the dominion belongs to Allah.'],
    ['Before sleep', 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا', 'In Your name, O Allah, I die and I live.'],
    ['Seeking forgiveness', 'أَسْتَغْفِرُ اللَّهَ', 'I seek forgiveness from Allah.'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Duas & Adhkar')), body: ListView(padding: const EdgeInsets.all(18), children: [
      ...groups.map((d) => Padding(padding: const EdgeInsets.only(bottom: 12), child: glass(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(d[0], style: const TextStyle(color: gold, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(d[1], textAlign: TextAlign.right, style: const TextStyle(fontSize: 23, height: 1.7)),
        const SizedBox(height: 8),
        Text(d[2], style: const TextStyle(color: Colors.white70, height: 1.45)),
      ])))),
    ]));
  }
}

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  double? qibla;
  String status = 'Finding your location…';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final p = await PrayerService().location();
    if (p == null) {
      if (mounted) setState(() => status = 'Location permission is required.');
      return;
    }
    final lat1 = p.latitude * math.pi / 180;
    final lon1 = p.longitude * math.pi / 180;
    const lat2 = 21.422487 * math.pi / 180;
    const lon2 = 39.826206 * math.pi / 180;
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = (math.atan2(y, x) * 180 / math.pi + 360) % 360;
    if (mounted) setState(() { qibla = bearing; status = 'Qibla bearing from your location'; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Qibla')), body: Center(child: Padding(padding: const EdgeInsets.all(22), child: qibla == null
      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.explore_outlined, size: 80, color: gold), const SizedBox(height: 16), Text(status, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: load, child: const Text('Try again'))])
      : glass(context, child: Column(children: [const Icon(Icons.navigation, size: 100, color: gold), const SizedBox(height: 12), Text('${qibla!.round()}°', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text(status, style: const TextStyle(color: Colors.white54)), const SizedBox(height: 18), const Text('Point your phone toward this bearing. Live compass mode can be added next.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, height: 1.4))]))));
  }
}

class RamadanPage extends StatelessWidget {
  const RamadanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Ramadan')), body: ListView(padding: const EdgeInsets.all(18), children: [
      glass(context, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('رمضان كريم', style: TextStyle(fontSize: 30, color: gold, fontWeight: FontWeight.w800)), SizedBox(height: 10), Text('Use local Fajr and Maghrib prayer times for Suhoor and Iftar. Lunar dates can vary by location and moon sighting.', style: TextStyle(color: Colors.white60, height: 1.5))])),
      const SizedBox(height: 14),
      _card(context, Icons.wb_twilight, 'Suhoor', 'Finish eating and drinking before Fajr.'),
      _card(context, Icons.nights_stay, 'Iftar', 'Break the fast at Maghrib.'),
      _card(context, Icons.menu_book, 'Quran goal', 'Set a daily Quran reading target.'),
      _card(context, Icons.favorite, 'Duas', 'Keep daily duas and dhikr close.'),
    ]));
  }

  static Widget _card(BuildContext c, IconData icon, String title, String text) => Padding(padding: const EdgeInsets.only(bottom: 12), child: glass(c, child: Row(children: [CircleAvatar(backgroundColor: emerald, child: Icon(icon)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(text, style: const TextStyle(color: Colors.white54))]))])));
}

class AudioQuranPage extends StatefulWidget {
  const AudioQuranPage({super.key});

  @override
  State<AudioQuranPage> createState() => _AudioQuranPageState();
}

class _AudioQuranPageState extends State<AudioQuranPage> {
  final service = QuranService();
  final player = AudioPlayer();
  int? playing;

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> play(int number) async {
    if (playing == number) {
      await player.stop();
      if (mounted) setState(() => playing = null);
      return;
    }
    await player.stop();
    await player.play(UrlSource('https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/$number.mp3'));
    if (mounted) setState(() => playing = number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Quran Audio')), body: FutureBuilder<List<Surah>>(future: service.load(), builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      return ListView(padding: const EdgeInsets.all(18), children: snapshot.data!.map((s) => Card(child: ListTile(
        onTap: () => play(s.number),
        leading: CircleAvatar(backgroundColor: emerald, child: Text('${s.number}')),
        title: Text(s.englishName),
        subtitle: Text(s.name),
        trailing: Icon(playing == s.number ? Icons.stop_circle : Icons.play_circle_fill, color: gold),
      ))).toList());
    }));
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Settings')), body: ListView(padding: const EdgeInsets.all(18), children: [
      glass(context, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('HudaWay', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), SizedBox(height: 6), Text('A Muslim companion for Quran, prayer, Qibla, duas and dhikr.', style: TextStyle(color: Colors.white60))])),
      const SizedBox(height: 12),
      const Card(child: ListTile(leading: Icon(Icons.notifications_outlined, color: gold), title: Text('Prayer notifications'), subtitle: Text('Enable notifications from the Prayer page.'))),
      const Card(child: ListTile(leading: Icon(Icons.language, color: gold), title: Text('Languages'), subtitle: Text('Arabic and English content.'))),
      const Card(child: ListTile(leading: Icon(Icons.info_outline, color: gold), title: Text('About HudaWay'), subtitle: Text('Version 1.0.0'))),
    ]);
  }
}
