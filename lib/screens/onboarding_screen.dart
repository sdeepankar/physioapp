import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_theme.dart';
import '../core/app_settings.dart';
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
    final bookingBadgeEnabled = preferences.getBool(bookingBadgeKey) ?? true;
    if (!mounted) return;

    final Widget nextPage = name == null || phone == null
        ? const UserDetailsPage()
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

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Your details'),
      centerTitle: true,
      backgroundColor: appCanvas,
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: appTeal),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Enter your name and phone number to continue. There is no OTP or password. These details are saved on this device only.',
                    style: TextStyle(color: appInk, height: 1.45, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: profileFieldDecoration(
              label: 'Full name',
              hint: 'Enter your name',
              icon: Icons.person_outline_rounded,
            ),
            validator: (value) => value == null || value.trim().length < 2
                ? 'Enter your name'
                : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            maxLength: 10,
            decoration: profileFieldDecoration(
              label: 'Phone number',
              hint: '10-digit Indian number',
              icon: Icons.phone_outlined,
            ).copyWith(prefixText: '+91 ', counterText: ''),
            validator: (value) =>
                value == null || !RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())
                ? 'Enter a valid 10-digit phone number'
                : null,
          ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: FilledButton(
        onPressed: _isSaving ? null : _saveDetails,
        style: FilledButton.styleFrom(
          backgroundColor: appTeal,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Continue'),
      ),
    ),
  );

  Future<void> _saveDetails() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isSaving = true);
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(profileNameKey, name);
      await preferences.setString(profilePhoneKey, phone);
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
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your details. Try again.'),
        ),
      );
    }
  }
}

InputDecoration profileFieldDecoration({
  required String label,
  required String hint,
  required IconData icon,
}) => InputDecoration(
  labelText: label,
  hintText: hint,
  prefixIcon: Icon(icon, color: appMuted, size: 20),
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

