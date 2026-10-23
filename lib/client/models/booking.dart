import 'dart:math';

import 'package:flutter/material.dart';

import 'care_service.dart';

class Booking {
  static final Random _idRandom = Random.secure();

  /// Internal retry key; the server generates the visible sequential ID.
  static String createClientRequestId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final suffix = _idRandom.nextInt(100000).toString().padLeft(5, '0');
    return 'REQ$timestamp$suffix';
  }

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
    this.status = 'pending_assignment',
    this.paymentStatus = 'pending',
    this.clientRequestId = '',
  });

  factory Booking.fromOrderRow(Map<String, dynamic> row) {
    final scheduledAt = DateTime.parse(row['scheduledAt'] as String).toLocal();
    final serviceName = row['serviceName'] as String? ?? 'Care service';
    final price = (row['servicePrice'] as num?)?.toDouble() ?? 0;
    final rupee = String.fromCharCode(0x20B9);
    final existing = careServices.cast<CareService?>().firstWhere(
      (service) => service!.name.toLowerCase() == serviceName.toLowerCase(),
      orElse: () => null,
    );
    final service = CareService(
      serviceName,
      existing?.subtitle ?? '',
      existing?.icon ?? Icons.medical_services_outlined,
      existing?.color ?? const Color(0xFF43A8D4),
      price == price.roundToDouble()
          ? '$rupee${price.toStringAsFixed(0)}'
          : '$rupee${price.toStringAsFixed(2)}',
      id: row['serviceId'] as String? ?? '',
      priceAmount: price,
    );
    final hour = scheduledAt.hour % 12 == 0 ? 12 : scheduledAt.hour % 12;
    final minute = scheduledAt.minute.toString().padLeft(2, '0');

    return Booking(
      id: row[r'$id'] as String? ?? '',
      service: service,
      date: DateUtils.dateOnly(scheduledAt),
      time: '$hour:$minute ${scheduledAt.hour >= 12 ? 'PM' : 'AM'}',
      addressType: row['addressType'] as String? ?? 'Home',
      address: row['address'] as String? ?? '',
      area: row['area'] as String? ?? '',
      city: row['city'] as String? ?? '',
      state: row['state'] as String? ?? '',
      pinCode: row['pinCode'] as String? ?? '',
      landmark: row['landmark'] as String? ?? '',
      status: row['status'] as String? ?? 'pending_assignment',
      paymentStatus: row['paymentStatus'] as String? ?? 'pending',
      clientRequestId: row['clientRequestId'] as String? ?? '',
    );
  }

  final String id;
  final CareService service;
  final DateTime date;
  final String time;
  final String addressType;
  final String address;
  final String area, city, state, pinCode;
  final String landmark;
  final String status;
  final String paymentStatus;
  final String clientRequestId;

  Booking withId(String value) => Booking(
    id: value,
    service: service,
    date: date,
    time: time,
    addressType: addressType,
    address: address,
    area: area,
    city: city,
    state: state,
    pinCode: pinCode,
    landmark: landmark,
    status: status,
    paymentStatus: paymentStatus,
    clientRequestId: clientRequestId,
  );

  Booking withStatus(String value) => Booking(
    id: id,
    service: service,
    date: date,
    time: time,
    addressType: addressType,
    address: address,
    area: area,
    city: city,
    state: state,
    pinCode: pinCode,
    landmark: landmark,
    status: value,
    paymentStatus: paymentStatus,
    clientRequestId: clientRequestId,
  );
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
