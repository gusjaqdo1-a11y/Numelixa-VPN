import 'dart:math' as math;
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
  runApp(NumelixaQuranApp(alarms: alarms));
}

class NumelixaQuranApp extends StatelessWidget {
  final AlarmService alarms;
  const NumelixaQuranApp({super.key, required this.alarms});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Numelixa Quran',
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: deep, colorScheme: ColorScheme.fromSeed(seedColor: emerald, brightness: Brightness.dark), fontFamily: 'sans-serif'),
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
  final pages = const [DashboardPage(), QuranPage(), PrayerPage(), DhikrPage(), MorePage()];
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: pages[index]),
    bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Quran'),
      NavigationDestination(icon: Icon(Icons.mosque_outlined), selectedIcon: Icon(Icons.mosque), label: 'Prayer'),
      NavigationDestination(icon: Icon(Icons.fingerprint), selectedIcon: Icon(Icons.fingerprint), label: 'Dhikr'),
      NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'More'),
    ]),
  );
}

Widget glass(BuildContext context, {required Widget child, EdgeInsets padding = const EdgeInsets.all(18)}) => Container(
  padding: padding,
  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .055), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: .08))),
  child: child,
);

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 30), children: [
    Row(children: [ClipRRect(borderRadius: BorderRadius.circular(16), child: SvgPicture.asset('assets/brand/logo.svg', width: 58, height: 58)), const SizedBox(width: 14), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Assalamu Alaikum', style: TextStyle(fontSize: 14, color: Colors.white60)), Text('Numelixa Quran', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800))]))]),
    const SizedBox(height: 20),
    glass(context, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('آية اليوم', style: TextStyle(color: gold, fontWeight: FontWeight.bold)), SizedBox(height: 12), Text('إِنَّ مَعَ الْعُسْرِ يُسْرًا', textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: TextStyle(fontSize: 28, height: 1.8, fontWeight: FontWeight.w700)), SizedBox(height: 8), Text('Indeed, with hardship comes ease.', style: TextStyle(color: Colors.white70)), Text('Al-Inshirah · 94:6', style: TextStyle(color: Colors.white38, fontSize: 12))])),
    const SizedBox(height: 14),
    Row(children: [Expanded(child: _quick(context, Icons.menu_book, 'Continue Quran', 'Read where you left off')), const SizedBox(width: 12), Expanded(child: _quick(context, Icons.fingerprint, 'Tasbeeh', 'Keep your dhikr count'))]),
    const SizedBox(height: 14),
    glass(context, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Today', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Row(children: [const Icon(Icons.access_time, color: gold), const SizedBox(width: 10), Expanded(child: Text(DateFormat('EEEE, d MMMM y').format(DateTime.now()))), const Icon(Icons.chevron_right)]), const SizedBox(height: 12), const Text('Prayer times are calculated on your device after location permission is granted.', style: TextStyle(color: Colors.white54, height: 1.4))])),
    const SizedBox(height: 14),
    glass(context, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Explore', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), SizedBox(height: 14), _ExploreRow(icon: Icons.favorite_outline, title: 'Duas & Adhkar', subtitle: 'Morning, evening and daily supplications'), _ExploreRow(icon: Icons.explore_outlined, title: 'Qibla', subtitle: 'Find the direction of the Kaaba'), _ExploreRow(icon: Icons.nightlight_outlined, title: 'Ramadan tools', subtitle: 'Suhoor, iftar and fasting helpers')]))
  ]);
  Widget _quick(BuildContext c, IconData i, String t, String s) => glass(c, padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: gold), const SizedBox(height: 10), Text(t, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 3), Text(s, style: const TextStyle(fontSize: 11, color: Colors.white54))]));
}
class _ExploreRow extends StatelessWidget { final IconData icon; final String title, subtitle; const _ExploreRow({required this.icon, required this.title, required this.subtitle}); @override Widget build(BuildContext c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [Icon(icon, color: gold), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12))])), const Icon(Icons.chevron_right, color: Colors.white38)])); }

