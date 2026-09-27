import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const defaultAccessibility = AccessibilityPreferences();
const profileNameKey = 'deep_care_profile_name';
const profilePhoneKey = 'deep_care_profile_phone';
const profilePhoneVerifiedKey = 'deep_care_profile_phone_verified';
const bookingBadgeKey = 'deep_care_booking_badge';
const textScaleKey = 'deep_care_text_scale';
const reduceMotionKey = 'deep_care_reduce_motion';
const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class AccessibilityPreferences {
  const AccessibilityPreferences({
    this.textScale = 1,
    this.reduceMotion = false,
  });

  final double textScale;
  final bool reduceMotion;
}

final ValueNotifier<AccessibilityPreferences> accessibilityPreferences =
    ValueNotifier(defaultAccessibility);

void setAccessibilityPreferences(AccessibilityPreferences preferences) {
  accessibilityPreferences.value = preferences;
  unawaited(storeAccessibilityPreferences(preferences));
}

Future<void> storeAccessibilityPreferences(
  AccessibilityPreferences preferences,
) async {
  try {
    final storage = await SharedPreferences.getInstance();
    await storage.setDouble(textScaleKey, preferences.textScale);
    await storage.setBool(reduceMotionKey, preferences.reduceMotion);
  } catch (_) {
    // Keep the current app session usable when local settings cannot be saved.
  }
}

Future<void> initializeAppSettings() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    accessibilityPreferences.value = AccessibilityPreferences(
      textScale: preferences.getDouble(textScaleKey) ?? 1,
      reduceMotion: preferences.getBool(reduceMotionKey) ?? false,
    );
  } catch (_) {
    // App startup remains available if local preferences cannot be read.
  }
}
