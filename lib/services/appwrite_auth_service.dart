import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;

import '../core/auth_config.dart';
import 'appwrite_service.dart';

/// Exchanges a Phone.Email verified-phone result for an Appwrite session.
class AppwriteAuthService {
  AppwriteAuthService._()
    : _functions = Functions(AppwriteService.instance.client),
      _account = Account(AppwriteService.instance.client);

  static final AppwriteAuthService instance = AppwriteAuthService._();

  final Functions _functions;
  final Account _account;

  /// Deletes the current Appwrite session. A missing or expired session is
  /// already logged out and is therefore treated as success.
  Future<void> logout() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (error) {
      if (error.code == 401) return;
      throw AppwriteAuthException(
        'Could not end the Appwrite session '
        '(${error.code ?? 'unknown'}: ${error.type ?? 'Appwrite error'}).',
      );
    }
  }

  Future<({String name, String firstName, String lastName, String phone})>
  authenticateWithPhoneEmail({
    required String accessToken,
    required String mode,
    required String firstName,
    required String lastName,
  }) async {
    if (mode != 'login' && mode != 'register') {
      throw const AppwriteAuthException(
        'Choose login or account registration.',
      );
    }
    if (accessToken.isEmpty) {
      throw const AppwriteAuthException(
        'Phone verification returned no token.',
      );
    }

    late final dynamic execution;
    try {
      execution = await _functions.createExecution(
        functionId: phoneEmailAuthFunctionId,
        body: jsonEncode({
          'accessToken': accessToken,
          'mode': mode,
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
        }),
        xasync: false,
        method: enums.ExecutionMethod.pOST,
      );
    } on AppwriteException catch (error) {
      throw AppwriteAuthException(
        'Could not invoke the authentication Function '
        '(${error.code ?? 'unknown'}: ${error.type ?? 'Appwrite error'}).',
      );
    }

    if (execution.responseStatusCode < 200 ||
        execution.responseStatusCode >= 300) {
      String? message;
      try {
        final body = jsonDecode(execution.responseBody) as Map<String, dynamic>;
        message = body['error'] as String?;
      } catch (_) {
        // Use the safe generic message below for unexpected function responses.
      }
      throw AppwriteAuthException(
        message ?? 'Could not complete registration. Please try again.',
      );
    }

    final Map<String, dynamic> result;
    try {
      result = jsonDecode(execution.responseBody) as Map<String, dynamic>;
    } catch (_) {
      throw const AppwriteAuthException(
        'The registration service returned an invalid response.',
      );
    }

    final userId = result['userId'];
    final secret = result['secret'];
    final verifiedPhone = result['phone'];
    final profileName = result['name'];
    final returnedFirstName = result['firstName'];
    final returnedLastName = result['lastName'];
    if (userId is! String ||
        secret is! String ||
        verifiedPhone is! String ||
        profileName is! String ||
        returnedFirstName is! String ||
        returnedLastName is! String) {
      throw const AppwriteAuthException(
        'The registration service returned incomplete account details.',
      );
    }
    if (!RegExp(r'^\+91[6-9]\d{9}$').hasMatch(verifiedPhone)) {
      throw const AppwriteAuthException(
        'Deep Care currently supports verified Indian mobile numbers.',
      );
    }

    late final String? activeUserId;
    try {
      final session = await _account.getSession(sessionId: 'current');
      activeUserId = session.userId;
    } on AppwriteException catch (error) {
      if (error.code == 401) {
        activeUserId = null;
      } else {
        throw AppwriteAuthException(
          'Could not check the current Appwrite session '
          '(${error.code ?? 'unknown'}: ${error.type ?? 'Appwrite error'}).',
        );
      }
    }

    if (activeUserId == userId) {
      // The user may retry after a prior successful session creation. Reuse it.
    } else {
      if (activeUserId != null) {
        try {
          await _account.deleteSession(sessionId: 'current');
        } on AppwriteException catch (error) {
          throw AppwriteAuthException(
            'Could not replace the current Appwrite session '
            '(${error.code ?? 'unknown'}: ${error.type ?? 'Appwrite error'}).',
          );
        }
      }
      try {
        await _account.createSession(userId: userId, secret: secret);
      } on AppwriteException catch (error) {
        throw AppwriteAuthException(
          'The authentication Function completed, but Appwrite could not '
          'create the login session (${error.code ?? 'unknown'}: '
          '${error.type ?? 'Appwrite error'}).',
        );
      }
    }
    return (
      name: profileName,
      firstName: returnedFirstName,
      lastName: returnedLastName,
      phone: verifiedPhone.substring(3),
    );
  }
}

class AppwriteAuthException implements Exception {
  const AppwriteAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
