import 'package:flutter/material.dart';

import 'core/app_settings.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAppSettings();
  runApp(const PhysioApp());
}
