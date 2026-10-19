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
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HudaWay',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          brightness: Brightness.dark,
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
      DashboardPage(alarms: widget.alarms),
      const QuranPage(),
      PrayerPage(alarms: widget.alarms),
      const DhikrPage(),
      MorePage(alarms: widget.alarms),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Quran',
          ),
          NavigationDestination(
            icon: Icon(Icons.mosque_outlined),
            selectedIcon: Icon(Icons.mosque),
            label: 'Prayer',
          ),
          NavigationDestination(
            icon: Icon(Icons.fingerprint),
            selectedIcon: Icon(Icons.fingerprint),
            label: 'Dhikr',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

Widget appBox(Widget child) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.055),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white12),
    ),
    child: child,
  );
}

class DashboardPage extends StatefulWidget {
  final AlarmService alarms;

  const DashboardPage({super.key, required this.alarms});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<PrayerEntry>? prayers;

  @override
  void initState() {
    super.initState();
    _loadPrayerPreview();
  }

  Future<void> _loadPrayerPreview() async {
    try {
      final service = PrayerService();
      await service.localZone();
      final position = await service.location();
      if (position == null || !mounted) return;
      final result = service.calculate(
        position.latitude,
        position.longitude,
        DateTime.now(),
      );
      if (mounted) setState(() => prayers = result);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Assalamu Alaikum',
          style: TextStyle(color: Colors.white60),
        ),
        const Text(
          'HudaWay',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        appBox(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ayah of the Day',
                style: TextStyle(color: gold, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 28,
                  height: 1.8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text('Indeed, with hardship comes ease.'),
              Text(
                'Ash-Sharh 94:6',
                style: TextStyle(color: Colors.white38),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        appBox(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Today’s Prayer Times',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (prayers == null)
                const Text(
                  'Allow location to calculate prayer times.',
                  style: TextStyle(color: Colors.white54),
                )
              else
                ...prayers!
                    .where((item) => item.name != 'Sunrise')
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(item.name),
                            const Spacer(),
                            Text(
                              DateFormat('h:mm a').format(item.time),
                              style: const TextStyle(
                                color: gold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _featureTile(
              context,
              Icons.menu_book,
              'Quran',
              const QuranPage(),
            ),
            _featureTile(
              context,
              Icons.explore,
              'Qibla',
              const QiblaPage(),
            ),
            _featureTile(
              context,
              Icons.favorite_outline,
              'Duas',
              const DuasPage(),
            ),
            _featureTile(
              context,
              Icons.nightlight_outlined,
              'Ramadan',
              const RamadanPage(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _featureTile(
    BuildContext context,
    IconData icon,
    String title,
    Widget page,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => page),
        );
      },
      child: appBox(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: gold, size: 30),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
  late Future<List<Surah>> future;
  String query = '';

  @override
  void initState() {
    super.initState();
    future = QuranService().load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Surah>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: FilledButton.icon(
              onPressed: () {
                setState(() => future = QuranService().load());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Quran'),
            ),
          );
        }

        final all = snapshot.data!;
        final normalized = query.trim().toLowerCase();
        final list = normalized.isEmpty
            ? all
            : all
                .where(
                  (surah) =>
                      surah.englishName.toLowerCase().contains(normalized) ||
                      surah.name.contains(query.trim()) ||
                      surah.number.toString() == normalized,
                )
                .toList();

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Quran Kareem',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const Text(
              'القرآن الكريم',
              style: TextStyle(color: gold, fontSize: 20),
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search Surah',
              ),
            ),
            const SizedBox(height: 12),
            appBox(const Text('114 Surahs • 6236 Ayahs')),
            const SizedBox(height: 8),
            ...list.map(
              (surah) => Card(
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ReaderPage(surah: surah),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: green,
                    child: Text('${surah.number}'),
                  ),
                  title: Text(surah.englishName),
                  subtitle: Text('${surah.verses.length} Ayahs'),
                  trailing: Text(
                    surah.name,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
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
  double fontSize = 28;
  int? playing;

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> playAyah(Ayah ayah) async {
    try {
      if (playing == ayah.number) {
        await player.stop();
        if (mounted) setState(() => playing = null);
        return;
      }

      await player.stop();
      await player.play(
        UrlSource(
          'https://cdn.islamic.network/quran/audio/128/ar.alafasy/${ayah.number}.mp3',
        ),
      );
      if (mounted) setState(() => playing = ayah.number);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio could not be played.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surah.englishName),
        actions: [
          IconButton(
            onPressed: () => setState(
              () => fontSize = math.min(42, fontSize + 2),
            ),
            icon: const Icon(Icons.text_increase),
          ),
          IconButton(
            onPressed: () => setState(
              () => fontSize = math.max(20, fontSize - 2),
            ),
            icon: const Icon(Icons.text_decrease),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          appBox(
            Column(
              children: [
                Text(
                  widget.surah.name,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.surah.translation,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ...widget.surah.verses.map(
            (ayah) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: appBox(
                Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: green,
                          radius: 15,
                          child: Text('${ayah.numberInSurah}'),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => playAyah(ayah),
                          icon: Icon(
                            playing == ayah.number
                                ? Icons.stop_circle
                                : Icons.play_circle_outline,
                            color: gold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      ayah.text,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 1.9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (loading) return;
    setState(() => loading = true);

    try {
      final service = PrayerService();
      await service.localZone();
      final position = await service.location();
      if (position == null) {
        throw Exception('Location permission or GPS is disabled.');
      }

      final list = service.calculate(
        position.latitude,
        position.longitude,
        DateTime.now(),
      );

      try {
        await widget.alarms.scheduleAll(list);
      } catch (_) {}

      if (mounted) setState(() => prayers = list);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
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
            const Expanded(
              child: Text(
                'Prayer Times',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              onPressed: loading ? null : load,
              icon: const Icon(Icons.refresh, color: gold),
            ),
          ],
        ),
        if (prayers == null)
          appBox(
            Column(
              children: [
                const Icon(Icons.location_on, color: gold, size: 48),
                const SizedBox(height: 10),
                const Text(
                  'Use your location for accurate prayer times.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: loading ? null : load,
                  child: Text(loading ? 'Loading…' : 'Use my location'),
                ),
              ],
            ),
          )
        else
          ...prayers!.map(
            (prayer) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: appBox(
                Row(
                  children: [
                    Icon(
                      prayer.name == 'Sunrise'
                          ? Icons.wb_sunny
                          : Icons.mosque,
                      color: gold,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${prayer.name}\n${prayer.arabic}'),
                    ),
                    Text(
                      DateFormat('h:mm a').format(prayer.time),
                      style: const TextStyle(
                        color: gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  StreamSubscription<CompassEvent>? subscription;
  double? heading;
  double? qibla;

  @override
  void initState() {
    super.initState();
    _start();
  }

  double bearing(double latitude, double longitude) {
    const kaabaLat = 21.422487;
    const kaabaLon = 39.826206;

    final lat = latitude * math.pi / 180;
    final targetLat = kaabaLat * math.pi / 180;
    final deltaLon = (kaabaLon - longitude) * math.pi / 180;

    final value = math.atan2(
      math.sin(deltaLon) * math.cos(targetLat),
      math.cos(lat) * math.sin(targetLat) -
          math.sin(lat) * math.cos(targetLat) * math.cos(deltaLon),
    );

    return (value * 180 / math.pi + 360) % 360;
  }

  Future<void> _start() async {
    try {
      final position = await PrayerService().location();
      if (position == null) return;

      if (mounted) {
        setState(() {
          qibla = bearing(position.latitude, position.longitude);
        });
      }

      subscription = FlutterCompass.events?.listen((event) {
        final value = event.heading;
        if (!mounted || value == null) return;
        setState(() => heading = value);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final angle = ((qibla ?? 0) - (heading ?? 0)) * math.pi / 180;

    return Scaffold(
      appBar: AppBar(title: const Text('Qibla Finder')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          appBox(
            Column(
              children: [
                const Text(
                  'QIBLA',
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  qibla == null
                      ? 'Location unavailable'
                      : '${qibla!.toStringAsFixed(1)}° from North',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 20),
                Transform.rotate(
                  angle: angle,
                  child: const Icon(
                    Icons.navigation,
                    size: 180,
                    color: gold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Keep the phone flat and calibrate the compass.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DhikrPage extends StatefulWidget {
  const DhikrPage({super.key});

  @override
  State<DhikrPage> createState() => _DhikrPageState();
}

class _DhikrPageState extends State<DhikrPage> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dhikr & Tasbeeh')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'سُبْحَانَ اللَّهِ',
              style: TextStyle(fontSize: 30),
            ),
            const SizedBox(height: 20),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 70,
                fontWeight: FontWeight.w900,
                color: gold,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => setState(() => count++),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Text('TAP', style: TextStyle(fontSize: 22)),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => count = 0),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}

class DuasPage extends StatelessWidget {
  const DuasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duas & Adhkar')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          DuaCard(
            'Morning',
            'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا',
          ),
          DuaCard(
            'Forgiveness',
            'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ',
          ),
          DuaCard(
            'Protection',
            'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
          ),
        ],
      ),
    );
  }
}

class DuaCard extends StatelessWidget {
  final String title;
  final String text;

  const DuaCard(this.title, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: appBox(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 24, height: 1.8),
            ),
          ],
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
          appBox(
            const Column(
              children: [
                Icon(Icons.nightlight_round, color: gold, size: 55),
                SizedBox(height: 14),
                Text(
                  'Ramadan Tools',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Use Prayer Times for Fajr and Maghrib to follow your daily fasting schedule.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MorePage extends StatefulWidget {
  final AlarmService alarms;

  const MorePage({super.key, required this.alarms});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  String sound = 'adhan_kuwait';

  @override
  void initState() {
    super.initState();
    _loadSound();
  }

  Future<void> _loadSound() async {
    try {
      final value = await AlarmService.sound();
      if (mounted) setState(() => sound = value);
    } catch (_) {}
  }

  Future<void> _changeSound(String value) async {
    try {
      await AlarmService.setSound(value);
      if (mounted) setState(() => sound = value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'More',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.explore, color: gold),
          title: const Text('Qibla'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const QiblaPage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.favorite, color: gold),
          title: const Text('Duas'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const DuasPage()),
            );
          },
        ),
        const Divider(),
        const ListTile(
          title: Text(
            'Adhan Sound',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        RadioListTile<String>(
          value: 'adhan_kuwait',
          groupValue: sound,
          title: const Text('Kuwait'),
          onChanged: (value) {
            if (value != null) _changeSound(value);
          },
        ),
        RadioListTile<String>(
          value: 'adhan_dubai',
          groupValue: sound,
          title: const Text('Dubai'),
          onChanged: (value) {
            if (value != null) _changeSound(value);
          },
        ),
        RadioListTile<String>(
          value: 'adhan_fajr',
          groupValue: sound,
          title: const Text('Fajr'),
          onChanged: (value) {
            if (value != null) _changeSound(value);
          },
        ),
      ],
    );
  }
}
