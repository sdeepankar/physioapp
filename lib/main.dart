import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final preferences = await SharedPreferences.getInstance();
    _accessibilityPreferences.value = AccessibilityPreferences(
      textScale: preferences.getDouble(_textScaleKey) ?? 1,
      reduceMotion: preferences.getBool(_reduceMotionKey) ?? false,
    );
  } catch (_) {
    // App startup remains available if local preferences cannot be read.
  }
  runApp(const PhysioApp());
}

const _teal = Color(0xFF078F78);
const _ink = Color(0xFF172D36);
const _muted = Color(0xFF73838A);
const _canvas = Color(0xFFF5F8F8);
const _defaultAccessibility = AccessibilityPreferences();
const _profileNameKey = 'deep_care_profile_name';
const _profilePhoneKey = 'deep_care_profile_phone';
const _bookingBadgeKey = 'deep_care_booking_badge';
const _textScaleKey = 'deep_care_text_scale';
const _reduceMotionKey = 'deep_care_reduce_motion';
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class AccessibilityPreferences {
  const AccessibilityPreferences({
    this.textScale = 1,
    this.reduceMotion = false,
  });

  final double textScale;
  final bool reduceMotion;
}

final ValueNotifier<AccessibilityPreferences> _accessibilityPreferences =
    ValueNotifier(_defaultAccessibility);

void _setAccessibilityPreferences(AccessibilityPreferences preferences) {
  _accessibilityPreferences.value = preferences;
  unawaited(_storeAccessibilityPreferences(preferences));
}

Future<void> _storeAccessibilityPreferences(
  AccessibilityPreferences preferences,
) async {
  try {
    final storage = await SharedPreferences.getInstance();
    await storage.setDouble(_textScaleKey, preferences.textScale);
    await storage.setBool(_reduceMotionKey, preferences.reduceMotion);
  } catch (_) {
    // Keep the current app session usable when local settings cannot be saved.
  }
}

class CurrentPlace {
  const CurrentPlace({
    required this.area,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });
  final String area, city, state, postalCode, country;
  String get displayName => [
    area,
    city,
    state,
    postalCode,
  ].where((part) => part.isNotEmpty).join(', ');
  String get areaLine => [
    area,
    city,
    state,
    postalCode,
    country,
  ].where((part) => part.isNotEmpty).toSet().join(', ');
}

class LocationLookupException implements Exception {
  const LocationLookupException(this.message, {this.permanentlyDenied = false});
  final String message;
  final bool permanentlyDenied;
  @override
  String toString() => message;
}

Future<CurrentPlace> locateCurrentPlace() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationLookupException(
      'Turn on Location Services and try again.',
    );
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    throw const LocationLookupException(
      'Location permission is blocked. Enable it in app settings.',
      permanentlyDenied: true,
    );
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.unableToDetermine) {
    throw const LocationLookupException(
      'Location access was not granted. You can enter the address manually.',
    );
  }
  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    final placemarks = await Geocoding().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
      locale: const Locale('en', 'IN'),
    );
    if (placemarks.isEmpty) {
      throw const LocationLookupException(
        'Could not find an address for your location.',
      );
    }
    final place = placemarks.first;
    String clean(String? value) => value?.trim() ?? '';
    final area = clean(place.subLocality);
    final city = clean(place.locality).isNotEmpty
        ? clean(place.locality)
        : clean(place.subAdministrativeArea);
    final state = clean(place.administrativeArea);
    final postalCode = clean(place.postalCode);
    final country = clean(place.country);
    if ([area, city, state, postalCode].every((value) => value.isEmpty)) {
      throw const LocationLookupException(
        'Could not find area, city, state or PIN for your location.',
      );
    }
    return CurrentPlace(
      area: area,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
    );
  } on LocationLookupException {
    rethrow;
  } catch (_) {
    throw const LocationLookupException(
      'Could not resolve your location. Check location access and try again.',
    );
  }
}

class PhysioApp extends StatelessWidget {
  const PhysioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityPreferences>(
      valueListenable: _accessibilityPreferences,
      builder: (context, preferences, _) => MaterialApp(
        title: 'Deep Care',
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          final systemTextScale = media.textScaler.scale(1);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(
                systemTextScale * preferences.textScale,
              ),
              disableAnimations:
                  media.disableAnimations || preferences.reduceMotion,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: _canvas,
          colorScheme: ColorScheme.fromSeed(seedColor: _teal, surface: _canvas),
          pageTransitionsTheme: preferences.reduceMotion
              ? PageTransitionsTheme(
                  builders: {
                    for (final platform in TargetPlatform.values)
                      platform: const _NoMotionPageTransitionsBuilder(),
                  },
                )
              : const PageTransitionsTheme(),
          appBarTheme: const AppBarTheme(
            titleTextStyle: TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.35,
            ),
          ),
          fontFamily: 'Roboto',
        ),
        home: const BrandedSplashScreen(),
      ),
    );
  }
}

class _NoMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoMotionPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

class CareService {
  const CareService(
    this.name,
    this.subtitle,
    this.icon,
    this.color,
    this.price,
  );
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String price;
}

