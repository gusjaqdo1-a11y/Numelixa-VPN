import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:adhan_dart/adhan_dart.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'services.dart';

const forest = Color(0xFF0B5D45);
const ink = Color(0xFF071B15);
const gold = Color(0xFFD6A63A);
const paper = Color(0xFFF7F1E4);

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
          scaffoldBackgroundColor: ink,
          colorScheme: ColorScheme.fromSeed(seedColor: forest, brightness: Brightness.dark),
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
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Quran'),
          NavigationDestination(icon: Icon(Icons.mosque_outlined), selectedIcon: Icon(Icons.mosque), label: 'Prayer'),
          NavigationDestination(icon: Icon(Icons.fingerprint), selectedIcon: Icon(Icons.fingerprint), label: 'Dhikr'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'More'),
        ],
      ),
    );
  }
}

Widget appBox(Widget child, {Color? color}) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: color ?? Colors.white.withValues(alpha: .055), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white12)),
      child: child,
    );

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 48});
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(size * .22), child: SvgPicture.asset('assets/brand/logo.svg', width: size, height: size));
}

class DashboardPage extends StatefulWidget {
  final AlarmService alarms;
  const DashboardPage({super.key, required this.alarms});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<PrayerEntry>? prayers;
  String place = 'Location not set';
  String hijri = '1448 AH';
  Timer? ticker;
  DateTime now = DateTime.now();
  @override
  void initState() {
    super.initState();
    _refresh();
    ticker = Timer.periodic(const Duration(minutes: 1), (_) { if (mounted) setState(() => now = DateTime.now()); });
  }
  @override
  void dispose() { ticker?.cancel(); super.dispose(); }
  Future<void> _refresh() async {
    final service = PrayerService();
    try {
      await service.localZone();
      final pos = await service.location();
      if (pos != null) {
        final list = service.calculate(pos.latitude, pos.longitude, DateTime.now(), method: await Preferences.prayerMethod(), madhab: await Preferences.madhabValue());
        final name = await service.reversePlace(pos.latitude, pos.longitude);
        if (mounted) setState(() { prayers = list; place = name; });
        await widget.alarms.scheduleNextDays(service, days: 7);
      }
    } catch (_) {}
    final h = await HijriService.today();
    if (mounted && h != null) {
      setState(() => hijri = h.display);
      if (await Preferences.lockCalendar()) await widget.alarms.showLockCalendar(h.display);
    }
  }
  PrayerEntry? _next() {
    final list = prayers?.where((p) => p.name != 'Sunrise').toList();
    if (list == null || list.isEmpty) return null;
    for (final p in list) { if (p.time.isAfter(now)) return p; }
    return null;
  }
  @override
  Widget build(BuildContext context) {
    final next = _next();
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          Row(children: [const BrandMark(size: 54), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Assalamu Alaikum', style: TextStyle(color: Colors.white60)), Text('HudaWay', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))]))]),
          const SizedBox(height: 16),
          appBox(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(place, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 5), Text(DateFormat('EEEE, d MMMM yyyy').format(now), style: const TextStyle(fontWeight: FontWeight.bold)), Text(hijri, style: const TextStyle(color: gold, fontSize: 17, fontWeight: FontWeight.w700)), const SizedBox(height: 10), Text(DateFormat('h:mm:ss a').format(now), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900))])),
          const SizedBox(height: 12),
          appBox(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Next Prayer', style: TextStyle(color: gold, fontWeight: FontWeight.bold)), const SizedBox(height: 8), if (next == null) const Text('Prayer schedule will refresh for the next day.') else Row(children: [Text(next.arabic, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)), const SizedBox(width: 10), Text(next.name, style: const TextStyle(fontSize: 18)), const Spacer(), Text(DateFormat('h:mm a').format(next.time), style: const TextStyle(color: gold, fontSize: 19, fontWeight: FontWeight.bold))])])),
          const SizedBox(height: 12),
          appBox(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ayah of the Day', style: TextStyle(color: gold, fontWeight: FontWeight.bold)), SizedBox(height: 10), Text('إِنَّ مَعَ الْعُسْرِ يُسْرًا', textAlign: TextAlign.right, style: TextStyle(fontSize: 29, height: 1.8, fontWeight: FontWeight.bold)), SizedBox(height: 5), Text('Indeed, with hardship comes ease.  •  Ash-Sharh 94:6')])),
          const SizedBox(height: 14),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.45, children: [_tile(context, Icons.menu_book, 'Quran', const QuranPage()), _tile(context, Icons.explore, 'Qibla', const QiblaPage()), _tile(context, Icons.favorite_outline, 'Duas', const DuasPage()), _tile(context, Icons.nightlight_outlined, 'Ramadan', const RamadanPage())]),
        ],
      ),
    );
  }
  Widget _tile(BuildContext context, IconData icon, String title, Widget page) => InkWell(borderRadius: BorderRadius.circular(22), onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page)), child: appBox(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: gold, size: 30), const Spacer(), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))])));
}

