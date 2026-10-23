import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_settings.dart';
import '../core/app_theme.dart';
import '../models/booking.dart';
import '../models/patient_profile.dart';
import '../models/saved_address.dart';
import 'account_settings_screen.dart';
import 'help_support_screen.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.bookings,
    required this.profile,
    required this.onEditProfile,
    required this.onEditMedicalHistory,
    required this.onOpenSettings,
    required this.onLogout,
    required this.onOpenBookings,
  });

  final List<Booking> bookings;
  final PatientProfile profile;
  final VoidCallback onEditProfile;
  final VoidCallback onEditMedicalHistory;
  final VoidCallback onOpenSettings;
  final VoidCallback onLogout;
  final VoidCallback onOpenBookings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text(
            'My profile',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: appInk,
            ),
          ),
          const SizedBox(height: 17),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onEditProfile,
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF173B4A), Color(0xFF087F70)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _profileSummary(profile),
                            style: const TextStyle(
                              color: Color(0xFFD6E7E5),
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 23),
          const Text(
            'Your care',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: appInk,
            ),
          ),
          const SizedBox(height: 8),
          ProfileMenuTile(
            icon: Icons.folder_open_outlined,
            title: 'My documents',
            subtitle: 'Reports and care documents',
            onTap: () => _openSection(
              context,
              'My documents',
              Icons.folder_open_outlined,
            ),
          ),
          ProfileMenuTile(
            icon: Icons.favorite_border_rounded,
            title: 'Medical history',
            subtitle:
                profile.bloodGroup.isEmpty &&
                    profile.allergies.isEmpty &&
                    profile.conditions.isEmpty &&
                    profile.medications.isEmpty &&
                    profile.emergencyContact.isEmpty
                ? 'Add allergies, conditions, and other health notes'
                : 'View or update your health details',
            onTap: onEditMedicalHistory,
          ),
          ProfileMenuTile(
            icon: Icons.people_outline_rounded,
            title: 'Family members',
            subtitle: 'Manage care for your family',
            onTap: () => _openSection(
              context,
              'Family members',
              Icons.people_outline_rounded,
            ),
          ),
          ProfileMenuTile(
            icon: Icons.location_on_outlined,
            title: 'Address book',
            subtitle: 'Addresses used for bookings',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AddressBookPage(bookings: bookings),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Preferences & support',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: appInk,
            ),
          ),
          const SizedBox(height: 8),
          ProfileMenuTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Payment methods',
            subtitle: 'UPI',
            onTap: () => _openSection(
              context,
              'Payment methods',
              Icons.account_balance_wallet_outlined,
            ),
          ),
          ProfileMenuTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Notifications, permissions and app info',
            onTap: onOpenSettings,
          ),
          ProfileMenuTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & support',
            subtitle: 'Get help with care services',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    HelpSupportScreen(onOpenBookings: onOpenBookings),
              ),
            ),
          ),
          ProfileMenuTile(
            icon: Icons.logout_rounded,
            title: 'Log out',
            subtitle: 'Sign out and clear locally saved health details',
            isDestructive: true,
            onTap: onLogout,
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Profile details are stored on this device',
              style: TextStyle(color: appMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  void _openSection(BuildContext context, String title, IconData icon) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfileSectionPage(title: title, icon: icon),
      ),
    );
  }

  String _profileSummary(PatientProfile profile) {
    final details = <String>[];
    if (profile.phone.isNotEmpty) details.add('+91 ${profile.phone}');
    if (profile.age != null) details.add('Age ${profile.age}');
    if (profile.gender.isNotEmpty) details.add(profile.gender);
    return details.isEmpty
        ? 'Add your age and contact details'
        : details.join(' · ');
  }
}

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({
    super.key,
    required this.initialProfile,
    required this.onSave,
  });

  final PatientProfile initialProfile;
  final Future<void> Function(PatientProfile profile) onSave;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ageController;
  String? _gender;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _nameController = TextEditingController(text: profile.name);
    _phoneController = TextEditingController(text: profile.phone);
    _ageController = TextEditingController(text: profile.age?.toString() ?? '');
    _gender = profile.gender.isEmpty ? null : profile.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Your profile'),
      centerTitle: true,
      backgroundColor: appCanvas,
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F5F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: appTeal),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your account details sync to your Deep Care profile. Medical history stays on this device.',
                    style: TextStyle(color: appInk, height: 1.4, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 23),
          const _ProfileSectionHeading('Personal details'),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _profileInputDecoration(
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
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: _profileInputDecoration(
              label: 'Mobile number',
              hint: '10-digit Indian number',
              icon: Icons.phone_outlined,
            ).copyWith(prefixText: '+91 '),
            validator: (value) {
              final phone = value?.trim() ?? '';
              return phone.isEmpty || RegExp(r'^[6-9]\d{9}$').hasMatch(phone)
                  ? null
                  : 'Enter a valid 10-digit mobile number';
            },
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: _profileInputDecoration(
              label: 'Gender (optional)',
              hint: 'Select if you wish',
              icon: Icons.wc_outlined,
            ),
            items: const [
              DropdownMenuItem(value: 'Woman', child: Text('Woman')),
              DropdownMenuItem(value: 'Man', child: Text('Man')),
              DropdownMenuItem(value: 'Non-binary', child: Text('Non-binary')),
              DropdownMenuItem(
                value: 'Prefer not to say',
                child: Text('Prefer not to say'),
              ),
            ],
            onChanged: (value) => setState(() => _gender = value),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: _profileInputDecoration(
              label: 'Age (optional)',
              hint: 'Enter your age',
              icon: Icons.cake_outlined,
            ),
            validator: (value) {
              final age = int.tryParse(value?.trim() ?? '');
              return value == null ||
                      value.trim().isEmpty ||
                      (age != null && age >= 1 && age <= 120)
                  ? null
                  : 'Enter an age from 1 to 120';
            },
          ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: FilledButton(
        onPressed: _save,
        style: FilledButton.styleFrom(
          backgroundColor: appTeal,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Save details'),
      ),
    ),
  );

  InputDecoration _profileInputDecoration({
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

  void _save() {
    if (_formKey.currentState?.validate() != true) return;
    _saveChanges();
  }

  Future<void> _saveChanges() async {
    try {
      await widget.onSave(
        PatientProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          gender: _gender ?? '',
          age: int.tryParse(_ageController.text.trim()),
          bloodGroup: widget.initialProfile.bloodGroup,
          allergies: widget.initialProfile.allergies,
          conditions: widget.initialProfile.conditions,
          medications: widget.initialProfile.medications,
          emergencyContact: widget.initialProfile.emergencyContact,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your profile. Try again.'),
        ),
      );
    }
  }
}

