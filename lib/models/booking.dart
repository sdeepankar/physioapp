import 'package:flutter/material.dart';
import 'care_service.dart';

class Booking {
  const Booking({
    required this.id,
    required this.service,
    required this.date,
    required this.time,
    required this.addressType,
    required this.address,
    required this.area,
    required this.city,
    required this.state,
    required this.pinCode,
    required this.landmark,
  });

  final String id;
  final CareService service;
  final DateTime date;
  final String time;
  final String addressType;
  final String address;
  final String area, city, state, pinCode;
  final String landmark;
  DateTime get scheduledAt {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s+(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(time.trim());
    if (match == null) return DateUtils.dateOnly(date);

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String get localitySummary =>
      [area, city, state, pinCode].where((part) => part.isNotEmpty).join(', ');
}