class QuranPage extends StatefulWidget { const QuranPage({super.key}); @override State<QuranPage> createState() => _QuranPageState(); }
class _QuranPageState extends State<QuranPage> {
  final service = QuranService();
  late Future<List<Surah>> future;
  String query = '';
  @override void initState(){super.initState(); future=service.load();}
  @override Widget build(BuildContext context) => FutureBuilder<List<Surah>>(future: future, builder: (c,s) {
    if (!s.hasData) return const Center(child: CircularProgressIndicator());
    final list=s.data!.where((x)=>x.englishName.toLowerCase().contains(query.toLowerCase()) || x.name.contains(query)).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(18,18,18,30), children: [const Text('Quran',style:TextStyle(fontSize:30,fontWeight:FontWeight.w800)), const SizedBox(height:4), const Text('القرآن الكريم',style:TextStyle(color:gold,fontSize:18)), const SizedBox(height:18), TextField(onChanged:(v)=>setState(()=>query=v), decoration: InputDecoration(prefixIcon:const Icon(Icons.search), hintText:'Search surah', filled:true, fillColor:Colors.white.withValues(alpha:.05), border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none))), const SizedBox(height:14), ...list.map((surah)=>Card(color:Colors.white.withValues(alpha:.04),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),child:ListTile(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>ReaderPage(surah:surah))),leading:CircleAvatar(backgroundColor:emerald,child:Text('${surah.number}')),title:Text(surah.englishName,style:const TextStyle(fontWeight:FontWeight.w700)),subtitle:Text('${surah.revelationType} · ${surah.ayahs} Ayahs',style:const TextStyle(color:Colors.white54)),trailing:Text(surah.name,style:const TextStyle(fontSize:18)))) )]);
  });
}
class ReaderPage extends StatelessWidget { final Surah surah; const ReaderPage({super.key,required this.surah}); @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(surah.englishName),backgroundColor:deep),body:ListView(padding:const EdgeInsets.all(18),children:[glass(c,child:Column(children:[Text(surah.name,textDirection:TextDirection.rtl,style:const TextStyle(fontSize:32,fontWeight:FontWeight.bold)),const SizedBox(height:5),Text(surah.translation,style:const TextStyle(color:Colors.white54))])),const SizedBox(height:14),...surah.verses.map((a)=>Padding(padding:const EdgeInsets.only(bottom:16),child:glass(c,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Row(children:[CircleAvatar(radius:14,backgroundColor:emerald,child:Text('${a.numberInSurah}',style:const TextStyle(fontSize:11))),const Spacer(),IconButton(onPressed:()=>Preferences.saveLastAyah(surah.number,a.numberInSurah),icon:const Icon(Icons.bookmark_border,color:gold))]),const SizedBox(height:10),Text(a.text,textDirection:TextDirection.rtl,textAlign:TextAlign.right,style:const TextStyle(fontSize:27,height:1.9,fontWeight:FontWeight.w600))])))]));}

class PrayerPage extends StatefulWidget { const PrayerPage({super.key}); @override State<PrayerPage> createState()=>_PrayerPageState(); }
class _PrayerPageState extends State<PrayerPage>{ final service=PrayerService(); final alarms=AlarmService(); List<PrayerEntry>? prayers; String place='Location not set'; bool loading=false;
  Future<void> load() async { setState(()=>loading=true); final p=await service.location(); if(p!=null){ prayers=service.calculate(p.latitude,p.longitude,DateTime.now()); await alarms.init(); await alarms.scheduleAll(prayers!); place='${p.latitude.toStringAsFixed(2)}, ${p.longitude.toStringAsFixed(2)}'; } setState(()=>loading=false); }
  @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[Row(children:[const Expanded(child:Text('Prayer Times',style:TextStyle(fontSize:30,fontWeight:FontWeight.w800))),IconButton(onPressed:loading?null:load,icon:const Icon(Icons.my_location,color:gold))]),Text(place,style:const TextStyle(color:Colors.white54)),const SizedBox(height:18),if(prayers==null)glass(c,child:Column(children:[const Icon(Icons.location_on_outlined,size:50,color:gold),const SizedBox(height:10),const Text('Enable location for accurate local prayer times',textAlign:TextAlign.center,style:TextStyle(fontSize:16)),const SizedBox(height:14),FilledButton.icon(onPressed:loading?null:load,icon:const Icon(Icons.gps_fixed),label:Text(loading?'Loading...':'Use my location'))])) else ...prayers!.map((p)=>Padding(padding:const EdgeInsets.only(bottom:10),child:glass(c,padding:const EdgeInsets.symmetric(horizontal:16,vertical:14),child:Row(children:[CircleAvatar(backgroundColor:emerald,child:Icon(_icon(p.name),size:19)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(p.name,style:const TextStyle(fontWeight:FontWeight.bold)),Text(p.arabic,textDirection:TextDirection.rtl,style:const TextStyle(color:gold,fontSize:12))])),Text(DateFormat('h:mm a').format(p.time),style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800))])))),const SizedBox(height:8),glass(c,child:const Text('Alarm: prayer notifications are scheduled locally on this device. Exact alarm permission may be required by Android.',style:TextStyle(color:Colors.white54,height:1.5))) ]);
  IconData _icon(String n)=>switch(n){'Fajr'=>Icons.wb_twilight,'Sunrise'=>Icons.wb_sunny_outlined,'Dhuhr'=>Icons.sunny,'Asr'=>Icons.wb_sunny,'Maghrib'=>Icons.nights_stay_outlined,_=>Icons.dark_mode_outlined};
}