class MedicalHistoryPage extends StatefulWidget {
  const MedicalHistoryPage({
    super.key,
    required this.initialProfile,
    required this.onSave,
  });

  final PatientProfile initialProfile;
  final Future<void> Function(PatientProfile profile) onSave;

  @override
  State<MedicalHistoryPage> createState() => _MedicalHistoryPageState();
}

class _MedicalHistoryPageState extends State<MedicalHistoryPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bloodGroupController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _conditionsController;
  late final TextEditingController _medicationsController;
  late final TextEditingController _emergencyContactController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _bloodGroupController = TextEditingController(text: profile.bloodGroup);
    _allergiesController = TextEditingController(text: profile.allergies);
    _conditionsController = TextEditingController(text: profile.conditions);
    _medicationsController = TextEditingController(text: profile.medications);
    _emergencyContactController = TextEditingController(
      text: profile.emergencyContact,
    );
  }

  @override
  void dispose() {
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Medical history'),
      centerTitle: true,
      backgroundColor: appCanvas,
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFE1F5F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: appTeal),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These optional details are stored locally on this device, not sent to a server. This section is not for emergency care.',
                    style: TextStyle(color: appInk, height: 1.4, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 23),
          const _ProfileSectionHeading('Medical details (optional)'),
          TextFormField(
            controller: _bloodGroupController,
            textCapitalization: TextCapitalization.characters,
            decoration: _profileInputDecoration(
              label: 'Blood group',
              hint: 'For example, O+',
              icon: Icons.bloodtype_outlined,
            ),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _allergiesController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: _profileInputDecoration(
              label: 'Allergies',
              hint: 'List any known allergies',
              icon: Icons.warning_amber_outlined,
            ),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _conditionsController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: _profileInputDecoration(
              label: 'Existing conditions',
              hint: 'For example, asthma or diabetes',
              icon: Icons.health_and_safety_outlined,
            ),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _medicationsController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: _profileInputDecoration(
              label: 'Current medications',
              hint: 'List medicines you currently take',
              icon: Icons.medication_outlined,
            ),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _emergencyContactController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: _profileInputDecoration(
              label: 'Emergency contact (optional)',
              hint: '10-digit Indian number',
              icon: Icons.contact_phone_outlined,
            ).copyWith(prefixText: '+91 '),
            validator: (value) {
              final phone = value?.trim() ?? '';
              return phone.isEmpty || RegExp(r'^[6-9]\d{9}$').hasMatch(phone)
                  ? null
                  : 'Enter a valid 10-digit Indian mobile number';
            },
          ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: FilledButton(
        onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(
          backgroundColor: appTeal,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _saving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Save medical history'),
      ),
    ),
  );

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    try {
      final profile = widget.initialProfile;
      await widget.onSave(
        PatientProfile(
          name: profile.name,
          phone: profile.phone,
          gender: profile.gender,
          age: profile.age,
          bloodGroup: _bloodGroupController.text.trim().toUpperCase(),
          allergies: _allergiesController.text.trim(),
          conditions: _conditionsController.text.trim(),
          medications: _medicationsController.text.trim(),
          emergencyContact: _emergencyContactController.text.trim(),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save medical history. Try again.'),
        ),
      );
    }
  }
}

