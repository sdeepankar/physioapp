import 'package:flutter/material.dart';

import '../core/appwrite_config.dart';
import '../core/app_theme.dart';
import '../core/app_settings.dart';
import '../services/appwrite_service.dart';

import 'package:geolocator/geolocator.dart';

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
  bool _checkingAppwrite = false;
  String? _appwriteStatus;
  bool _appwriteConnected = false;

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
      backgroundColor: appCanvas,
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const SettingsHeading('Notifications'),
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
              color: appTeal,
            ),
            title: const Text(
              'Booking badge',
              style: TextStyle(
                color: appInk,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Show a red dot when a booking update is new',
              style: TextStyle(color: appMuted, fontSize: 12),
            ),
            activeTrackColor: appTeal,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8, left: 4),
          child: Text(
            'Push notifications are not connected yet. The booking badge works inside the app.',
            style: TextStyle(color: appMuted, fontSize: 11, height: 1.4),
          ),
        ),
        const SizedBox(height: 22),
        const SettingsHeading('Accessibility'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ValueListenableBuilder<AccessibilityPreferences>(
            valueListenable: accessibilityPreferences,
            builder: (context, preferences, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Text size',
                  style: TextStyle(
                    color: appInk,
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
                    setAccessibilityPreferences(
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
                    setAccessibilityPreferences(
                      AccessibilityPreferences(
                        textScale: preferences.textScale,
                        reduceMotion: enabled,
                      ),
                    );
                  },
                  title: const Text(
                    'Reduce motion',
                    style: TextStyle(
                      color: appInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Limit app animations',
                    style: TextStyle(color: appMuted, fontSize: 12),
                  ),
                  activeTrackColor: appTeal,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const SettingsHeading('Permissions'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: const Icon(Icons.location_on_outlined, color: appTeal),
            title: const Text(
              'Location access',
              style: TextStyle(
                color: appInk,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Manage location permission for this app',
              style: TextStyle(color: appMuted, fontSize: 12),
            ),
            trailing: const Icon(Icons.open_in_new_rounded, color: appMuted),
            onTap: _openLocationSettings,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            _locationStatusText,
            style: const TextStyle(color: appMuted, fontSize: 11, height: 1.4),
          ),
        ),
        const SizedBox(height: 22),
        const SettingsHeading('Privacy'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline_rounded, color: appTeal),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your name, phone number, services, and bookings sync with your Deep Care account. Medical history and saved addresses remain on this device.',
                  style: TextStyle(color: appMuted, height: 1.45, fontSize: 13),
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
        const SettingsHeading('Backend connection'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Appwrite',
                style: TextStyle(
                  color: appInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Check that Deep Care can reach $appwriteProjectName.',
                style: TextStyle(color: appMuted, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _checkingAppwrite ? null : _checkAppwrite,
                  icon: _checkingAppwrite
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_sync_outlined),
                  label: Text(
                    _checkingAppwrite
                        ? 'Checking connection…'
                        : 'Check Appwrite connection',
                  ),
                ),
              ),
              if (_appwriteStatus != null) ...[
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _appwriteConnected
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 18,
                        color: _appwriteConnected
                            ? appTeal
                            : const Color(0xFFC4484B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _appwriteStatus!,
                          style: TextStyle(
                            color: _appwriteConnected
                                ? appTeal
                                : const Color(0xFFC4484B),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SettingsHeading('About'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const ListTile(
            leading: Icon(Icons.health_and_safety_outlined, color: appTeal),
            title: Text(
              'Deep Care',
              style: TextStyle(
                color: appInk,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Version 1.0.0',
              style: TextStyle(color: appMuted, fontSize: 12),
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

  Future<void> _checkAppwrite() async {
    setState(() {
      _checkingAppwrite = true;
      _appwriteStatus = null;
    });

    try {
      final response = await AppwriteService.instance.ping();
      if (!mounted) return;
      setState(() {
        _appwriteConnected = true;
        _appwriteStatus = response.isEmpty
            ? 'Connected to Appwrite.'
            : 'Connected to Appwrite: $response';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _appwriteConnected = false;
        _appwriteStatus = 'Could not connect. Check your internet connection and Appwrite project settings.';
      });
    } finally {
      if (mounted) setState(() => _checkingAppwrite = false);
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

class SettingsHeading extends StatelessWidget {
  const SettingsHeading(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
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
    appBar: AppBar(title: Text(title), backgroundColor: appCanvas),
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
              child: Icon(icon, size: 38, color: appTeal),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: appInk,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This section will be available after account and service setup.',
              textAlign: TextAlign.center,
              style: TextStyle(color: appMuted, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}
