import 'package:flutter/material.dart';
import 'services.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final alarms = AlarmService();
  try {
    await alarms.init();
  } catch (_) {}
  runApp(HudaWayApp(alarms: alarms));
}