const _services = <CareService>[
  CareService(
    'Home Nursing',
    'Care at your home',
    Icons.medical_services_outlined,
    Color(0xFF43A8D4),
    '₹499',
  ),
  CareService(
    'Physiotherapy',
    'Expert recovery care',
    Icons.accessibility_new_rounded,
    Color(0xFF16A887),
    '₹699',
  ),
  CareService(
    'Caregiver',
    'Support for daily needs',
    Icons.volunteer_activism_outlined,
    Color(0xFFF1A343),
    '₹399',
  ),
  CareService(
    'Elder Care',
    'Comfort for seniors',
    Icons.elderly_outlined,
    Color(0xFFEE6A74),
    '₹599',
  ),
  CareService(
    'Lab Sample',
    'Tests from home',
    Icons.science_outlined,
    Color(0xFF5596D8),
    '₹199',
  ),
  CareService(
    'Doctor Visit',
    'Consult at home',
    Icons.health_and_safety_outlined,
    Color(0xFF38A990),
    '₹799',
  ),
  CareService(
    'Health Check',
    'Stay on top of health',
    Icons.favorite_border_rounded,
    Color(0xFF8B71C5),
    '₹999',
  ),
  CareService(
    'Ambulance',
    'Emergency assistance',
    Icons.emergency_outlined,
    Color(0xFFE65D5D),
    'From ₹999',
  ),
];

class Booking {
  const Booking({
    required this.id,
    required this.service,
    required this.date,
    required this.time,
    required this.addressType,
    required this.address,
    required this.area,
    required this.city,
    required this.state,
    required this.pinCode,
    required this.landmark,
  });

  final String id;
  final CareService service;
  final DateTime date;
  final String time;
  final String addressType;
  final String address;
  final String area, city, state, pinCode;
  final String landmark;
  DateTime get scheduledAt {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s+(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(time.trim());
    if (match == null) return DateUtils.dateOnly(date);

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String get localitySummary =>
      [area, city, state, pinCode].where((part) => part.isNotEmpty).join(', ');
}

class _BookingAddressBlock extends StatelessWidget {
  const _BookingAddressBlock({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: IntrinsicWidth(
      child: Text(
        [
          booking.address,
          booking.area,
          [
            booking.city,
            booking.state,
            booking.pinCode,
          ].where((part) => part.isNotEmpty).join(', '),
        ].where((line) => line.isNotEmpty).join('\n'),
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: _ink,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.55,
        ),
      ),
    ),
  );
}

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
    final name = preferences.getString(_profileNameKey);
    final phone = preferences.getString(_profilePhoneKey);
    final bookingBadgeEnabled = preferences.getBool(_bookingBadgeKey) ?? true;
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
      backgroundColor: _canvas,
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
                Icon(Icons.info_outline_rounded, color: _teal),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Enter your name and phone number to continue. There is no OTP or password. These details are saved on this device only.',
                    style: TextStyle(color: _ink, height: 1.45, fontSize: 13),
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
            decoration: _profileFieldDecoration(
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
            decoration: _profileFieldDecoration(
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
          backgroundColor: _teal,
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
      await preferences.setString(_profileNameKey, name);
      await preferences.setString(_profilePhoneKey, phone);
      final bookingBadgeEnabled = preferences.getBool(_bookingBadgeKey) ?? true;
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

InputDecoration _profileFieldDecoration({
  required String label,
  required String hint,
  required IconData icon,
}) => InputDecoration(
  labelText: label,
  hintText: hint,
  prefixIcon: Icon(icon, color: _muted, size: 20),
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
    borderSide: const BorderSide(color: _teal, width: 1.5),
  ),
);

class PatientShell extends StatefulWidget {
  const PatientShell({
    super.key,
    required this.userName,
    required this.userPhone,
    required this.bookingBadgeEnabled,
  });

  final String userName;
  final String userPhone;
  final bool bookingBadgeEnabled;

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  int _index = 0;
  final List<Booking> _bookings = [];
  late String _profileName = widget.userName;
  late String _profilePhone = widget.userPhone;
  CurrentPlace? _currentPlace;
  bool _isLocating = false;
  bool _hasUnreadNotifications = false;
  late bool _bookingBadgeEnabled = widget.bookingBadgeEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateLocation(automatic: true);
    });
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
        profileName: _profileName,
        profilePhone: _profilePhone,
        onEditProfile: _editProfile,
        onOpenSettings: _openSettings,
        onLogout: _logout,
        onOpenBookings: () => setState(() => _index = 1),
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
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
    );
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
          initialName: _profileName,
          initialPhone: _profilePhone,
          onSave: (name, phone) async {
            final preferences = await SharedPreferences.getInstance();
            await preferences.setString(_profileNameKey, name);
            await preferences.setString(_profilePhoneKey, phone);
            if (!mounted) return;
            setState(() {
              _profileName = name;
              _profilePhone = phone;
            });
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
      await preferences.setBool(_bookingBadgeKey, enabled);
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
          'This will remove your saved name and phone number, demo bookings, and detected location from this device.',
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
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_profileNameKey);
      await preferences.remove(_profilePhoneKey);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not clear the saved profile.')),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _bookings.clear();
      _profileName = '';
      _profilePhone = '';
      _currentPlace = null;
      _hasUnreadNotifications = false;
      _index = 0;
    });
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const UserDetailsPage()),
      (_) => false,
    );
  }
}

class ServiceDetailsPage extends StatelessWidget {
  const ServiceDetailsPage({
    super.key,
    required this.service,
    required this.currentPlace,
    required this.onBookingConfirmed,
  });

