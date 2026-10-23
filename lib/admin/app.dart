import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'screens/admin_screen.dart';

class DeepCareAdminApp extends StatelessWidget {
  const DeepCareAdminApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Deep Care Admin',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: appCanvas,
      colorScheme: ColorScheme.fromSeed(seedColor: appTeal, surface: appCanvas),
      appBarTheme: const AppBarTheme(
        backgroundColor: appCanvas,
        foregroundColor: appInk,
        titleTextStyle: TextStyle(
          color: appInk,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      fontFamily: 'Roboto',
    ),
    home: const AdminAuthGate(),
  );
}
