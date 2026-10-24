import 'package:appwrite/enums.dart' as enums;

import '../../services/appwrite_service.dart';

class ProviderService {
  ProviderService._();

  static final ProviderService instance = ProviderService._();

  final AppwriteService _appwrite = AppwriteService.instance;

  Future<Map<String, dynamic>> getStatus() => _appwrite.callApi(
    '/provider/status',
    const {},
    method: enums.ExecutionMethod.gET,
  );

  Future<Map<String, dynamic>> apply({
    required String name,
    required String phone,
    required String businessName,
    required List<String> serviceIds,
    required List<String> serviceAreas,
  }) async {
    final response = await _appwrite.callApi('/provider/apply', {
      'name': name,
      'phone': phone,
      'businessName': businessName,
      'serviceIds': serviceIds,
      'serviceAreas': serviceAreas,
    });
    final row = response['row'];
    if (row is! Map) {
      throw const FormatException(
        'The provider application response was invalid.',
      );
    }
    return Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> listServices() async {
    final response = await _appwrite.callApi(
      '/services',
      const {},
      method: enums.ExecutionMethod.gET,
    );
    final rows = response['rows'];
    if (rows is! List) {
      throw const FormatException('The service list response was invalid.');
    }
    return rows.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  Future<List<Map<String, dynamic>>> listAssignedOrders() async {
    final response = await _appwrite.callApi(
      '/provider/orders',
      const {},
      method: enums.ExecutionMethod.gET,
    );
    final rows = response['rows'];
    if (rows is! List) {
      throw const FormatException('The booking list response was invalid.');
    }
    return rows.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  Future<Map<String, dynamic>> setAvailability(bool isAvailable) async {
    final response = await _appwrite.callApi('/provider/availability', {
      'isAvailable': isAvailable,
    });
    final row = response['row'];
    if (row is! Map) {
      throw const FormatException('The availability response was invalid.');
    }
    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> updateOrder(
    String orderId,
    String action, {
    String note = '',
  }) async {
    final response = await _appwrite.callApi(
      '/provider/orders/${Uri.encodeComponent(orderId)}/$action',
      {'note': note},
    );
    final row = response['row'];
    if (row is! Map) {
      throw const FormatException('The booking update response was invalid.');
    }
    return Map<String, dynamic>.from(response);
  }
}
