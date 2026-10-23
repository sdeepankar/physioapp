import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'core/app_settings.dart';
import 'screens/onboarding_screen.dart';

class PhysioApp extends StatelessWidget {
  const PhysioApp({super.key});
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<AccessibilityPreferences>(
        valueListenable: accessibilityPreferences,
        builder: (context, preferences, _) => MaterialApp(
          title: 'Deep Care',
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final systemTextScale = media.textScaler.scale(1);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(
                  systemTextScale * preferences.textScale,
                ),
                disableAnimations:
                    media.disableAnimations || preferences.reduceMotion,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: appCanvas,
            colorScheme: ColorScheme.fromSeed(
              seedColor: appTeal,
              surface: appCanvas,
            ),
            pageTransitionsTheme: preferences.reduceMotion
                ? PageTransitionsTheme(
                    builders: {
                      for (final platform in TargetPlatform.values)
                        platform: const NoMotionPageTransitionsBuilder(),
                    },
                  )
                : const PageTransitionsTheme(),
            appBarTheme: const AppBarTheme(
              titleTextStyle: TextStyle(
                color: appInk,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.35,
              ),
            ),
            fontFamily: 'Roboto',
          ),
          home: const BrandedSplashScreen(),
        ),
      );
}

class NoMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoMotionPageTransitionsBuilder();
  @override
  Duration get transitionDuration => Duration.zero;
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
