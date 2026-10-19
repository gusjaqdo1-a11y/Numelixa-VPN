class Surah {
  final int number;
  final String name;
  final String englishName;
  final String translation;
  final int ayahs;
  final String revelationType;
  final List<Ayah> verses;
  const Surah({required this.number, required this.name, required this.englishName, required this.translation, required this.ayahs, required this.revelationType, required this.verses});
  factory Surah.fromJson(Map<String, dynamic> json) => Surah(number: json['number'] as int, name: json['name'] as String, englishName: json['englishName'] as String, translation: json['englishNameTranslation'] as String? ?? '', ayahs: json['numberOfAyahs'] as int, revelationType: json['revelationType'] as String? ?? '', verses: ((json['ayahs'] as List?) ?? const []).map((e) => Ayah.fromJson(e as Map<String, dynamic>)).toList());
}
class Ayah {
  final int number;
  final int numberInSurah;
  final String text;
  final int page;
  final int juz;
  const Ayah({required this.number, required this.numberInSurah, required this.text, required this.page, required this.juz});
  factory Ayah.fromJson(Map<String, dynamic> json) => Ayah(number: json['number'] as int, numberInSurah: json['numberInSurah'] as int, text: json['text'] as String, page: json['page'] as int? ?? 0, juz: json['juz'] as int? ?? 0);
}
class PrayerEntry {
  final String name;
  final String arabic;
  final DateTime time;
  final bool enabled;
  const PrayerEntry({required this.name, required this.arabic, required this.time, this.enabled = true});
}
class DuaItem {
  final String title;
  final String arabic;
  final String meaning;
  final int target;
  const DuaItem({required this.title, required this.arabic, required this.meaning, this.target = 1});
}
