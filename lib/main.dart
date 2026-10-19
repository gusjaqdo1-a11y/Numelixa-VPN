import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';
import 'services.dart';

const Color emerald = Color(0xFF0B5D45);
const Color deep = Color(0xFF061A14);
const Color gold = Color(0xFFD6A63A);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final alarms = AlarmService();
  try {
    await alarms.init();
  } catch (_) {}
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
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
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
        onDestinationSelected: (value) => setState(() => index = value),
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

Widget panel({required Widget child, EdgeInsets padding = const EdgeInsets.all(18)}) {
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
    final today = DateFormat('EEEE, d MMMM y').format(DateTime.now());
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(color: emerald, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.auto_awesome, color: gold, size: 30),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assalamu Alaikum', style: TextStyle(color: Colors.white60)),
                  Text('HudaWay', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        const SizedBox(height: 22),
        panel(
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Icon(Icons.auto_awesome, color: gold), SizedBox(width: 8), Text('Ayah of the day', style: TextStyle(color: gold, fontWeight: FontWeight.bold))]),
              SizedBox(height: 14),
              Text('إِنَّ مَعَ الْعُسْرِ يُسْرًا', textAlign: TextAlign.right, style: TextStyle(fontSize: 29, height: 1.8, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('Indeed, with hardship comes ease.', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 4),
              Text('Ash-Sharh · 94:6', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _quick(context, Icons.menu_book, 'Quran', 'Read & listen', const QuranPage())),
            const SizedBox(width: 12),
            Expanded(child: _quick(context, Icons.explore, 'Qibla', 'Find direction', const QiblaPage())),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _quick(context, Icons.favorite_outline, 'Duas', 'Daily adhkar', const DuasPage())),
            const SizedBox(width: 12),
            Expanded(child: _quick(context, Icons.nightlight_outlined, 'Ramadan', 'Fasting tools', const RamadanPage())),
          ],
        ),
        const SizedBox(height: 14),
        panel(
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: gold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(today, style: const TextStyle(color: Colors.white60)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _quick(BuildContext context, IconData icon, String title, String subtitle, Widget page) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      borderRadius: BorderRadius.circular(22),
      child: panel(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: gold, size: 28),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  final QuranService service = QuranService();
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: gold, size: 48),
                  const SizedBox(height: 12),
                  const Text('Quran data could not be loaded.', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: () => setState(() => future = service.load()), child: const Text('Retry')),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final text = query.trim().toLowerCase();
        final surahs = snapshot.data!.where((surah) {
          return text.isEmpty ||
              surah.englishName.toLowerCase().contains(text) ||
              surah.name.contains(query.trim());
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('Quran', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('القرآن الكريم', style: TextStyle(color: gold, fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search a Surah'),
            ),
            const SizedBox(height: 14),
            panel(
              child: const Row(
                children: [
                  Icon(Icons.menu_book, color: gold),
                  SizedBox(width: 12),
                  Expanded(child: Text('114 Surahs · Arabic Quran', style: TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...surahs.map((surah) => Card(
              color: Colors.white.withValues(alpha: 0.04),
              child: ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(surah: surah))),
                leading: CircleAvatar(backgroundColor: emerald, child: Text('${surah.number}')),
                title: Text(surah.englishName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${surah.revelationType} · ${surah.ayahs} Ayahs'),
                trailing: Text(surah.name, style: const TextStyle(fontSize: 18)),
              ),
            )),
          ],
        );
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
  final AudioPlayer player = AudioPlayer();
  int? playing;

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> playAyah(Ayah ayah) async {
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
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          panel(
            child: Column(
              children: [
                Text(widget.surah.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(widget.surah.translation, style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 8),
                Text('${widget.surah.revelationType} · ${widget.surah.ayahs} verses', style: const TextStyle(color: gold, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...widget.surah.verses.map((ayah) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 15, backgroundColor: emerald, child: Text('${ayah.numberInSurah}', style: const TextStyle(fontSize: 11))),
                      const Spacer(),
                      IconButton(
                        onPressed: () => playAyah(ayah),
                        icon: Icon(playing == ayah.number ? Icons.stop_circle : Icons.play_circle_outline, color: gold),
                      ),
                    ],
                  ),
                  Text(ayah.text, textAlign: TextAlign.right, style: const TextStyle(fontSize: 27, height: 1.9, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          )),
        ],
      ),
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
  String locationText = 'Location not set';

  Future<void> loadPrayerTimes() async {
    setState(() => loading = true);
    try {
      final position = await PrayerService().location();
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable location permission.')));
        }
        return;
      }

      final list = PrayerService().calculate(position.latitude, position.longitude, DateTime.now());
      await widget.alarms.scheduleAll(list);
      if (mounted) {
        setState(() {
          prayers = list;
          locationText = '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not calculate prayer times: $error')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          children: [
            const Expanded(child: Text('Prayer Times', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))),
            IconButton(onPressed: loading ? null : loadPrayerTimes, icon: const Icon(Icons.my_location, color: gold)),
          ],
        ),
        Text(locationText, style: const TextStyle(color: Colors.white54)),
        const SizedBox(height: 18),
        if (prayers == null)
          panel(
            child: Column(
              children: [
                const Icon(Icons.location_on_outlined, color: gold, size: 48),
                const SizedBox(height: 10),
                const Text('Allow location to calculate your local prayer times.', textAlign: TextAlign.center),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: loading ? null : loadPrayerTimes,
                  child: Text(loading ? 'Finding location…' : 'Use my location'),
                ),
              ],
            ),
          )
        else
          ...prayers!.map((prayer) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: panel(
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: emerald, child: const Icon(Icons.mosque_outlined)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(prayer.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(prayer.arabic, style: const TextStyle(color: gold)),
                      ],
                    ),
                  ),
                  Text(DateFormat('h:mm a').format(prayer.time), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          )),
      ],
    );
  }
}

class DhikrPage extends StatefulWidget {
  const DhikrPage({super.key});

  @override
  State<DhikrPage> createState() => _DhikrPageState();
}

class _DhikrPageState extends State<DhikrPage> {
  static const options = ['SubhanAllah', 'Alhamdulillah', 'Allahu Akbar', 'La ilaha illallah', 'Astaghfirullah'];
  int count = 0;
  int target = 33;
  String dhikr = 'SubhanAllah';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('Tasbeeh', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          initialValue: dhikr,
          decoration: const InputDecoration(labelText: 'Dhikr'),
          items: options.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
          onChanged: (value) => setState(() => dhikr = value ?? dhikr),
        ),
        const SizedBox(height: 14),
        panel(
          child: Column(
            children: [
              Text(dhikr, style: const TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 18),
              Text('$count', style: const TextStyle(fontSize: 76, fontWeight: FontWeight.w900)),
              Text('Target $target', style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => setState(() => count = count >= target ? 0 : count + 1),
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: emerald, border: Border.all(color: gold, width: 2)),
                  child: const Center(child: Text('TAP', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900))),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                children: [33, 34, 99, 100].map((value) => ChoiceChip(
                  label: Text('$value'),
                  selected: target == value,
                  onSelected: (_) => setState(() { target = value; count = 0; }),
                )).toList(),
              ),
              TextButton(onPressed: () => setState(() => count = 0), child: const Text('Reset')),
            ],
          ),
        ),
      ],
    );
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('Explore', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        _item(context, Icons.explore, 'Qibla', 'Find the direction of the Kaaba', const QiblaPage()),
        _item(context, Icons.favorite, 'Duas & Adhkar', 'Daily supplications', const DuasPage()),
        _item(context, Icons.nightlight, 'Ramadan', 'Fasting and worship tools', const RamadanPage()),
        _item(context, Icons.headphones, 'Quran Audio', 'Listen to recitations', const AudioQuranPage()),
        _item(context, Icons.settings_outlined, 'Settings', 'App information', const SettingsPage()),
      ],
    );
  }

  static Widget _item(BuildContext context, IconData icon, String title, String subtitle, Widget page) {
    return Card(
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        leading: CircleAvatar(backgroundColor: emerald, child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class DuasPage extends StatelessWidget {
  const DuasPage({super.key});

  static const duas = <Map<String, String>>[
    {'title': 'Morning', 'arabic': 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ', 'meaning': 'We have entered the morning and the dominion belongs to Allah.'},
    {'title': 'Evening', 'arabic': 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ', 'meaning': 'We have entered the evening and the dominion belongs to Allah.'},
    {'title': 'Before sleep', 'arabic': 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا', 'meaning': 'In Your name, O Allah, I die and I live.'},
    {'title': 'After waking', 'arabic': 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا', 'meaning': 'Praise belongs to Allah who gave us life after causing us to die.'},
    {'title': 'Seeking forgiveness', 'arabic': 'أَسْتَغْفِرُ اللَّهَ', 'meaning': 'I seek forgiveness from Allah.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duas & Adhkar')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          panel(child: const Text('Daily supplications. Religious references should be checked against an authenticated source.', style: TextStyle(color: Colors.white60, height: 1.5))),
          const SizedBox(height: 14),
          ...duas.map((dua) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dua['title']!, style: const TextStyle(color: gold, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(dua['arabic']!, textAlign: TextAlign.right, style: const TextStyle(fontSize: 23, height: 1.7)),
                  const SizedBox(height: 8),
                  Text(dua['meaning']!, style: const TextStyle(color: Colors.white70, height: 1.45)),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  double? bearing;
  String status = 'Finding your location…';

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final position = await PrayerService().location();
    if (position == null) {
      if (mounted) setState(() => status = 'Location permission is required.');
      return;
    }

    const kaabaLat = 21.422487;
    const kaabaLon = 39.826206;
    final lat1 = position.latitude * math.pi / 180;
    final lon1 = position.longitude * math.pi / 180;
    final lat2 = kaabaLat * math.pi / 180;
    final lon2 = kaabaLon * math.pi / 180;
    final deltaLon = lon2 - lon1;
    final y = math.sin(deltaLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);
    final value = (math.atan2(y, x) * 180 / math.pi + 360) % 360;

    if (mounted) {
      setState(() {
        bearing = value;
        status = 'Qibla bearing from your location';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qibla')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: bearing == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.explore_outlined, size: 80, color: gold),
                    const SizedBox(height: 16),
                    Text(status, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: load, child: const Text('Try again')),
                  ],
                )
              : panel(
                  child: Column(
                    children: [
                      const Icon(Icons.navigation, size: 100, color: gold),
                      const SizedBox(height: 12),
                      Text('${bearing!.round()}°', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(status, style: const TextStyle(color: Colors.white54)),
                      const SizedBox(height: 18),
                      const Text('Point your phone toward the calculated bearing. Live compass support can be enabled on compatible devices.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, height: 1.4)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class RamadanPage extends StatelessWidget {
  const RamadanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ramadan')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          panel(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('رمضان كريم', style: TextStyle(fontSize: 30, color: gold, fontWeight: FontWeight.w800)),
                SizedBox(height: 10),
                Text('Use local Fajr and Maghrib prayer times for suhoor and iftar. Lunar dates may vary by location and moon sighting.', style: TextStyle(color: Colors.white60, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(Icons.wb_twilight, 'Suhoor', 'Finish eating and drinking before Fajr.'),
          _card(Icons.nights_stay, 'Iftar', 'Break the fast at Maghrib.'),
          _card(Icons.menu_book, 'Quran goal', 'Set a daily Quran reading target.'),
          _card(Icons.favorite, 'Duas', 'Keep daily duas and dhikr close.'),
        ],
      ),
    );
  }

  static Widget _card(IconData icon, String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: panel(
        child: Row(
          children: [
            CircleAvatar(backgroundColor: emerald, child: Icon(icon)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(text, style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AudioQuranPage extends StatefulWidget {
  final int? surahNumber;
  const AudioQuranPage({super.key, this.surahNumber});

  @override
  State<AudioQuranPage> createState() => _AudioQuranPageState();
}

class _AudioQuranPageState extends State<AudioQuranPage> {
  final QuranService service = QuranService();
  final AudioPlayer player = AudioPlayer();
  int? playing;
  late Future<List<Surah>> future;

  @override
  void initState() {
    super.initState();
    future = service.load();
  }

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
    return Scaffold(
      appBar: AppBar(title: const Text('Quran Audio')),
      body: FutureBuilder<List<Surah>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Could not load Quran audio list: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final list = widget.surahNumber == null ? snapshot.data! : snapshot.data!.where((item) => item.number == widget.surahNumber).toList();
          return ListView(
            padding: const EdgeInsets.all(18),
            children: list.map((surah) => Card(
              child: ListTile(
                onTap: () => play(surah.number),
                leading: CircleAvatar(backgroundColor: emerald, child: Text('${surah.number}')),
                title: Text(surah.englishName),
                subtitle: Text(surah.name),
                trailing: Icon(playing == surah.number ? Icons.stop_circle : Icons.play_circle_fill, color: gold),
              ),
            )).toList(),
          );
        },
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          panel(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HudaWay', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('Quran, prayer, Qibla, duas and dhikr in one app.', style: TextStyle(color: Colors.white60)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Card(child: ListTile(leading: Icon(Icons.notifications_outlined, color: gold), title: Text('Prayer notifications'), subtitle: Text('Prayer notifications are scheduled from the Prayer page.'))),
          const Card(child: ListTile(leading: Icon(Icons.language, color: gold), title: Text('Languages'), subtitle: Text('Arabic and English content.'))),
          const Card(child: ListTile(leading: Icon(Icons.info_outline, color: gold), title: Text('About HudaWay'), subtitle: Text('Version 1.0.0'))),
        ],
      ),
    );
  }
}
