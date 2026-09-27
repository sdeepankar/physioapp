import 'package:flutter/material.dart';
export 'app/app.dart';
import 'app/app.dart';
import 'core/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAppSettings();
  runApp(const PhysioApp());
}
