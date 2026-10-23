import 'package:appwrite/enums.dart' as enums;

import '../../services/appwrite_service.dart';
import '../models/booking.dart';
import '../models/care_service.dart';
import '../models/patient_profile.dart';

/// Appwrite operations that are specific to the client booking experience.
class AppwriteClientService {
  AppwriteClientService._();

  static final AppwriteClientService instance = AppwriteClientService._();

  final AppwriteService _appwrite = AppwriteService.instance;

  Future<Map<String, dynamic>> syncClientProfile(PatientProfile profile) =>
      _appwrite.callApi('/profile/sync', {
        'name': profile.name,
        'phone': profile.phone,
        'gender': profile.gender,
        'age': profile.age,
      });

  Future<List<CareService>> listActiveServices() async {
    final response = await _appwrite.callApi(
      '/services',
      const {},
      method: enums.ExecutionMethod.gET,
    );
    final rows = response['rows'];
    if (rows is! List) {
      throw const FormatException('The service list response was invalid.');
    }
    return rows
        .whereType<Map>()
        .map((row) => CareService.fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<Booking>> listClientOrders() async {
    final response = await _appwrite.callApi(
      '/orders',
      const {},
      method: enums.ExecutionMethod.gET,
    );
    final rows = response['rows'];
    if (rows is! List) {
      throw const FormatException('The booking list response was invalid.');
    }
    return rows
        .whereType<Map>()
        .map((row) => Booking.fromOrderRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Booking> createOrder(Booking booking) async {
    if (booking.service.id.isEmpty) {
      throw const FormatException(
        'This service is not connected to the database. Reload services and try again.',
      );
    }
    if (booking.clientRequestId.isEmpty) {
      throw const FormatException(
        'This booking request has expired. Please review and submit it again.',
      );
    }
    final response = await _appwrite.callApi('/orders', {
      'clientRequestId': booking.clientRequestId,
      'serviceId': booking.service.id,
      'scheduledAt': booking.scheduledAt.toUtc().toIso8601String(),
      'addressType': booking.addressType,
      'address': booking.address,
      'area': booking.area,
      'city': booking.city,
      'state': booking.state,
      'pinCode': booking.pinCode,
      'landmark': booking.landmark,
    });
    final row = response['row'];
    if (row is! Map) {
      throw const FormatException('The new booking response was invalid.');
    }
    return Booking.fromOrderRow(Map<String, dynamic>.from(row));
  }

  Future<void> cancelClientOrder(String orderId) async {
    await _appwrite.callApi('/orders/$orderId/cancel', const {});
  }
}