  final CareService service;
  final CurrentPlace? currentPlace;
  final ValueChanged<Booking> onBookingConfirmed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service details'),
        centerTitle: true,
        backgroundColor: _canvas,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            height: 205,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE1F4EF), Color(0xFFD9EBF4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .8),
                  shape: BoxShape.circle,
                ),
                child: Icon(service.icon, size: 62, color: service.color),
              ),
            ),
          ),
          const SizedBox(height: 21),
          Text(
            service.name,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(service.subtitle, style: const TextStyle(color: _muted)),
          const SizedBox(height: 19),
          const Text(
            'About this service',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get professional, one-to-one care in the comfort of your home. We connect you with verified healthcare professionals and make it easy to find a time that works for you.',
            style: TextStyle(color: _muted, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _ServiceFeature(icon: Icons.schedule_rounded, label: '45–60 min'),
              const SizedBox(width: 10),
              _ServiceFeature(
                icon: Icons.verified_user_outlined,
                label: 'Verified expert',
              ),
              const SizedBox(width: 10),
              _ServiceFeature(icon: Icons.home_outlined, label: 'At your home'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Starting price',
                    style: TextStyle(color: _muted),
                  ),
                ),
                Text(
                  '${service.price} / session',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DateTimePage(
                service: service,
                currentPlace: currentPlace,
                onBookingConfirmed: onBookingConfirmed,
              ),
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _teal,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Book now'),
        ),
      ),
    );
  }
}

class _ServiceFeature extends StatelessWidget {
  const _ServiceFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _teal, size: 19),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: _muted),
          ),
        ],
      ),
    ),
  );
}

class DateTimePage extends StatefulWidget {
  const DateTimePage({
    super.key,
    required this.service,
    required this.currentPlace,
    required this.onBookingConfirmed,
  });

  final CareService service;
  final CurrentPlace? currentPlace;
  final ValueChanged<Booking> onBookingConfirmed;

  @override
  State<DateTimePage> createState() => _DateTimePageState();
}

class _DateTimePageState extends State<DateTimePage> {
  final DateTime _today = DateUtils.dateOnly(DateTime.now());
  int _selectedDay = 0;
  String? _selectedTime;

