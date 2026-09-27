import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/booking.dart';
import '../widgets/shared_widgets.dart';
import 'account_settings_screen.dart';
import 'help_support_screen.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.bookings,
    required this.profileName,
    required this.profilePhone,
    required this.onEditProfile,
    required this.onOpenSettings,
    required this.onLogout,
    required this.onOpenBookings,
  });

  final List<Booking> bookings;
  final String profileName;
  final String profilePhone;
  final VoidCallback onEditProfile;
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
                            profileName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            profilePhone.isEmpty
                                ? 'Add your name and mobile number'
                                : '+91 $profilePhone',
                            style: const TextStyle(
                              color: Color(0xFFD6E7E5),
                              fontSize: 11,
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
            icon: Icons.calendar_month_outlined,
            title: 'My bookings',
            subtitle:
                '${bookings.length} demo booking${bookings.length == 1 ? '' : 's'}',
            onTap: onOpenBookings,
          ),
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
            subtitle: 'Health information and notes',
            onTap: () => _openSection(
              context,
              'Medical history',
              Icons.favorite_border_rounded,
            ),
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
            subtitle: 'Addresses used for demo bookings',
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
            subtitle: 'Remove your saved profile and demo bookings',
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
}

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({
    super.key,
    required this.initialName,
    required this.initialPhone,
    required this.onSave,
  });

  final String initialName;
  final String initialPhone;
  final Future<void> Function(String name, String phone) onSave;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Personal details'),
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
                    'No OTP or authentication is used. Your name and phone are saved on this device and are not sent to a server.',
                    style: TextStyle(color: appInk, height: 1.4, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 23),
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
            textInputAction: TextInputAction.done,
            maxLength: 10,
            decoration: _profileInputDecoration(
              label: 'Mobile number',
              hint: '10-digit Indian number',
              icon: Icons.phone_outlined,
            ).copyWith(prefixText: '+91 ', counterText: ''),
            validator: (value) {
              final phone = value?.trim() ?? '';
              if (phone.isEmpty || RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
                return null;
              }
              return 'Enter a valid 10-digit mobile number';
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
        _nameController.text.trim(),
        _phoneController.text.trim(),
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

class AddressBookPage extends StatelessWidget {
  const AddressBookPage({super.key, required this.bookings});

  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final addresses = <String, Booking>{};
    for (final booking in bookings.reversed) {
      addresses.putIfAbsent(
        '${booking.addressType}:${booking.address}',
        () => booking,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Address book'),
        centerTitle: true,
        backgroundColor: appCanvas,
      ),
      body: addresses.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Addresses from your demo bookings will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: appMuted, height: 1.5),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final booking in addresses.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ReviewCard(
                      children: [
                        ReviewRow(
                          icon: Icons.location_on_outlined,
                          label: booking.addressType,
                          value:
                              '${booking.address}, ${booking.localitySummary}',
                        ),
                        if (booking.landmark.isNotEmpty) ...[
                          const Divider(height: 22),
                          ReviewRow(
                            icon: Icons.near_me_outlined,
                            label: 'Landmark',
                            value: booking.landmark,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