class DhikrPage extends StatefulWidget{const DhikrPage({super.key});@override State<DhikrPage> createState()=>_DhikrPageState();}
class _DhikrPageState extends State<DhikrPage>{int count=0,target=33;final duas=const[ DuaItem(title:'SubhanAllah',arabic:'سُبْحَانَ اللَّهِ',meaning:'Glory be to Allah',target:33),DuaItem(title:'Alhamdulillah',arabic:'الْحَمْدُ لِلَّهِ',meaning:'All praise is for Allah',target:33),DuaItem(title:'Allahu Akbar',arabic:'اللَّهُ أَكْبَرُ',meaning:'Allah is the Greatest',target:34)];@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[const Text('Dhikr & Tasbeeh',style:TextStyle(fontSize:30,fontWeight:FontWeight.w800)),const SizedBox(height:6),const Text('Remember Allah with a simple, focused counter.',style:TextStyle(color:Colors.white54)),const SizedBox(height:20),glass(c,child:Column(children:[Text('$count',style:const TextStyle(fontSize:72,fontWeight:FontWeight.w800,color:gold)),Text('of $target',style:const TextStyle(color:Colors.white54)),const SizedBox(height:18),GestureDetector(onTap:()=>setState(()=>count=count>=target?0:count+1),child:Container(width:190,height:190,decoration:BoxDecoration(shape:BoxShape.circle,color:emerald,border:Border.all(color:gold,width:3),boxShadow:[BoxShadow(color:gold.withValues(alpha:.15),blurRadius:30)]),child:const Center(child:Text('TAP',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800))))),const SizedBox(height:14),TextButton.icon(onPressed:()=>setState(()=>count=0),icon:const Icon(Icons.refresh),label:const Text('Reset'))])),const SizedBox(height:18),...duas.map((d)=>ListTile(onTap:()=>setState(()=>target=d.target),leading:const Icon(Icons.favorite_border,color:gold),title:Text(d.title),subtitle:Text('${d.meaning} · ${d.target}')))]);}

class MorePage extends StatelessWidget{const MorePage({super.key});@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[const Text('More',style:TextStyle(fontSize:30,fontWeight:FontWeight.w800)),const SizedBox(height:18),...[(Icons.explore,'Qibla','Calculate Qibla direction from your location'),(Icons.volunteer_activism,'Duas','Daily duas with Arabic and explanations'),(Icons.nightlight,'Ramadan','Fasting, suhoor and iftar helpers'),(Icons.settings_outlined,'Settings','Language, calculation method, notifications and appearance'),(Icons.info_outline,'About','About Numelixa Quran and data sources')].map((x)=>Card(color:Colors.white.withValues(alpha:.04),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),child:ListTile(leading:Icon(x.$1,color:gold),title:Text(x.$2),subtitle:Text(x.$3,style:const TextStyle(color:Colors.white54)),trailing:const Icon(Icons.chevron_right))))]);}

