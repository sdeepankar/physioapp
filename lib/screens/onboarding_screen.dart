import 'package:flutter/material.dart';
import 'package:phone_email_auth/phone_email_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_theme.dart';
import '../core/app_settings.dart';
import '../services/phone_otp_service.dart';
import 'patient_shell.dart';

class BrandedSplashScreen extends StatefulWidget {
  const BrandedSplashScreen({super.key});

  @override
  State<BrandedSplashScreen> createState() => _BrandedSplashScreenState();
}

class _BrandedSplashScreenState extends State<BrandedSplashScreen> {
  @override
  void initState() {
    super.initState();
    _continueFromSplash();
  }

  Future<void> _continueFromSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final preferences = await SharedPreferences.getInstance();
    final name = preferences.getString(profileNameKey);
    final phone = preferences.getString(profilePhoneKey);
    final phoneVerified = preferences.getBool(profilePhoneVerifiedKey) ?? false;
    final bookingBadgeEnabled = preferences.getBool(bookingBadgeKey) ?? true;
    if (!mounted) return;

    final Widget nextPage = name == null || phone == null || !phoneVerified
        ? PhoneEmailLoginPage()
        : PatientShell(
            userName: name,
            userPhone: phone,
            bookingBadgeEnabled: bookingBadgeEnabled,
          );
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => nextPage));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 390,
                    maxHeight: 390,
                  ),
                  child: Image.asset(
                    'assets/images/paramedical_health_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PhoneEmailLoginPage extends StatefulWidget {
  const PhoneEmailLoginPage({super.key});

  @override
  State<PhoneEmailLoginPage> createState() => _PhoneEmailLoginPageState();
}

