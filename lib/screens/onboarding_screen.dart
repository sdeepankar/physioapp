import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_settings.dart';
import '../core/app_theme.dart';
import '../models/patient_profile.dart';
import '../services/appwrite_service.dart';
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
    final profile = PatientProfile(
      name: name ?? '',
      phone: preferences.getString(profilePhoneKey) ?? '',
      gender: preferences.getString(profileGenderKey) ?? '',
      age: preferences.getInt(profileAgeKey),
      bloodGroup: preferences.getString(profileBloodGroupKey) ?? '',
      allergies: preferences.getString(profileAllergiesKey) ?? '',
      conditions: preferences.getString(profileConditionsKey) ?? '',
      medications: preferences.getString(profileMedicationsKey) ?? '',
      emergencyContact: preferences.getString(profileEmergencyContactKey) ?? '',
    );
    final bookingBadgeEnabled = preferences.getBool(bookingBadgeKey) ?? true;
    if (!mounted) return;

    final Widget nextPage = name == null
        ? const ProfileSetupPage()
        : PatientShell(
            profile: profile,
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390, maxHeight: 390),
              child: Image.asset(
                'assets/images/paramedical_health_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  String? _gender;
  bool _isSignup = false;
  String? _pendingUserId;
  bool _isSaving = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appCanvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: ListView(
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
                    const SizedBox(height: 18),
                    Text(
                      _isSignup ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: appInk,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isSignup
                          ? 'Add your details, then verify your email with a one-time code.'
                          : 'Enter your email and we’ll send you a one-time sign-in code.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: appMuted, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    if (_isSignup && _pendingUserId == null) ...[
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: _decoration(
                          'Full name',
                          Icons.person_outline_rounded,
                        ),
                        validator: (value) {
                          if (!_isSignup || _pendingUserId != null) return null;
                          return (value ?? '').trim().length >= 2
                              ? null
                              : 'Enter your name';
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        inputFormatters: [
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            final digits = newValue.text.replaceAll(
                              RegExp(r'\D'),
                              '',
                            );
                            final hasCountryCode =
                                digits.startsWith('91') && digits.length > 10;
                            final phone = hasCountryCode
                                ? digits.substring(2)
                                : digits;
                            final limitedPhone = phone.length > 10
                                ? phone.substring(0, 10)
                                : phone;

                            int adjustOffset(int offset) {
                              if (offset < 0) return limitedPhone.length;
                              var digitOffset = newValue.text
                                  .substring(0, offset)
                                  .replaceAll(RegExp(r'\D'), '')
                                  .length;
                              if (hasCountryCode) {
                                digitOffset = (digitOffset - 2).clamp(
                                  0,
                                  limitedPhone.length,
                                );
                              }
                              return digitOffset.clamp(0, limitedPhone.length);
                            }

                            return newValue.copyWith(
                              text: limitedPhone,
                              selection: TextSelection(
                                baseOffset: adjustOffset(
                                  newValue.selection.baseOffset,
                                ),
                                extentOffset: adjustOffset(
                                  newValue.selection.extentOffset,
                                ),
                              ),
                              composing: TextRange.empty,
                            );
                          }),
                        ],
                        decoration: _decoration(
                          'Mobile number',
                          Icons.phone_outlined,
                        ).copyWith(prefixText: '+91 '),
                        validator: (value) {
                          if (!_isSignup || _pendingUserId != null) return null;
                          return RegExp(r'^[6-9]\d{9}$')
                                  .hasMatch(value?.trim() ?? '')
                              ? null
                              : 'Enter a valid 10-digit Indian mobile number';
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: _decoration(
                          'Gender (optional)',
                          Icons.wc_outlined,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Woman',
                            child: Text('Woman'),
                          ),
                          DropdownMenuItem(value: 'Man', child: Text('Man')),
                          DropdownMenuItem(
                            value: 'Non-binary',
                            child: Text('Non-binary'),
                          ),
                          DropdownMenuItem(
                            value: 'Prefer not to say',
                            child: Text('Prefer not to say'),
                          ),
                        ],
                        onChanged: (value) => setState(() => _gender = value),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: _decoration(
                          'Age (optional)',
                          Icons.cake_outlined,
                        ),
                        validator: (value) {
                          if (!_isSignup || _pendingUserId != null) {
                            return null;
                          }
                          final age = int.tryParse(value?.trim() ?? '');
                          return value == null ||
                                  value.trim().isEmpty ||
                                  (age != null && age >= 1 && age <= 120)
                              ? null
                              : 'Enter an age from 1 to 120';
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: _pendingUserId != null,
                      textInputAction: _pendingUserId == null
                          ? TextInputAction.done
                          : TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: _decoration(
                        'Email address',
                        Icons.email_outlined,
                      ),
                      validator: (value) {
                        final email = (value ?? '').trim();
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(email)
                            ? null
                            : 'Enter a valid email address';
                      },
                      onFieldSubmitted: (_) {
                        if (_pendingUserId == null) {
                          _sendEmailCode();
                        }
                      },
                    ),
                    if (_pendingUserId != null) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: _decoration(
                          'Email verification code',
                          Icons.mark_email_read_outlined,
                        ),
                        validator: (value) =>
                            RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                            ? null
                            : 'Enter the 6-digit code from your email',
                        onFieldSubmitted: (_) => _verifyEmailCode(),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(_error!, style: const TextStyle(color: appInk)),
                    ],
                    if (_notice != null) ...[
                      const SizedBox(height: 14),
                      Text(_notice!, style: const TextStyle(color: appTeal)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isSaving
                          ? null
                          : _pendingUserId == null
                          ? _sendEmailCode
                          : _verifyEmailCode,
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
                          : Text(
                              _pendingUserId == null
                                  ? _isSignup
                                        ? 'Continue'
                                        : 'Send login code'
                                  : 'Verify email and continue',
                            ),
                    ),
                    if (_pendingUserId != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isSaving ? null : _sendEmailCode,
                        child: const Text('Resend code'),
                      ),
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  _pendingUserId = null;
                                  _codeController.clear();
                                  _error = null;
                                  _notice = null;
                                });
                              },
                        child: const Text('Use a different email'),
                      ),
                    ],
                    if (_pendingUserId == null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => _changeMode(!_isSignup),
                        child: Text(
                          _isSignup
                              ? 'Already registered? Log in'
                              : 'Not registered? Sign up',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _changeMode(bool isSignup) {
    setState(() {
      _isSignup = isSignup;
      _codeController.clear();
      _error = null;
      _notice = null;
    });
  }

  Future<void> _sendEmailCode() async {
    if (_pendingUserId == null && _formKey.currentState?.validate() != true) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _error = null;
      _notice = null;
    });
    final email = _emailController.text.trim();
    try {
      final appwrite = AppwriteService.instance;
      final userId = _isSignup
          ? await appwrite.sendEmailVerificationCode(email: email)
          : await appwrite.sendLoginEmailVerificationCode(email: email);
      if (!mounted) return;
      setState(() {
        _pendingUserId = userId;
        _isSaving = false;
        _notice = 'A one-time code was sent to $email.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = _errorMessage(
          error,
          'Could not send a code. Please try again.',
        );
      });
    }
  }

  Future<void> _verifyEmailCode() async {
    if (_formKey.currentState?.validate() != true || _pendingUserId == null) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _error = null;
      _notice = null;
    });
    try {
      final user = await AppwriteService.instance.verifyEmailCode(
        userId: _pendingUserId!,
        code: _codeController.text,
        name: _isSignup ? _nameController.text : null,
      );
      final name = user.name.trim().isNotEmpty
          ? user.name.trim()
          : user.email.split('@').first;
      final preferences = await SharedPreferences.getInstance();
      final accountPhone = user.phone.replaceFirst(RegExp(r'^\+91'), '');
      final phone = _isSignup
          ? _phoneController.text.trim()
          : accountPhone.isNotEmpty
          ? accountPhone
          : preferences.getString(profilePhoneKey) ?? '';
      await preferences.setString(profileNameKey, name);
      await preferences.setString(profilePhoneKey, phone);
      if (_isSignup) {
        final age = int.tryParse(_ageController.text.trim());
        if (_gender == null) {
          await preferences.remove(profileGenderKey);
        } else {
          await preferences.setString(profileGenderKey, _gender!);
        }
        if (age == null) {
          await preferences.remove(profileAgeKey);
        } else {
          await preferences.setInt(profileAgeKey, age);
        }
      }
      final bookingBadgeEnabled = preferences.getBool(bookingBadgeKey) ?? true;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PatientShell(
            profile: PatientProfile(
              name: name,
              phone: phone,
              gender: preferences.getString(profileGenderKey) ?? '',
              age: preferences.getInt(profileAgeKey),
              bloodGroup: preferences.getString(profileBloodGroupKey) ?? '',
              allergies: preferences.getString(profileAllergiesKey) ?? '',
              conditions: preferences.getString(profileConditionsKey) ?? '',
              medications: preferences.getString(profileMedicationsKey) ?? '',
              emergencyContact:
                  preferences.getString(profileEmergencyContactKey) ?? '',
            ),
            bookingBadgeEnabled: bookingBadgeEnabled,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = _errorMessage(
          error,
          'Could not verify your email. Check the code and try again.',
        );
      });
    }
  }
}

String _errorMessage(Object error, String fallback) {
  if (error is FormatException) return error.message;
  if (error is AppwriteException && error.message != null) {
    return error.message!;
  }
  return fallback;
}

InputDecoration _decoration(String label, IconData icon) => InputDecoration(
  labelText: label,
  prefixIcon: Icon(icon, color: appMuted),
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