InputDecoration _profileInputDecoration({
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

class _ProfileSectionHeading extends StatelessWidget {
  const _ProfileSectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        color: appInk,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Icon(
          icon,
          color: isDestructive ? const Color(0xFFC4484B) : appTeal,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? const Color(0xFFC4484B) : appInk,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: appMuted, fontSize: 11),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: appMuted),
        onTap: onTap,
      ),
    ),
  );
}

class SavedAddressEditPage extends StatefulWidget {
  const SavedAddressEditPage({super.key, this.address});

  final SavedAddress? address;

  @override
  State<SavedAddressEditPage> createState() => _SavedAddressEditPageState();
}

class _SavedAddressEditPageState extends State<SavedAddressEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressController;
  late final TextEditingController _areaController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pinCodeController;
  late final TextEditingController _landmarkController;
  late String _addressType;

  static const _addressTypes = ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _addressController = TextEditingController(text: address?.address ?? '');
    _areaController = TextEditingController(text: address?.area ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _stateController = TextEditingController(text: address?.state ?? '');
    _pinCodeController = TextEditingController(text: address?.pinCode ?? '');
    _landmarkController = TextEditingController(text: address?.landmark ?? '');
    _addressType = _addressTypes.contains(address?.addressType)
        ? address!.addressType
        : 'Home';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.address == null ? 'Add address' : 'Edit address'),
      centerTitle: true,
      backgroundColor: appCanvas,
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Save location as'),
          const SizedBox(height: 9),
          Wrap(
            spacing: 9,
            children: [
              for (final type in _addressTypes)
                ChoiceChip(
                  label: Text(type),
                  selected: _addressType == type,
                  onSelected: (_) => setState(() => _addressType = type),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _addressField(
            controller: _addressController,
            label: 'House / flat and street address',
            hint: 'Enter your complete address',
            icon: Icons.location_on_outlined,
            capitalization: TextCapitalization.sentences,
            minLines: 2,
            validator: (value) => value == null || value.trim().length < 8
                ? 'Enter a complete address'
                : null,
          ),
          const SizedBox(height: 14),
          _addressField(
            controller: _areaController,
            label: 'Area / locality',
            hint: 'Neighbourhood or locality',
            icon: Icons.map_outlined,
            capitalization: TextCapitalization.words,
            validator: _requiredAddressPart('Enter your area'),
          ),
          const SizedBox(height: 14),
          _addressField(
            controller: _cityController,
            label: 'City',
            hint: 'City or town',
            icon: Icons.location_city_outlined,
            capitalization: TextCapitalization.words,
            validator: _requiredAddressPart('Enter your city'),
          ),
          const SizedBox(height: 14),
          _addressField(
            controller: _stateController,
            label: 'State',
            hint: 'State',
            icon: Icons.map_outlined,
            capitalization: TextCapitalization.words,
            validator: _requiredAddressPart('Enter your state'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _pinCodeController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: _profileInputDecoration(
              label: 'PIN code',
              hint: '6-digit PIN code',
              icon: Icons.local_post_office_outlined,
            ),
            validator: (value) =>
                RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '')
                ? null
                : 'Enter a valid 6-digit PIN code',
          ),
          const SizedBox(height: 14),
          _addressField(
            controller: _landmarkController,
            label: 'Landmark (optional)',
            hint: 'Nearby landmark',
            icon: Icons.near_me_outlined,
            capitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: FilledButton(
        onPressed: _save,
        style: FilledButton.styleFrom(
          backgroundColor: appTeal,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Save address'),
      ),
    ),
  );

  String? Function(String?) _requiredAddressPart(String message) =>
      (value) => value == null || value.trim().isEmpty ? message : null;

  Widget _addressField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextCapitalization capitalization,
    int? minLines,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    textCapitalization: capitalization,
    minLines: minLines,
    maxLines: minLines == null ? 1 : minLines + 1,
    decoration: _profileInputDecoration(label: label, hint: hint, icon: icon),
    validator: validator,
  );

  void _save() {
    if (_formKey.currentState?.validate() != true) return;
    final existing = widget.address;
    Navigator.of(context).pop(
      SavedAddress(
        id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        label: _addressType,
        addressType: _addressType,
        address: _addressController.text.trim(),
        area: _areaController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pinCode: _pinCodeController.text.trim(),
        landmark: _landmarkController.text.trim(),
      ),
    );
  }
}

class AddressBookPage extends StatefulWidget {
  const AddressBookPage({super.key, required this.bookings});

  final List<Booking> bookings;

  @override
  State<AddressBookPage> createState() => _AddressBookPageState();
}

class _AddressBookPageState extends State<AddressBookPage> {
  List<SavedAddress> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(savedAddressesKey);
      final addresses = encoded == null
          ? _addressesFromBookings()
          : (jsonDecode(encoded) as List<dynamic>)
                .map(
                  (item) => SavedAddress.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList();
      if (encoded == null && addresses.isNotEmpty) {
        await _persistAddresses(addresses);
      }
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load your saved addresses.')),
      );
    }
  }

  List<SavedAddress> _addressesFromBookings() {
    final addresses = <String, SavedAddress>{};
    for (final booking in widget.bookings.reversed) {
      final key = '${booking.addressType}:${booking.address}';
      addresses.putIfAbsent(
        key,
        () => SavedAddress(
          id: key,
          label: booking.addressType,
          addressType: booking.addressType,
          address: booking.address,
          area: booking.area,
          city: booking.city,
          state: booking.state,
          pinCode: booking.pinCode,
          landmark: booking.landmark,
        ),
      );
    }
    return addresses.values.toList();
  }

  Future<void> _persistAddresses(List<SavedAddress> addresses) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      savedAddressesKey,
      jsonEncode(addresses.map((address) => address.toJson()).toList()),
    );
  }

  Future<void> _addAddress() async {
    final address = await Navigator.of(context).push<SavedAddress>(
      MaterialPageRoute<SavedAddress>(
        builder: (_) => const SavedAddressEditPage(),
      ),
    );
    if (address == null || !mounted) return;
    await _updateAddresses([..._addresses, address]);
  }

  Future<void> _editAddress(SavedAddress existing) async {
    final updated = await Navigator.of(context).push<SavedAddress>(
      MaterialPageRoute<SavedAddress>(
        builder: (_) => SavedAddressEditPage(address: existing),
      ),
    );
    if (updated == null || !mounted) return;
    await _updateAddresses([
      for (final address in _addresses)
        if (address.id == existing.id) updated else address,
    ]);
  }

  Future<void> _deleteAddress(SavedAddress address) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('Remove ${address.label} from your address book?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    await _updateAddresses(
      _addresses.where((item) => item.id != address.id).toList(),
    );
  }

  Future<void> _updateAddresses(List<SavedAddress> addresses) async {
    try {
      await _persistAddresses(addresses);
      if (mounted) setState(() => _addresses = addresses);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save your address. Try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Address book'),
        centerTitle: true,
        backgroundColor: appCanvas,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: appTeal))
          : _addresses.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 54,
                      color: appTeal,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No saved addresses yet',
                      style: TextStyle(
                        color: appInk,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Add an address to keep your care locations in one place.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: appMuted, height: 1.5),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _addAddress,
                      icon: const Icon(Icons.add),
                      label: const Text('Add address'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final address in _addresses)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: appTeal,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    address.label,
                                    style: const TextStyle(
                                      color: appInk,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Edit address',
                                  onPressed: () => _editAddress(address),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: appTeal,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete address',
                                  onPressed: () => _deleteAddress(address),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFC4484B),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              address.address,
                              style: const TextStyle(
                                color: appInk,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address.localitySummary,
                              style: const TextStyle(
                                color: appMuted,
                                height: 1.4,
                              ),
                            ),
                            if (address.landmark.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Landmark: ${address.landmark}',
                                style: const TextStyle(
                                  color: appMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: !_loading && _addresses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _addAddress,
              backgroundColor: appTeal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add address'),
            )
          : null,
    );
  }
}
