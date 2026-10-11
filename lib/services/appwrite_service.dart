import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart' as enums;
import 'package:appwrite/models.dart';

import '../core/appwrite_config.dart';

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
