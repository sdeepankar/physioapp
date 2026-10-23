import 'package:flutter/material.dart';

import '../core/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DeepCareProviderApp());
}

class DeepCareProviderApp extends StatelessWidget {
  const DeepCareProviderApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Deep Care Provider',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: appCanvas,
      colorScheme: ColorScheme.fromSeed(seedColor: appTeal, surface: appCanvas),
      fontFamily: 'Roboto',
    ),
    home: const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.medical_services_outlined, size: 56, color: appTeal),
                SizedBox(height: 16),
                Text(
                  'Deep Care Provider',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: appInk,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Provider sign-in, availability, and assigned bookings will be built in this app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: appMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