class QuranPage extends StatefulWidget {
  const QuranPage({super.key});
  @override State<QuranPage> createState() => _QuranPageState();
}
class _QuranPageState extends State<QuranPage> {
  late Future<List<Surah>> future;
  String query = '';
  @override void initState(){super.initState();future=QuranService().load();}
  @override Widget build(BuildContext context){
    return FutureBuilder<List<Surah>>(future:future,builder:(context,snapshot){
      if(snapshot.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(snapshot.hasError||snapshot.data==null)return Center(child:FilledButton(onPressed:()=>setState(()=>future=QuranService().load()),child:const Text('Retry Quran')));
      final q=query.toLowerCase();
      final list=snapshot.data!.where((s)=>q.isEmpty||s.englishName.toLowerCase().contains(q)||s.name.contains(query)).toList();
      return ListView(padding:const EdgeInsets.all(18),children:[
        const Text('Quran Kareem',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900)),
        const Text('القرآن الكريم',style:TextStyle(color:gold,fontSize:20)),
        const SizedBox(height:12),
        TextField(onChanged:(v)=>setState(()=>query=v),decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search Surah')),
        const SizedBox(height:12),
        ...list.map((s)=>Card(child:ListTile(leading:CircleAvatar(backgroundColor:forest,child:Text('${s.number}')),title:Text(s.englishName),subtitle:Text('${s.verses.length} Ayahs'),trailing:Text(s.name),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>ReaderPage(surah:s))))),
      ]);
    });
  }
}
class ReaderPage extends StatelessWidget {
  final Surah surah;
  const ReaderPage({super.key,required this.surah});
  @override Widget build(BuildContext context){
    final text=surah.verses.map((a)=>'${a.text} ۝${a.numberInSurah}').join('  ');
    return Scaffold(backgroundColor:paper,appBar:AppBar(backgroundColor:paper,foregroundColor:Colors.black87,title:Text(surah.englishName)),body:ListView(padding:const EdgeInsets.all(18),children:[Text(surah.name,textAlign:TextAlign.center,style:const TextStyle(color:Colors.black87,fontSize:34,fontWeight:FontWeight.bold)),Text(surah.translation,textAlign:TextAlign.center,style:const TextStyle(color:Colors.black54)),const SizedBox(height:18),Text(text,textAlign:TextAlign.right,style:const TextStyle(color:Colors.black87,fontSize:31,height:2.1))]));
  }
}
class PrayerPage extends StatelessWidget {
  final AlarmService alarms;
  const PrayerPage({super.key,required this.alarms});
  @override Widget build(BuildContext context){
    return Scaffold(appBar:AppBar(title:const Text('Prayer Times')),body:Column(children:[Expanded(child:DashboardPage(alarms:alarms)),Padding(padding:const EdgeInsets.all(12),child:OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>AlarmSettingsPage(alarms:alarms))),icon:const Icon(Icons.notifications_active),label:const Text('Adhan & Alarm Settings')))]));
  }
}
class QiblaPage extends StatefulWidget { const QiblaPage({super.key}); @override State<QiblaPage> createState() => _QiblaPageState(); }
class _QiblaPageState extends State<QiblaPage> {
  StreamSubscription<CompassEvent>? sub; double? heading; double? qibla; String place = 'Finding location…'; bool calibrate = false;
  @override void initState() { super.initState(); _start(); }
  double bearing(double lat, double lon) { const kLat = 21.422487; const kLon = 39.826206; final p1 = lat * math.pi / 180; final p2 = kLat * math.pi / 180; final dl = (kLon - lon) * math.pi / 180; final b = math.atan2(math.sin(dl) * math.cos(p2), math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl)); return (b * 180 / math.pi + 360) % 360; }
  Future<void> _start() async { try { final service = PrayerService(); final pos = await service.location(); if (pos == null) throw Exception('Location permission is required.'); qibla = bearing(pos.latitude, pos.longitude); place = await service.reversePlace(pos.latitude, pos.longitude); sub = FlutterCompass.events?.listen((e) { final h = e.heading; if (mounted && h != null) setState(() => heading = h); }); if (mounted) setState(() {}); } catch (_) { if (mounted) setState(() => place = 'Enable GPS and compass'); } }
  @override void dispose() { sub?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) { final relative = qibla == null || heading == null ? 0.0 : ((qibla! - heading! + 540) % 360 - 180); final angle = relative * math.pi / 180; return Scaffold(appBar: AppBar(title: const Text('Qibla Finder')), body: ListView(padding: const EdgeInsets.all(20), children: [appBox(Column(children: [const Text('القبلة', style: TextStyle(color: gold, fontSize: 28, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(place, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 6), Text(qibla == null ? 'Qibla direction unavailable' : 'Qibla ${qibla!.toStringAsFixed(1)}° from North', style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 18), Stack(alignment: Alignment.center, children: [Container(width: 285, height: 285, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: gold, width: 2), color: Colors.white.withValues(alpha: .035))), Transform.rotate(angle: angle, child: Column(children: [const Icon(Icons.navigation, size: 175, color: gold), Transform.translate(offset: const Offset(0, -32), child: const Icon(Icons.mosque, size: 45, color: Colors.white))]))]), const SizedBox(height: 12), Text(heading == null ? 'Waiting for compass sensor…' : 'Phone heading ${heading!.toStringAsFixed(0)}°', style: const TextStyle(color: Colors.white70)), const SizedBox(height: 8), const Text('Keep the phone flat. Move it in a figure‑8 if the compass needs calibration.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)), const SizedBox(height: 10), FilledButton.icon(onPressed: () => setState(() => calibrate = !calibrate), icon: const Icon(Icons.explore), label: Text(calibrate ? 'Calibration mode on' : 'Calibrate compass'))]))])); }
}

class DhikrPage extends StatefulWidget { const DhikrPage({super.key}); @override State<DhikrPage> createState() => _DhikrPageState(); }
class _DhikrPageState extends State<DhikrPage> { int count = 0; int target = 33; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Dhikr & Tasbeeh')), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('سُبْحَانَ اللَّهِ', style: TextStyle(fontSize: 30)), const SizedBox(height: 8), Text('$count / $target', style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: gold)), const SizedBox(height: 18), GestureDetector(onTap: () => setState(() { count++; if (count > 9999) count = 0; }), child: Container(width: 190, height: 190, decoration: BoxDecoration(shape: BoxShape.circle, color: forest, border: Border.all(color: gold, width: 4)), child: const Center(child: Text('TAP', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900))))), const SizedBox(height: 10), Wrap(spacing: 8, children: [for (final n in [33, 99, 100]) ChoiceChip(label: Text('$n'), selected: target == n, onSelected: (_) => setState(() { target = n; count = 0; }))]), TextButton(onPressed: () => setState(() => count = 0), child: const Text('Reset'))]))); }
}

class DuasPage extends StatelessWidget {
  const DuasPage({super.key});
  static const duas = <DuaItem>[
    DuaItem(title: 'Morning', arabic: 'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا', meaning: 'O Allah, by You we enter the morning and by You we enter the evening.'),
    DuaItem(title: 'Evening', arabic: 'اللَّهُمَّ بِكَ أَمْسَيْنَا وَبِكَ أَصْبَحْنَا', meaning: 'O Allah, by You we enter the evening and by You we enter the morning.'),
    DuaItem(title: 'Forgiveness', arabic: 'رَبِّ اغْفِرْ لِي وَتُبْ عَلَيَّ إِنَّكَ أَنْتَ التَّوَّابُ الرَّحِيمُ', meaning: 'My Lord, forgive me and accept my repentance.'),
    DuaItem(title: 'Protection', arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ', meaning: 'I seek refuge in the perfect words of Allah from the evil of what He created.'),
    DuaItem(title: 'Travel', arabic: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ', meaning: 'Glory to Him who made this serviceable for us.'),
    DuaItem(title: 'Before sleep', arabic: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا', meaning: 'In Your name, O Allah, I die and I live.'),
    DuaItem(title: 'After waking', arabic: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا', meaning: 'Praise is for Allah who gave us life after causing us to die.'),
    DuaItem(title: 'Entering the mosque', arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ', meaning: 'O Allah, open for me the doors of Your mercy.'),
    DuaItem(title: 'Leaving the mosque', arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ', meaning: 'O Allah, I ask You from Your bounty.'),
    DuaItem(title: 'Anxiety', arabic: 'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ ۖ عَلَيْهِ تَوَكَّلْتُ', meaning: 'Allah is sufficient for me; there is no god but Him. Upon Him I rely.'),
    DuaItem(title: 'Rabbana', arabic: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً', meaning: 'Our Lord, give us good in this world and good in the Hereafter.'),
    DuaItem(title: 'Knowledge', arabic: 'رَبِّ زِدْنِي عِلْمًا', meaning: 'My Lord, increase me in knowledge.'),
  ];
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Duas & Adhkar')), body: ListView(padding: const EdgeInsets.all(18), children: duas.map((d) => Padding(padding: const EdgeInsets.only(bottom: 12), child: appBox(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.title, style: const TextStyle(color: gold, fontWeight: FontWeight.bold)), const SizedBox(height: 10), Text(d.arabic, textAlign: TextAlign.right, style: const TextStyle(fontSize: 24, height: 1.9)), const SizedBox(height: 8), Text(d.meaning, style: const TextStyle(color: Colors.white70))])))).toList()));
}

class RamadanPage extends StatelessWidget { const RamadanPage({super.key}); @override Widget build(BuildContext context) => FutureBuilder<HijriDate?>(future: HijriService.today(), builder: (context, s) { final isRamadan = s.data?.month == 9; return Scaffold(appBar: AppBar(title: const Text('Ramadan')), body: ListView(padding: const EdgeInsets.all(18), children: [const BrandMark(size: 88), const SizedBox(height: 18), if (!isRamadan) appBox(const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Coming soon', style: TextStyle(color: gold, fontSize: 28, fontWeight: FontWeight.w900)), SizedBox(height: 8), Text('Ramadan features will unlock automatically when the Hijri calendar reaches Ramadan (9).')])) else ...const [Text('Ramadan Mubarak', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)), SizedBox(height: 12), _RamadanFeature('Suhoor & Iftar times'), _RamadanFeature('Daily fasting countdown'), _RamadanFeature('Ramadan duas & adhkar'), _RamadanFeature('Quran completion plan'), _RamadanFeature('Sadaqah & good-deed tracker')]])); }); }
class _RamadanFeature extends StatelessWidget { final String text; const _RamadanFeature(this.text); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: appBox(Row(children: [const Icon(Icons.check_circle, color: gold), const SizedBox(width: 10), Text(text)]))); }

class AlarmSettingsPage extends StatefulWidget { final AlarmService alarms; const AlarmSettingsPage({super.key, required this.alarms}); @override State<AlarmSettingsPage> createState() => _AlarmSettingsPageState(); }
class _AlarmSettingsPageState extends State<AlarmSettingsPage> {
  String sound = 'adhan_kuwait'; bool enabled = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { final s = await AlarmService.sound(); final e = await Preferences.alarmsEnabled(); if (mounted) setState(() { sound = s; enabled = e; }); }
  Future<void> _saveSound(String v) async { await AlarmService.setSound(v); setState(() => sound = v); await widget.alarms.refreshStoredSchedule(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Adhan & Alarms')), body: ListView(padding: const EdgeInsets.all(18), children: [appBox(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Adhan sound', style: TextStyle(color: gold, fontWeight: FontWeight.bold)), RadioListTile<String>(value: 'adhan_kuwait', groupValue: sound, onChanged: (v) { if (v != null) _saveSound(v); }, title: const Text('Kuwait Adhan')), RadioListTile<String>(value: 'adhan_dubai', groupValue: sound, onChanged: (v) { if (v != null) _saveSound(v); }, title: const Text('Dubai Adhan')), RadioListTile<String>(value: 'adhan_fajr', groupValue: sound, onChanged: (v) { if (v != null) _saveSound(v); }, title: const Text('Fajr Adhan'))])), const SizedBox(height: 12), appBox(SwitchListTile(value: enabled, onChanged: (v) async { setState(() => enabled = v); await Preferences.setAlarmsEnabled(v); if (v) { await widget.alarms.refreshStoredSchedule(); } else { await widget.alarms.plugin.cancelAll(); } }, title: const Text('Prayer notifications'), subtitle: const Text('Schedule Fajr, Dhuhr, Asr, Maghrib and Isha'))), const SizedBox(height: 12), const Text('Allow notifications and exact alarms in Android settings for reliable Adhan alerts.', style: TextStyle(color: Colors.white54))]));
}

class MorePage extends StatelessWidget { final AlarmService alarms; const MorePage({super.key,required this.alarms}); @override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(18),children:[Row(children:[const BrandMark(size:56),const SizedBox(width:12),const Text('Settings',style:TextStyle(fontSize:30,fontWeight:FontWeight.w900))]),const SizedBox(height:18),appBox(const Text('Prayer times use your GPS location.')),ListTile(leading:const Icon(Icons.notifications_active,color:gold),title:const Text('Adhan & Alarm Settings'),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>AlarmSettingsPage(alarms:alarms)))),ListTile(leading:const Icon(Icons.explore,color:gold),title:const Text('Qibla Finder'),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>const QiblaPage()))),ListTile(leading:const Icon(Icons.favorite,color:gold),title:const Text('Duas & Adhkar'),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>const DuasPage()))),ListTile(leading:const Icon(Icons.nightlight,color:gold),title:const Text('Ramadan'),onTap:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>const RamadanPage()))) ]); }
class HijriDate { final int day, month, year; final String monthName; const HijriDate(this.day, this.month, this.year, this.monthName); String get display => '$day $monthName $year AH'; }
class HijriService {
  static Future<HijriDate?> today() async {
    final now = DateTime.now();
    try {
      final r = await http.get(Uri.parse('https://api.aladhan.com/v1/gToH?date=${DateFormat('dd-MM-yyyy').format(now)}')).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) { final d = jsonDecode(r.body)['data']['hijri']; return HijriDate(int.parse('${d['day']}'), int.parse('${d['month']['number']}'), int.parse('${d['year']}'), '${d['month']['en']}'); }
    } catch (_) {}
    return null;
  }
}
