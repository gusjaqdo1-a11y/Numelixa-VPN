import 'package:flutter_test/flutter_test.dart';
import 'package:hudaway/models.dart';

void main() {
  test('Surah and Ayah models parse valid Quran data', () {
    final surah = Surah.fromJson({
      'number': 1,
      'name': 'الفاتحة',
      'englishName': 'Al-Fatihah',
      'englishNameTranslation': 'The Opening',
      'numberOfAyahs': 1,
      'revelationType': 'Meccan',
      'ayahs': [
        {'number': 1, 'numberInSurah': 1, 'text': 'بِسْمِ اللَّهِ', 'page': 1, 'juz': 1}
      ]
    });
    expect(surah.number, 1);
    expect(surah.englishName, 'Al-Fatihah');
    expect(surah.verses.single.numberInSurah, 1);
  });
}
