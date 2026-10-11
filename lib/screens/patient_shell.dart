import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_settings.dart';
import '../models/booking.dart';
import '../models/care_service.dart';
import '../models/patient_profile.dart';
import '../services/appwrite_service.dart';
import '../services/location_service.dart';
import 'booking_flow_screen.dart';
import 'booking_history_screen.dart';
import 'profile_screen.dart';
import 'account_settings_screen.dart';
import 'discovery_screens.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class PatientShell extends StatefulWidget {
  const PatientShell({
    super.key,
    required this.profile,
    required this.bookingBadgeEnabled,
  });

  final PatientProfile profile;
  final bool bookingBadgeEnabled;

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _index = 0;
  final List<Booking> _bookings = [];
  late PatientProfile _profile = widget.profile;
  CurrentPlace? _currentPlace;
  bool _isLocating = false;
  bool _hasUnreadNotifications = false;
  Timer? _exitHintTimer;
  bool _exitHintVisible = false;
  late bool _bookingBadgeEnabled = widget.bookingBadgeEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateLocation(automatic: true);
    });
  }

  @override
  void dispose() {
    _exitHintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        onServiceTap: _showService,
        onBrowseServices: _openServices,
        bookings: _bookings,
        onBookingTap: _openBooking,
        currentPlace: _currentPlace,
        isLocating: _isLocating,
        onLocationTap: _updateLocation,
        onSearchTap: _openSearch,
        onNotificationsTap: _openNotifications,
        hasUnreadNotifications: _hasUnreadNotifications && _bookingBadgeEnabled,
      ),
      BookingsPage(bookings: _bookings, onBookingCancelled: _removeBooking),
      const SimplePage(
        icon: Icons.local_offer_outlined,
        title: 'Offers for you',
        message: 'New deals on trusted care services are coming soon.',
      ),
      ProfilePage(
        bookings: _bookings,
        profile: _profile,
        onEditProfile: _editProfile,
        onEditMedicalHistory: _editMedicalHistory,
        onOpenSettings: _openSettings,
        onLogout: _logout,
        onOpenBookings: () => setState(() => _index = 1),
      ),
    ];
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleSystemBack();
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) {
            _clearExitHint();
            setState(() => _index = value);
          },
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFDDF4EE),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_offer_outlined),
              selectedIcon: Icon(Icons.local_offer_rounded),
              label: 'Offers',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void _handleSystemBack() {
    if (_index != 0) {
      _clearExitHint();
      setState(() => _index = 0);
      return;
    }
    if (_exitHintVisible) {
      _clearExitHint();
      SystemNavigator.pop();
      return;
    }
    setState(() => _exitHintVisible = true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Press back again to exit',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
          behavior: SnackBarBehavior.floating,
          width: 240,
          duration: Duration(seconds: 2),
          dismissDirection: DismissDirection.none,
        ),
      );
    _exitHintTimer?.cancel();
    _exitHintTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _exitHintVisible = false);
    });
  }

  void _clearExitHint() {
    _exitHintTimer?.cancel();
    _exitHintTimer = null;
    if (_exitHintVisible) {
      _exitHintVisible = false;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  void _openServices() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceListPage(onServiceTap: _showService),
      ),
    );
  }

  void _openSearch() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ServiceSearchPage(onServiceTap: _showService),
    ),
  );

  void _openNotifications() {
    setState(() => _hasUnreadNotifications = false);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationsPage(
          bookings: _bookings,
          onBookingCancelled: _removeBooking,
        ),
      ),
    );
  }

  Future<void> _updateLocation({bool automatic = false}) async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final place = await locateCurrentPlace();
      if (!mounted) return;
      setState(() => _currentPlace = place);
      if (!automatic) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location updated: ${place.displayName}')),
        );
      }
    } on LocationLookupException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showService(CareService service) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServiceDetailsPage(
          service: service,
          currentPlace: _currentPlace,
          onBookingConfirmed: _addBooking,
        ),
      ),
    );
  }

  void _addBooking(Booking booking) {
    setState(() {
      _bookings.insert(0, booking);
      _hasUnreadNotifications = true;
      _index = 1;
    });
  }

  void _removeBooking(String bookingId) {
    setState(() {
      _bookings.removeWhere((booking) => booking.id == bookingId);
    });
  }

  void _openBooking(Booking booking) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingDetailsPage(
          booking: booking,
          onBookingCancelled: _removeBooking,
        ),
      ),
    );
  }

  Future<void> _editProfile() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfileEditPage(
          initialProfile: _profile,
          onSave: (profile) async {
            final preferences = await SharedPreferences.getInstance();
            await preferences.setString(profileNameKey, profile.name);
            await preferences.setString(profilePhoneKey, profile.phone);
            await _saveOptionalString(
              preferences,
              profileGenderKey,
              profile.gender,
            );
            if (profile.age == null) {
              await preferences.remove(profileAgeKey);
            } else {
              await preferences.setInt(profileAgeKey, profile.age!);
            }
            await _saveOptionalString(
              preferences,
              profileBloodGroupKey,
              profile.bloodGroup,
            );
            await _saveOptionalString(
              preferences,
              profileAllergiesKey,
              profile.allergies,
            );
            await _saveOptionalString(
              preferences,
              profileConditionsKey,
              profile.conditions,
            );
            await _saveOptionalString(
              preferences,
              profileMedicationsKey,
              profile.medications,
            );
            await _saveOptionalString(
              preferences,
              profileEmergencyContactKey,
              profile.emergencyContact,
            );
            if (!mounted) return;
            setState(() => _profile = profile);
          },
        ),
      ),
    );
  }

  Future<void> _editMedicalHistory() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => MedicalHistoryPage(
          initialProfile: _profile,
          onSave: (profile) async {
            final preferences = await SharedPreferences.getInstance();
            await _saveOptionalString(
              preferences,
              profileBloodGroupKey,
              profile.bloodGroup,
            );
            await _saveOptionalString(
              preferences,
              profileAllergiesKey,
              profile.allergies,
            );
            await _saveOptionalString(
              preferences,
              profileConditionsKey,
              profile.conditions,
            );
            await _saveOptionalString(
              preferences,
              profileMedicationsKey,
              profile.medications,
            );
            await _saveOptionalString(
              preferences,
              profileEmergencyContactKey,
              profile.emergencyContact,
            );
            if (!mounted) return;
            setState(() => _profile = profile);
          },
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (settingsContext) => SettingsPage(
          bookingBadgeEnabled: _bookingBadgeEnabled,
          onBookingBadgeChanged: _setBookingBadgeEnabled,
          onClearGuestData: () {
            Navigator.of(settingsContext).pop();
            _logout();
          },
        ),
      ),
    );
  }

  Future<void> _setBookingBadgeEnabled(bool enabled) async {
    setState(() => _bookingBadgeEnabled = enabled);
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(bookingBadgeKey, enabled);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save this preference.')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out of this session?'),
        content: const Text(
          'This will remove your saved profile and health details, demo bookings, and detected location from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC4484B),
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !mounted) return;
    try {
      await AppwriteService.instance.signOut();
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(profileNameKey);
      await preferences.remove(profilePhoneKey);
      await preferences.remove(profileGenderKey);
      await preferences.remove(profileAgeKey);
      await preferences.remove(profileBloodGroupKey);
      await preferences.remove(profileAllergiesKey);
      await preferences.remove(profileConditionsKey);
      await preferences.remove(profileMedicationsKey);
      await preferences.remove(profileEmergencyContactKey);
      await preferences.remove(savedAddressesKey);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not log out. Please try again.')),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _bookings.clear();
      _profile = const PatientProfile();
      _currentPlace = null;
      _hasUnreadNotifications = false;
      _index = 0;
    });
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const ProfileSetupPage()),
      (_) => false,
    );
  }

  Future<void> _saveOptionalString(
    SharedPreferences preferences,
    String key,
    String value,
  ) async {
    if (value.trim().isEmpty) {
      await preferences.remove(key);
    } else {
      await preferences.setString(key, value.trim());
    }
  }
}