class _PhoneEmailLoginPageState extends State<PhoneEmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isPhoneAuthReady = false;
  bool _isInitializingPhoneAuth = true;
  bool _isVerifyingPhone = false;
  bool _isSaving = false;
  String? _phoneAuthError;
  ({String name, String firstName, String lastName, String phone})?
  _verifiedProfile;

  @override
  void initState() {
    super.initState();
    _initializePhoneAuth();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _verifiedProfile;
    return Scaffold(
      backgroundColor: appCanvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 250,
                      maxHeight: 250,
                    ),
                    child: Image.asset(
                      'assets/images/paramedical_health_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Sign in to Deep Care',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: appInk,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Phone.Email securely verifies your phone. You only enter your number on their verification screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: appMuted, height: 1.5),
                  ),
                  if (profile == null) ...[
                    const SizedBox(height: 22),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _firstNameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.givenName],
                            decoration: _nameDecoration('First name'),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter your first name'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _lastNameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.familyName],
                            decoration: _nameDecoration('Last name'),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter your last name'
                                : null,
                            onFieldSubmitted: (_) => _continueWithPhoneEmail(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_isInitializingPhoneAuth ||
                      _isVerifyingPhone ||
                      _isSaving) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(color: appTeal),
                  ],
                  if (profile == null && _phoneAuthError == null) ...[
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _isInitializingPhoneAuth || _isVerifyingPhone
                          ? null
                          : _continueWithPhoneEmail,
                      icon: const Icon(Icons.verified_user_outlined),
                      label: const Text('Continue with Phone.Email'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: appTeal,
                      ),
                    ),
                  ],
                  if (profile != null) ...[
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE3EAEA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Review your details',
                            style: TextStyle(
                              color: appInk,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _VerifiedDetailRow(
                            label: 'First name',
                            value: profile.firstName.isEmpty
                                ? 'Not provided'
                                : profile.firstName,
                          ),
                          const SizedBox(height: 10),
                          _VerifiedDetailRow(
                            label: 'Last name',
                            value: profile.lastName.isEmpty
                                ? 'Not provided'
                                : profile.lastName,
                          ),
                          const SizedBox(height: 10),
                          _VerifiedDetailRow(
                            label: 'Mobile number',
                            value: '+91 ${profile.phone}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _isSaving
                          ? null
                          : () => _saveProfileFromProvider(
                              name: profile.name,
                              phone: profile.phone,
                            ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: appTeal,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Continue to Deep Care'),
                    ),
                  ],
                  if (_phoneAuthError case final error?) ...[
                    const SizedBox(height: 20),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: appInk, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _initializePhoneAuth,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Continue with Phone.Email'),
                      style: FilledButton.styleFrom(backgroundColor: appTeal),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfileFromProvider({
    required String name,
    required String phone,
  }) async {
    setState(() => _isSaving = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(profileNameKey, name);
      await preferences.setString(profilePhoneKey, phone);
      await preferences.setBool(profilePhoneVerifiedKey, true);
      final bookingBadgeEnabled = preferences.getBool(bookingBadgeKey) ?? true;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PatientShell(
            userName: name,
            userPhone: phone,
            bookingBadgeEnabled: bookingBadgeEnabled,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _phoneAuthError = 'Could not save your profile. Please try again.';
      });
    }
  }

  Future<void> _continueWithPhoneEmail() async {
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    if (!_isPhoneAuthReady) {
      await _initializePhoneAuth();
      if (!mounted || !_isPhoneAuthReady) return;
    }
    await _startPhoneVerification();
  }

  Future<void> _initializePhoneAuth() async {
    if (mounted) {
      setState(() {
        _isInitializingPhoneAuth = true;
        _isPhoneAuthReady = false;
        _phoneAuthError = null;
      });
    }
    try {
      await PhoneOtpService.initialize();
      if (!mounted) return;
      setState(() {
        _isInitializingPhoneAuth = false;
        _isPhoneAuthReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializingPhoneAuth = false;
        _isPhoneAuthReady = false;
        _phoneAuthError =
            'Phone verification is temporarily unavailable. Please try again.';
      });
    }
  }

  Future<void> _startPhoneVerification() async {
    FocusScope.of(context).unfocus();
    try {
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute<Map<String, dynamic>>(
          builder: (_) => const AuthScreen(),
        ),
      );
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _phoneAuthError =
              'Phone verification was closed. Continue when you are ready.';
        });
        return;
      }
      final authResponse = result[AppConstant.authResponse];
      if (authResponse is! LoginModel) {
        _showPhoneError('Phone verification returned an invalid result.');
        return;
      }
      await _onPhoneOtpSuccess(
        authResponse.accessTokenn ?? '',
        authResponse.jwtToken ?? '',
      );
    } catch (_) {
      if (!mounted) return;
      _showPhoneError('Phone verification could not start. Please try again.');
    }
  }

  Future<void> _onPhoneOtpSuccess(String accessToken, String _) async {
    if (accessToken.isEmpty) {
      _showPhoneError('Phone verification did not return a valid result.');
      return;
    }
    setState(() => _isVerifyingPhone = true);
    try {
      final profile = await PhoneOtpService.registerWithVerifiedPhone(
        accessToken: accessToken,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isVerifyingPhone = false;
        _verifiedProfile = profile;
      });
      FocusScope.of(context).unfocus();
    } on PhoneOtpException catch (error) {
      if (!mounted) return;
      setState(() => _isVerifyingPhone = false);
      _showPhoneError(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isVerifyingPhone = false);
      _showPhoneError('Could not verify your number. Please try again.');
    }
  }

  void _showPhoneError(String message) {
    if (!mounted) return;
    setState(() {
      _isInitializingPhoneAuth = false;
      _isVerifyingPhone = false;
      _isSaving = false;
      _phoneAuthError = message;
    });
  }
}

class _VerifiedDetailRow extends StatelessWidget {
  const _VerifiedDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 112,
        child: Text(
          label,
          style: const TextStyle(color: appMuted, fontSize: 13),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: appInk,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

InputDecoration _nameDecoration(String label) => InputDecoration(
  labelText: label,
  prefixIcon: const Icon(Icons.person_outline_rounded, color: appMuted),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(color: Color(0xFFE3EAEA)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(color: Color(0xFFE3EAEA)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(color: appTeal, width: 1.5),
  ),
);