  static const _times = [
    '09:00 AM',
    '11:00 AM',
    '01:00 PM',
    '04:00 PM',
    '06:00 PM',
    '07:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
      14,
      (index) => _today.add(Duration(days: index)),
    );
    final selectedDate = dates[_selectedDay];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select date & time'),
        centerTitle: true,
        backgroundColor: _canvas,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            widget.service.name,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: _teal, size: 20),
              const SizedBox(width: 9),
              Text(
                '${_months[selectedDate.month - 1]} ${selectedDate.year}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final date = dates[index];
                final selected = index == _selectedDay;
                return InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => setState(() => _selectedDay = index),
                  child: AnimatedContainer(
                    duration: _accessibilityPreferences.value.reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 150),
                    width: 53,
                    decoration: BoxDecoration(
                      color: selected ? _teal : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: selected ? _teal : const Color(0xFFE7ECEC),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekdays[date.weekday - 1],
                          style: TextStyle(
                            color: selected
                                ? Colors.white.withValues(alpha: .8)
                                : _muted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: selected ? Colors.white : _ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Available time slots',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 13),
          GridView.builder(
            itemCount: _times.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.7,
            ),
            itemBuilder: (context, index) {
              final time = _times[index];
              final selected = time == _selectedTime;
              return OutlinedButton(
                onPressed: () => setState(() => _selectedTime = time),
                style: OutlinedButton.styleFrom(
                  foregroundColor: selected ? Colors.white : _ink,
                  backgroundColor: selected ? _teal : Colors.white,
                  side: BorderSide(
                    color: selected ? _teal : const Color(0xFFE3EAEA),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(
                  time,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: _teal, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Selected: ${_weekdays[selectedDate.weekday - 1]}, ${selectedDate.day} ${_months[selectedDate.month - 1]}${_selectedTime == null ? '' : ' · $_selectedTime'}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: FilledButton(
          onPressed: _selectedTime == null ? null : _continue,
          style: FilledButton.styleFrom(
            backgroundColor: _teal,
            disabledBackgroundColor: const Color(0xFFB7CECA),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Continue'),
        ),
      ),
    );
  }

  void _continue() {
    final date = _today.add(Duration(days: _selectedDay));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingAddressPage(
          service: widget.service,
          currentPlace: widget.currentPlace,
          date: date,
          time: _selectedTime!,
          onBookingConfirmed: widget.onBookingConfirmed,
        ),
      ),
    );
  }
}

class BookingAddressPage extends StatefulWidget {
  const BookingAddressPage({
    super.key,
    required this.service,
    required this.currentPlace,
    required this.date,
    required this.time,
    required this.onBookingConfirmed,
  });

  final CareService service;
  final CurrentPlace? currentPlace;
  final DateTime date;
  final String time;
  final ValueChanged<Booking> onBookingConfirmed;

  @override
  State<BookingAddressPage> createState() => _BookingAddressPageState();
}

class _BookingAddressPageState extends State<BookingAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinController = TextEditingController();
  final _landmarkController = TextEditingController();
  String _addressType = 'Home';
  String? _locationMessage;
  bool _isLocating = false;

  static const _addressTypes = ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    final place = widget.currentPlace;
    if (place != null) {
      _areaController.text = place.area;
      _cityController.text = place.city;
      _stateController.text = place.state;
      _pinController.text = place.postalCode;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Service address',
          style: TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
          ),
        ),
        centerTitle: true,
        backgroundColor: _canvas,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_outlined, color: _teal),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_weekdays[widget.date.weekday - 1]}, ${widget.date.day} ${_months[widget.date.month - 1]} · ${widget.time}',
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Where should we come?',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.currentPlace == null
                  ? 'Use your location to fill the area details, then enter your exact house or street address.'
                  : 'Your location details are filled in. Enter your exact house or street address below.',
              style: TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _isLocating ? null : _useCurrentLocation,
              icon: _isLocating
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                _isLocating
                    ? 'Finding your location…'
                    : 'Use my current location',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _teal,
                side: const BorderSide(color: _teal),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
            if (_locationMessage != null) ...[
              const SizedBox(height: 7),
              Text(
                _locationMessage!,
                style: TextStyle(
                  color: _locationMessage!.startsWith('Location found')
                      ? _teal
                      : const Color(0xFF9B6C1C),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Address type',
              style: TextStyle(fontWeight: FontWeight.w600, color: _ink),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 9,
              children: [
                for (final type in _addressTypes)
                  ChoiceChip(
                    label: Text(type),
                    selected: _addressType == type,
                    onSelected: (_) => setState(() => _addressType = type),
                    selectedColor: const Color(0xFFDDF4EE),
                    labelStyle: TextStyle(
                      color: _addressType == type ? _teal : _ink,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _addressType == type
                          ? _teal
                          : const Color(0xFFE3EAEA),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _addressController,
              minLines: 3,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: _addressDecoration(
                label: 'Address',
                hint: 'House / flat number and street',
                icon: Icons.location_on_outlined,
              ),
              validator: (value) => value == null || value.trim().length < 8
                  ? 'Enter a complete address'
                  : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _areaController,
              textCapitalization: TextCapitalization.words,
              decoration: _addressDecoration(
                label: 'Area',
                hint: 'Neighbourhood or locality',
                icon: Icons.map_outlined,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your area'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityController,
              textCapitalization: TextCapitalization.words,
              decoration: _addressDecoration(
                label: 'City',
                hint: 'City or town',
                icon: Icons.location_city_outlined,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your city'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _addressDecoration(
                      label: 'State',
                      hint: 'State',
                      icon: Icons.map_outlined,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your state'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: _addressDecoration(
                      label: 'PIN code',
                      hint: '6 digits',
                      icon: Icons.pin_drop_outlined,
                    ).copyWith(counterText: ''),
                    validator: (value) =>
                        value == null ||
                            !RegExp(r'^\d{6}$').hasMatch(value.trim())
                        ? 'Enter 6 digits'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _landmarkController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _addressDecoration(
                label: 'Landmark (optional)',
                hint: 'Nearby landmark',
                icon: Icons.near_me_outlined,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: FilledButton(
          onPressed: _continue,
          style: FilledButton.styleFrom(
            backgroundColor: _teal,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Save & continue'),
        ),
      ),
    );
  }

  InputDecoration _addressDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _muted, size: 20),
      alignLabelWithHint: true,
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
        borderSide: const BorderSide(color: _teal, width: 1.5),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLocating = true;
      _locationMessage = null;
    });
    try {
      final place = await locateCurrentPlace();
      if (!mounted) return;
      setState(() {
        _areaController.text = place.area;
        _cityController.text = place.city;
        _stateController.text = place.state;
        _pinController.text = place.postalCode;
        _locationMessage =
            'Location found. Enter your exact house or street address below.';
      });
    } on LocationLookupException catch (error) {
      if (!mounted) return;
      setState(() => _locationMessage = error.message);
      if (error.permanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            action: SnackBarAction(
              label: 'Open settings',
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _continue() {
    if (_formKey.currentState?.validate() != true) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingReviewPage(
          booking: Booking(
            id: 'PH${DateTime.now().millisecondsSinceEpoch}',
            service: widget.service,
            date: widget.date,
            time: widget.time,
            addressType: _addressType,
            address: _addressController.text.trim(),
            area: _areaController.text.trim(),
            city: _cityController.text.trim(),
            state: _stateController.text.trim(),
            pinCode: _pinController.text.trim(),
            landmark: _landmarkController.text.trim(),
          ),
          onBookingConfirmed: widget.onBookingConfirmed,
        ),
      ),
    );
  }
}

class BookingReviewPage extends StatelessWidget {
  const BookingReviewPage({
    super.key,
    required this.booking,
    required this.onBookingConfirmed,
  });

  final Booking booking;
  final ValueChanged<Booking> onBookingConfirmed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review booking'),
        centerTitle: true,
        backgroundColor: _canvas,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE4F5F0),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Row(
              children: [
                Icon(Icons.fact_check_outlined, size: 28, color: _teal),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Review your care request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Service',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.2,
              color: _ink,
            ),
          ),
          const SizedBox(height: 11),
          _ReviewCard(
            children: [
              Row(
                children: [
                  ServiceIcon(service: booking.service, size: 48),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.service.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.service.subtitle,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    booking.service.price,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              const Divider(height: 25),
              _ReviewRow(
                icon: Icons.calendar_month_outlined,
                label: 'Date & time',
                value:
                    '${_weekdays[booking.date.weekday - 1]}, ${booking.date.day} ${_months[booking.date.month - 1]} · ${booking.time}',
              ),
            ],
          ),
          const SizedBox(height: 21),
          const Text(
            'Service address',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: _ink,
            ),
          ),
          const SizedBox(height: 11),
          _ReviewCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _BookingAddressBlock(booking: booking),
              ),
              if (booking.landmark.isNotEmpty) ...[
                const Divider(height: 25),
                _ReviewRow(
                  icon: Icons.near_me_outlined,
                  label: 'Landmark',
                  value: booking.landmark,
                ),
              ],
            ],
          ),
          const SizedBox(height: 21),
          _ReviewCard(
            children: [
              const Text(
                'Payment summary',
                style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
              ),
              const SizedBox(height: 13),
              _ReviewRow(
                icon: Icons.medical_services_outlined,
                label: 'Service fee',
                value: booking.service.price,
              ),
              const Divider(height: 22),
              _ReviewRow(
                icon: Icons.receipt_long_outlined,
                label: 'Total payable',
                value: booking.service.price,
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Your appointment is not confirmed until payment is completed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PaymentPage(
                booking: booking,
                onBookingConfirmed: onBookingConfirmed,
              ),
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _teal,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Proceed to payment'),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.bold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: _teal, size: 19),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: bold ? _ink : _muted,
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: _ink,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class PaymentPage extends StatelessWidget {
  const PaymentPage({
    super.key,
    required this.booking,
    required this.onBookingConfirmed,
  });

  final Booking booking;
  final ValueChanged<Booking> onBookingConfirmed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
        backgroundColor: _canvas,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Total amount', style: TextStyle(color: _muted)),
                ),
                Text(
                  booking.service.price,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pay with UPI',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _teal, width: 1.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.qr_code_rounded, color: _teal, size: 27),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPI',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Use your preferred UPI app',
                        style: TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.radio_button_checked, color: _teal),
              ],
            ),
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF9B6C1C),
                  size: 19,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'UPI is shown in demo mode. No payment will be requested or charged.',
                    style: TextStyle(
                      color: Color(0xFF795821),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BookingConfirmationPage(
                booking: booking,
                onBookingConfirmed: onBookingConfirmed,
              ),
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _teal,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Continue with UPI'),
        ),
      ),
    );
  }
}

