class Surah {
  final int number;
  final String name;
  final String englishName;
  final String translation;
  final int ayahs;
  final String revelationType;
  final List<Ayah> verses;

  const Surah({required this.number, required this.name, required this.englishName, required this.translation, required this.ayahs, required this.revelationType, required this.verses});

  factory Surah.fromJson(Map<String, dynamic> json) {
    final rawAyahs = json['ayahs'];
    final list = rawAyahs is List ? rawAyahs : const [];
    return Surah(
      number: _int(json['number']),
      name: _string(json['name']),
      englishName: _string(json['englishName']),
      translation: _string(json['englishNameTranslation']),
      ayahs: _int(json['numberOfAyahs']),
      revelationType: _string(json['revelationType']),
      verses: list.whereType<Map>().map((e) => Ayah.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}

class Ayah {
  final int number;
  final int numberInSurah;
  final String text;
  final int page;
  final int juz;

  const Ayah({required this.number, required this.numberInSurah, required this.text, required this.page, required this.juz});

  factory Ayah.fromJson(Map<String, dynamic> json) => Ayah(
    number: _int(json['number']),
    numberInSurah: _int(json['numberInSurah']),
    text: _string(json['text']),
    page: _int(json['page']),
    juz: _int(json['juz']),
  );
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

int _int(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
String _string(dynamic value) => value?.toString() ?? '';
