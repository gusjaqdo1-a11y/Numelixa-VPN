# Numelixa Quran

A premium Flutter Muslim companion app for Android.

## Included

- Complete 114-surah Quran data bundled into release builds from the verified `quran-uthmani` edition endpoint.
- Beautiful Arabic Quran reader with surah search and bookmarks.
- Device-location prayer time calculation with Fajr, Sunrise, Dhuhr, Asr, Maghrib and Isha.
- Local prayer-time notifications and exact-alarm support.
- Tasbeeh / dhikr counter with common adhkar presets.
- Dua/adhkar, Qibla and Ramadan feature areas ready for expansion.
- Dark emerald + gold premium visual system and custom Islamic logo.
- Offline-first Quran asset in release builds; network fallback is available for development.

## Build

The repository intentionally keeps the generated Flutter Android platform out of source control. GitHub Actions creates it from Flutter 3.47.7, downloads and validates the complete Quran asset, configures Android permissions, runs `flutter analyze`, and builds release APKs.

Push to `main` to produce downloadable APK artifacts in GitHub Actions. Create a Git tag such as `v1.0.0` to also publish APKs as a GitHub Release.

## Quran source

Release builds fetch the complete `quran-uthmani` edition from AlQuran Cloud's documented Quran API. The API documents a complete-Quran endpoint and the standard `quran-uthmani` edition.

## Important product note

Prayer times depend on the selected calculation method, madhab, date, coordinates and local time zone. The first version uses Muslim World League parameters with Shafi Asr as a sensible global default; a production release should expose calculation-method and madhab settings so users can match their local mosque/calendar.
