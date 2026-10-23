import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/models.dart';

import '../core/appwrite_config.dart';
import '../models/booking.dart';
import '../models/care_service.dart';
import '../models/patient_profile.dart';

class AppwriteService {
  AppwriteService._()
    : client = Client()
          .setEndpoint(appwriteEndpoint)
          .setProject(appwriteProjectId) {
    account = Account(client);
    functions = Functions(client);
  }

  static final AppwriteService instance = AppwriteService._();

  final Client client;
  late final Account account;
  late final Functions functions;

  Future<String> ping() => client.ping();

  Future<Map<String, dynamic>> syncClientProfile(PatientProfile profile) =>
      _call('/profile/sync', {
        'name': profile.name,
        'phone': profile.phone,
        'gender': profile.gender,
        'age': profile.age,
      });

  Future<List<CareService>> listActiveServices() async {
    final response = await _call(
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
    final response = await _call(
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
    final response = await _call('/orders', {
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
    await _call('/orders/$orderId/cancel', const {});
  }

  Future<Map<String, dynamic>> _call(
    String path,
    Map<String, dynamic> body, {
    enums.ExecutionMethod method = enums.ExecutionMethod.pOST,
  }) async {
    final execution = await functions.createExecution(
      functionId: appwriteRegisteredEmailFunctionId,
      body: jsonEncode(body),
      xasync: false,
      path: path,
      method: method,
    );
    final statusCode = execution.responseStatusCode;
    Map<String, dynamic> response;
    try {
      response = Map<String, dynamic>.from(
        jsonDecode(execution.responseBody) as Map,
      );
    } on Object {
      if (statusCode >= 200 && statusCode < 300) {
        throw const FormatException(
          'The backend returned an invalid response.',
        );
      }
      throw FormatException('Backend request failed (HTTP $statusCode).');
    }
    if (statusCode < 200 || statusCode >= 300) {
      final message = response['message'];
      throw FormatException(
        message is String && message.isNotEmpty
            ? message
            : 'Backend request failed (HTTP $statusCode).',
      );
    }
    return response;
  }

  Future<String> sendEmailVerificationCode({required String email}) async {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty) {
      throw const FormatException('Email is required.');
    }

    // Appwrite creates the account only when this email is new; otherwise it
    // sends a login code for the existing account.
    final token = await account.createEmailToken(
      userId: ID.unique(),
      email: normalizedEmail,
    );
    return token.userId;
  }

  Future<String> sendLoginEmailVerificationCode({required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw const FormatException('Email is required.');
    }

    final execution = await functions.createExecution(
      functionId: appwriteRegisteredEmailFunctionId,
      body: jsonEncode({'email': normalizedEmail}),
      xasync: false,
      method: enums.ExecutionMethod.pOST,
    );
    if (execution.responseStatusCode < 200 ||
        execution.responseStatusCode >= 300) {
      throw const FormatException(
        'Could not check your account. Please try again.',
      );
    }

    final Map<String, dynamic> response;
    try {
      response = jsonDecode(execution.responseBody) as Map<String, dynamic>;
    } on FormatException {
      throw const FormatException(
        'The account check returned an invalid response. Please try again.',
      );
    } on TypeError {
      throw const FormatException(
        'The account check returned an invalid response. Please try again.',
      );
    }

    if (response['registered'] != true) {
      throw const FormatException(
        'No account found for this email. Please sign up first.',
      );
    }

    final userId = response['userId'];
    if (userId is! String || userId.isEmpty) {
      throw const FormatException(
        'The account check returned an invalid response. Please try again.',
      );
    }
    return userId;
  }

  Future<User> verifyEmailCode({
    required String userId,
    required String code,
    String? name,
  }) async {
    final normalizedCode = code.trim();
    if (userId.isEmpty || normalizedCode.isEmpty) {
      throw const FormatException('Enter the code sent to your email.');
    }

    var hasSession = false;
    try {
      await account.get();
      hasSession = true;
    } on AppwriteException catch (error) {
      if (error.code != 401) rethrow;
    }
    if (!hasSession) {
      try {
        await account.createSession(userId: userId, secret: normalizedCode);
      } on AppwriteException catch (error) {
        if (error.code == 401 ||
            error.type?.toLowerCase().contains('invalid_token') == true) {
          throw const FormatException(
            'Incorrect OTP. Please check the code and try again.',
          );
        }
        rethrow;
      }
    }
    var user = await account.get();
    final normalizedName = name?.trim() ?? '';
    if (user.name.trim().isEmpty && normalizedName.isNotEmpty) {
      user = await account.updateName(name: normalizedName);
    }
    return user;
  }

  Future<bool> isSignedIn() async {
    try {
      await account.get();
      return true;
    } on AppwriteException catch (error) {
      if (error.code == 401) return false;
      rethrow;
    }
  }

  Future<User> getCurrentUser() => account.get();

  Future<void> signOut() async {
    await account.deleteSession(sessionId: 'current');
  }
}