class BookingConfirmationPage extends StatelessWidget {
  const BookingConfirmationPage({
    super.key,
    required this.booking,
    required this.onBookingConfirmed,
  });

  final Booking booking;
  final ValueChanged<Booking> onBookingConfirmed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 50, 24, 28),
          children: [
            Center(
              child: Container(
                width: 86,
                height: 86,
                decoration: const BoxDecoration(
                  color: Color(0xFFDDF4EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: _teal, size: 48),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your booking is confirmed!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This is a local demo confirmation. UPI payment has not been processed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, height: 1.45, fontSize: 13),
            ),
            const SizedBox(height: 28),
            _ReviewCard(
              children: [
                _ReviewRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Booking ID',
                  value: booking.id,
                ),
                const Divider(height: 24),
                _ReviewRow(
                  icon: Icons.medical_services_outlined,
                  label: 'Service',
                  value: booking.service.name,
                ),
                const Divider(height: 24),
                _ReviewRow(
                  icon: Icons.event_outlined,
                  label: 'Date & time',
                  value:
                      '${_weekdays[booking.date.weekday - 1]}, ${booking.date.day} ${_months[booking.date.month - 1]} · ${booking.time}',
                ),
                const Divider(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _BookingAddressBlock(booking: booking),
                ),
              ],
            ),
            const SizedBox(height: 19),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Connect a UPI payment provider and booking backend before using this flow for real appointments.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF795821),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            onBookingConfirmed(booking);
          },
          style: FilledButton.styleFrom(
            backgroundColor: _teal,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('View my bookings'),
        ),
      ),
    );
  }
}

class BookingsPage extends StatelessWidget {
  const BookingsPage({
    super.key,
    required this.bookings,
    required this.onBookingCancelled,
  });

  final List<Booking> bookings;
  final ValueChanged<String> onBookingCancelled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: bookings.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F5F0),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        size: 38,
                        color: _teal,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No bookings yet',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your appointments will appear here once you complete the demo booking flow.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, height: 1.5),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const Text(
                  'My bookings',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your local demo appointments',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
                const SizedBox(height: 18),
                for (final booking in bookings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BookingCard(
                      booking: booking,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BookingDetailsPage(
                            booking: booking,
                            onBookingCancelled: onBookingCancelled,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7ECEC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ServiceIcon(service: booking.service, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.service.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Booking ID: ${booking.id}',
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Demo',
                    style: TextStyle(
                      color: _teal,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 23),
            _ReviewRow(
              icon: Icons.event_outlined,
              label: 'Date & time',
              value:
                  '${_weekdays[booking.date.weekday - 1]}, ${booking.date.day} ${_months[booking.date.month - 1]} · ${booking.time}',
            ),
            const SizedBox(height: 13),
            _BookingAddressBlock(booking: booking),
          ],
        ),
      ),
    ),
  );
}

class BookingDetailsPage extends StatelessWidget {
  const BookingDetailsPage({
    super.key,
    required this.booking,
    required this.onBookingCancelled,
  });

