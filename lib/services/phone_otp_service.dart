import 'package:phone_email_auth/phone_email_auth.dart';

import '../core/auth_config.dart';
import 'appwrite_auth_service.dart';

class PhoneOtpException implements Exception {
  const PhoneOtpException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PhoneOtpService {
  PhoneOtpService._();

  static Future<void>? _initialization;

  static Future<void> initialize() async {
    final pendingInitialization = _initialization ??= PhoneEmail.initializeApp(
      clientId: phoneEmailClientId,
    );
    try {
      await pendingInitialization;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  static Future<
    ({String name, String firstName, String lastName, String phone})
  >
  authenticateWithVerifiedPhone({
    required String accessToken,
    required String mode,
    required String firstName,
    required String lastName,
  }) async {
    try {
      return await AppwriteAuthService.instance.authenticateWithPhoneEmail(
        accessToken: accessToken,
        mode: mode,
        firstName: firstName,
        lastName: lastName,
      );
    } on PhoneOtpException {
      rethrow;
    } on AppwriteAuthException catch (error) {
      throw PhoneOtpException(error.message);
    } catch (_) {
      throw const PhoneOtpException(
        'Could not verify your phone number. Check your connection and try again.',
      );
    }
  }
}