  final Booking booking;
  final ValueChanged<String> onBookingCancelled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking details'),
        centerTitle: true,
        backgroundColor: _canvas,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Column(
              children: [
                ServiceIcon(service: booking.service, size: 62),
                const SizedBox(height: 12),
                Text(
                  booking.service.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Demo booking · ${booking.id}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ReviewCard(
            children: [
              _ReviewRow(
                icon: Icons.event_outlined,
                label: 'Date & time',
                value:
                    '${_weekdays[booking.date.weekday - 1]}, ${booking.date.day} ${_months[booking.date.month - 1]} · ${booking.time}',
              ),
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _BookingAddressBlock(booking: booking),
              ),
              if (booking.landmark.isNotEmpty) ...[
                const Divider(height: 24),
                _ReviewRow(
                  icon: Icons.near_me_outlined,
                  label: 'Landmark',
                  value: booking.landmark,
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          _ReviewCard(
            children: [
              const Text(
                'Care professional',
                style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
              ),
              const SizedBox(height: 8),
              const Text(
                'A verified professional will be assigned when real booking services are connected.',
                style: TextStyle(color: _muted, height: 1.45, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: OutlinedButton(
          onPressed: () => _confirmCancel(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC4484B),
            side: const BorderSide(color: Color(0xFFE8B9BB)),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: const Text('Cancel demo booking'),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: const Text(
          'This will remove the demo booking from My Bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC4484B),
            ),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );

    if (shouldCancel != true || !context.mounted) return;
    onBookingCancelled(booking.id);
    Navigator.of(context).pop();
  }
}

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
              color: _ink,
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
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          _ProfileMenuTile(
            icon: Icons.calendar_month_outlined,
            title: 'My bookings',
            subtitle:
                '${bookings.length} demo booking${bookings.length == 1 ? '' : 's'}',
            onTap: onOpenBookings,
          ),
          _ProfileMenuTile(
            icon: Icons.folder_open_outlined,
            title: 'My documents',
            subtitle: 'Reports and care documents',
            onTap: () => _openSection(
              context,
              'My documents',
              Icons.folder_open_outlined,
            ),
          ),
          _ProfileMenuTile(
            icon: Icons.favorite_border_rounded,
            title: 'Medical history',
            subtitle: 'Health information and notes',
            onTap: () => _openSection(
              context,
              'Medical history',
              Icons.favorite_border_rounded,
            ),
          ),
          _ProfileMenuTile(
            icon: Icons.people_outline_rounded,
            title: 'Family members',
            subtitle: 'Manage care for your family',
            onTap: () => _openSection(
              context,
              'Family members',
              Icons.people_outline_rounded,
            ),
          ),
          _ProfileMenuTile(
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
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          _ProfileMenuTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Payment methods',
            subtitle: 'UPI',
            onTap: () => _openSection(
              context,
              'Payment methods',
              Icons.account_balance_wallet_outlined,
            ),
          ),
          _ProfileMenuTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Notifications, permissions and app info',
            onTap: onOpenSettings,
          ),
          _ProfileMenuTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & support',
            subtitle: 'Get help with care services',
            onTap: () => _openSection(
              context,
              'Help & support',
              Icons.help_outline_rounded,
            ),
          ),
          _ProfileMenuTile(
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
              style: TextStyle(color: _muted, fontSize: 11),
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
      backgroundColor: _canvas,
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
                Icon(Icons.info_outline_rounded, color: _teal),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No OTP or authentication is used. Your name and phone are saved on this device and are not sent to a server.',
                    style: TextStyle(color: _ink, height: 1.4, fontSize: 13),
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
          backgroundColor: _teal,
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
    prefixIcon: Icon(icon, color: _muted, size: 20),
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
      borderSide: const BorderSide(color: _teal, width: 1.5),
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

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
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
          color: isDestructive ? const Color(0xFFC4484B) : _teal,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? const Color(0xFFC4484B) : _ink,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: _muted, fontSize: 11),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
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
        backgroundColor: _canvas,
      ),
      body: addresses.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Addresses from your demo bookings will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, height: 1.5),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final booking in addresses.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReviewCard(
                      children: [
                        _ReviewRow(
                          icon: Icons.location_on_outlined,
                          label: booking.addressType,
                          value:
                              '${booking.address}, ${booking.localitySummary}',
                        ),
                        if (booking.landmark.isNotEmpty) ...[
                          const Divider(height: 22),
                          _ReviewRow(
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

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.bookingBadgeEnabled,
    required this.onBookingBadgeChanged,
    required this.onClearGuestData,
  });

  final bool bookingBadgeEnabled;
  final ValueChanged<bool> onBookingBadgeChanged;
  final VoidCallback onClearGuestData;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  late bool _bookingBadgeEnabled;
  LocationPermission? _locationPermission;
  bool? _locationServiceEnabled;
  bool _checkingLocation = true;

  @override
  void initState() {
    super.initState();
    _bookingBadgeEnabled = widget.bookingBadgeEnabled;
    WidgetsBinding.instance.addObserver(this);
    _refreshLocationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshLocationStatus();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Settings'),
      centerTitle: true,
      backgroundColor: _canvas,
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const _SettingsHeading('Notifications'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SwitchListTile(
            value: _bookingBadgeEnabled,
            onChanged: (enabled) {
              setState(() => _bookingBadgeEnabled = enabled);
              widget.onBookingBadgeChanged(enabled);
            },
            secondary: const Icon(
              Icons.notifications_active_outlined,
              color: _teal,
            ),
            title: const Text(
              'Booking badge',
              style: TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Show a red dot when a booking update is new',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
            activeTrackColor: _teal,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8, left: 4),
          child: Text(
            'Push notifications are not connected yet. The booking badge works inside the app.',
            style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
          ),
        ),
        const SizedBox(height: 22),
        const _SettingsHeading('Accessibility'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ValueListenableBuilder<AccessibilityPreferences>(
            valueListenable: _accessibilityPreferences,
            builder: (context, preferences, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Text size',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<double>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('Default')),
                    ButtonSegment(value: 1.15, label: Text('Large')),
                    ButtonSegment(value: 1.3, label: Text('Larger')),
                  ],
                  selected: {preferences.textScale},
                  onSelectionChanged: (selection) {
                    _setAccessibilityPreferences(
                      AccessibilityPreferences(
                        textScale: selection.first,
                        reduceMotion: preferences.reduceMotion,
                      ),
                    );
                  },
                  showSelectedIcon: false,
                ),
                const Divider(height: 25),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: preferences.reduceMotion,
                  onChanged: (enabled) {
                    _setAccessibilityPreferences(
                      AccessibilityPreferences(
                        textScale: preferences.textScale,
                        reduceMotion: enabled,
                      ),
                    );
                  },
                  title: const Text(
                    'Reduce motion',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Limit app animations',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  activeTrackColor: _teal,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const _SettingsHeading('Permissions'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const Icon(Icons.location_on_outlined, color: _teal),
            title: const Text(
              'Location access',
              style: TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Manage location permission for this app',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
            trailing: const Icon(Icons.open_in_new_rounded, color: _muted),
            onTap: _openLocationSettings,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            _locationStatusText,
            style: const TextStyle(color: _muted, fontSize: 11, height: 1.4),
          ),
        ),
        const SizedBox(height: 22),
        const _SettingsHeading('Privacy'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, color: _teal),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your name and phone are saved on this device for your profile. No OTP, authentication, or server upload is used. Demo bookings stay in memory until the app is closed.',
                  style: TextStyle(color: _muted, height: 1.45, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: widget.onClearGuestData,
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Log out and clear profile'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFC4484B),
            side: const BorderSide(color: Color(0xFFEBC6C7)),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
        const SizedBox(height: 22),
        const _SettingsHeading('About'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const ListTile(
            leading: Icon(Icons.health_and_safety_outlined, color: _teal),
            title: Text(
              'Deep Care',
              style: TextStyle(
                color: _ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Version 1.0.0',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _openLocationSettings() async {
    final opened = await Geolocator.openAppSettings();
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open device app settings.')),
      );
      return;
    }
  }

  String get _locationStatusText {
    if (_checkingLocation) return 'Checking device location status…';
    if (_locationPermission == null || _locationServiceEnabled == null) {
      return 'Could not read location status. Check device settings.';
    }
    final permission = switch (_locationPermission!) {
      LocationPermission.always => 'Allowed all the time',
      LocationPermission.whileInUse => 'Allowed while using the app',
      LocationPermission.denied => 'Permission not granted',
      LocationPermission.deniedForever => 'Permission blocked',
      LocationPermission.unableToDetermine => 'Permission unavailable',
    };
    final service = _locationServiceEnabled! ? 'on' : 'off';
    return '$permission · Location services $service';
  }

  Future<void> _refreshLocationStatus() async {
    try {
      final permission = await Geolocator.checkPermission();
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      setState(() {
        _locationPermission = permission;
        _locationServiceEnabled = serviceEnabled;
        _checkingLocation = false;
      });
    } catch (_) {
      if (mounted) setState(() => _checkingLocation = false);
    }
  }
}

class _SettingsHeading extends StatelessWidget {
  const _SettingsHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(
      title,
      style: const TextStyle(
        color: _ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class ProfileSectionPage extends StatelessWidget {
  const ProfileSectionPage({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), backgroundColor: _canvas),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5F0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 38, color: _teal),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This section will be available after account and service setup.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}

class ServiceSearchPage extends StatefulWidget {
  const ServiceSearchPage({super.key, required this.onServiceTap});
  final ValueChanged<CareService> onServiceTap;
  @override
  State<ServiceSearchPage> createState() => _ServiceSearchPageState();
}

class _ServiceSearchPageState extends State<ServiceSearchPage> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final matches = _services
        .where(
          (service) => '${service.name} ${service.subtitle}'
              .toLowerCase()
              .contains(_query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search services',
          style: TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
          ),
        ),
        backgroundColor: _canvas,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search care services',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: matches.isEmpty
                ? const Center(
                    child: Text(
                      'No services found',
                      style: TextStyle(color: _muted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: matches.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final service = matches[index];
                      return Card(
                        color: Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: service.color.withValues(
                              alpha: .13,
                            ),
                            child: Icon(service.icon, color: service.color),
                          ),
                          title: Text(
                            service.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(service.subtitle),
                          trailing: Text(
                            service.price,
                            style: const TextStyle(
                              color: _teal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () => widget.onServiceTap(service),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
    required this.bookings,
    required this.onBookingCancelled,
  });
  final List<Booking> bookings;
  final ValueChanged<String> onBookingCancelled;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      backgroundColor: _canvas,
    ),
    body: bookings.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 48,
                    color: _teal,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'You’re all caught up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Booking updates will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted),
                  ),
                ],
              ),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                color: Colors.white,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDDF4EE),
                    child: Icon(Icons.event_available_outlined, color: _teal),
                  ),
                  title: Text(
                    '${booking.service.name} booking confirmed',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${booking.date.day} ${_months[booking.date.month - 1]} · ${booking.time}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BookingDetailsPage(
                        booking: booking,
                        onBookingCancelled: onBookingCancelled,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onServiceTap,
    required this.onBrowseServices,
    required this.bookings,
    required this.onBookingTap,
    required this.currentPlace,
    required this.isLocating,
    required this.onLocationTap,
    required this.onSearchTap,
    required this.onNotificationsTap,
    required this.hasUnreadNotifications,
  });
  final ValueChanged<CareService> onServiceTap;
  final VoidCallback onBrowseServices;
  final List<Booking> bookings;
  final ValueChanged<Booking> onBookingTap;
  final CurrentPlace? currentPlace;
  final bool isLocating;
  final VoidCallback onLocationTap;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationsTap;
  final bool hasUnreadNotifications;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcomingVisits =
        bookings.where((booking) => booking.scheduledAt.isAfter(now)).toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final nextVisit = upcomingVisits.isEmpty ? null : upcomingVisits.first;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _HomeHeader(
                  currentPlace: currentPlace,
                  isLocating: isLocating,
                  onLocationTap: onLocationTap,
                  onSearchTap: onSearchTap,
                  onNotificationsTap: onNotificationsTap,
                  hasUnreadNotifications: hasUnreadNotifications,
                ),
                const SizedBox(height: 22),
                _CareBanner(onExplore: onBrowseServices),
                const SizedBox(height: 27),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Our services',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    TextButton(
                      onPressed: onBrowseServices,
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  itemCount: _services.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 17,
                    crossAxisSpacing: 10,
                    childAspectRatio: .79,
                  ),
                  itemBuilder: (context, index) => _ServiceTile(
                    service: _services[index],
                    onTap: () => onServiceTap(_services[index]),
                  ),
                ),
                const SizedBox(height: 24),
                _AppointmentCard(
                  nextVisit: nextVisit,
                  onVisitTap: nextVisit == null
                      ? onBrowseServices
                      : () => onBookingTap(nextVisit),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.currentPlace,
    required this.isLocating,
    required this.onLocationTap,
    required this.onSearchTap,
    required this.onNotificationsTap,
    required this.hasUnreadNotifications,
  });
  final CurrentPlace? currentPlace;
  final bool isLocating;
  final VoidCallback onLocationTap, onSearchTap, onNotificationsTap;
  final bool hasUnreadNotifications;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFE1F5F0),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Image.asset(
          'assets/images/paramedical_health_mark.png',
          fit: BoxFit.contain,
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: InkWell(
          onTap: isLocating ? null : onLocationTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR LOCATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (isLocating)
                      const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: _teal,
                        ),
                      )
                    else
                      const Icon(
                        Icons.location_on_rounded,
                        size: 15,
                        color: _teal,
                      ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        isLocating
                            ? 'Finding location…'
                            : (currentPlace?.displayName ??
                                  'Tap to set location'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      _HeaderButton(
        icon: Icons.search_rounded,
        label: 'Search',
        onTap: onSearchTap,
      ),
      const SizedBox(width: 8),
      _HeaderButton(
        icon: Icons.notifications_none_rounded,
        label: 'Notifications',
        badge: hasUnreadNotifications,
        onTap: onNotificationsTap,
      ),
    ],
  );
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = false,
  });
  final IconData icon;
  final String label;
  final bool badge;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: true,
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: _ink, size: 22),
              if (badge)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF8177),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CareBanner extends StatelessWidget {
  const _CareBanner({required this.onExplore});
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF123F50), Color(0xFF087F70)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -4,
          top: -10,
          child: Icon(
            Icons.health_and_safety_outlined,
            size: 124,
            color: Colors.white.withValues(alpha: .10),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'CARE THAT COMES TO YOU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Better care,\nright at home.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Book trusted healthcare professionals\nfor you and your family.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .83),
                height: 1.4,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onExplore,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _teal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                minimumSize: Size.zero,
              ),
              child: const Text(
                'Explore services',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class ServiceListPage extends StatelessWidget {
  const ServiceListPage({super.key, required this.onServiceTap});
  final ValueChanged<CareService> onServiceTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _canvas,
        title: const Text(
          'Select a service',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F4F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.favorite_rounded, color: _teal, size: 26),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Professional care,\nright at your doorstep.',
                    style: TextStyle(
                      color: _ink,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'What care do you need?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          for (final service in _services)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                child: InkWell(
                  borderRadius: BorderRadius.circular(17),
                  onTap: () => onServiceTap(service),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        ServiceIcon(service: service, size: 48),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                service.subtitle,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: _muted,
                            ),
                            Text(
                              'From ${service.price}',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.onTap});
  final CareService service;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(17),
    onTap: onTap,
    child: Column(
      children: [
        ServiceIcon(service: service, size: 52),
        const SizedBox(height: 8),
        Text(
          service.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.5,
            height: 1.15,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
      ],
    ),
  );
}

class ServiceIcon extends StatelessWidget {
  const ServiceIcon({super.key, required this.service, required this.size});
  final CareService service;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: service.color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(size * .30),
    ),
    child: Icon(service.icon, color: service.color, size: size * .52),
  );
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.nextVisit, required this.onVisitTap});

  final Booking? nextVisit;
  final VoidCallback onVisitTap;

  @override
  Widget build(BuildContext context) {
    final booking = nextVisit;
    final dateLabel = booking == null
        ? ''
        : '${_weekdays[booking.date.weekday - 1]}, ${booking.date.day} ${_months[booking.date.month - 1]} · ${booking.time}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onVisitTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8EEEE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.event_available_outlined,
                    color: _teal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Your next visit',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: _ink,
                      ),
                    ),
                  ),
                  Icon(
                    booking == null
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.chevron_right_rounded,
                    size: 16,
                    color: _muted,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (booking == null)
                const Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFE3F5F0),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        child: Icon(Icons.event_note_rounded, color: _teal),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No upcoming visits',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap to explore and book a care service',
                            style: TextStyle(fontSize: 11, color: _muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: booking.service.color.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        booking.service.icon,
                        color: booking.service.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.service.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateLabel,
                            style: const TextStyle(fontSize: 11, color: _muted),
                          ),
                          if (booking.localitySummary.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              booking.localitySummary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _muted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SimplePage extends StatelessWidget {
  const SimplePage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5F0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 38, color: _teal),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}
