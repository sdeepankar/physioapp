import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_theme.dart';
import '../models/saved_address.dart';
import '../models/booking.dart';
import '../models/care_service.dart';
import '../widgets/client_widgets.dart';
import '../core/app_settings.dart';
import '../services/location_service.dart';

class ServiceDetailsPage extends StatelessWidget {
  const ServiceDetailsPage({
    super.key,
    required this.service,
    required this.currentPlace,
    required this.onBookingConfirmed,
  });

  final CareService service;
  final CurrentPlace? currentPlace;
  final Future<Booking> Function(Booking) onBookingConfirmed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service details'),
        centerTitle: true,
        backgroundColor: appCanvas,
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
              color: appInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(service.subtitle, style: const TextStyle(color: appMuted)),
          const SizedBox(height: 19),
          const Text(
            'About this service',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: appInk,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get professional, one-to-one care in the comfort of your home. We connect you with verified healthcare professionals and make it easy to find a time that works for you.',
            style: TextStyle(color: appMuted, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              ServiceFeature(icon: Icons.schedule_rounded, label: '45–60 min'),
              const SizedBox(width: 10),
              ServiceFeature(
                icon: Icons.verified_user_outlined,
                label: 'Verified expert',
              ),
              const SizedBox(width: 10),
              ServiceFeature(icon: Icons.home_outlined, label: 'At your home'),
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
                    style: TextStyle(color: appMuted),
                  ),
                ),
                Text(
                  '${service.price} / session',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: appInk,
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
            backgroundColor: appTeal,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Book now'),
        ),
      ),
    );
  }
}

class ServiceFeature extends StatelessWidget {
  const ServiceFeature({super.key, required this.icon, required this.label});

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
          Icon(icon, color: appTeal, size: 19),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: appMuted),
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
  final Future<Booking> Function(Booking) onBookingConfirmed;

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
        backgroundColor: appCanvas,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            widget.service.name,
            style: const TextStyle(color: appMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: appTeal,
                size: 20,
              ),
              const SizedBox(width: 9),
              Text(
                '${months[selectedDate.month - 1]} ${selectedDate.year}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: appInk,
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
                    duration: accessibilityPreferences.value.reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 150),
                    width: 53,
                    decoration: BoxDecoration(
                      color: selected ? appTeal : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: selected ? appTeal : const Color(0xFFE7ECEC),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          weekdays[date.weekday - 1],
                          style: TextStyle(
                            color: selected
                                ? Colors.white.withValues(alpha: .8)
                                : appMuted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: selected ? Colors.white : appInk,
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
              color: appInk,
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
                  foregroundColor: selected ? Colors.white : appInk,
                  backgroundColor: selected ? appTeal : Colors.white,
                  side: BorderSide(
                    color: selected ? appTeal : const Color(0xFFE3EAEA),
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
                const Icon(
                  Icons.info_outline_rounded,
                  color: appTeal,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Selected: ${weekdays[selectedDate.weekday - 1]}, ${selectedDate.day} ${months[selectedDate.month - 1]}${_selectedTime == null ? '' : ' · $_selectedTime'}',
                    style: const TextStyle(color: appMuted, fontSize: 12),
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
            backgroundColor: appTeal,
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
  final Future<Booking> Function(Booking) onBookingConfirmed;

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
  List<SavedAddress> _savedAddresses = [];
  String? _selectedSavedAddressId;
  String? _locationMessage;
  bool _isLocating = false;
  bool _loadingSavedAddresses = true;

  static const _addressTypes = ['Home', 'Work', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
    final place = widget.currentPlace;
    if (place != null) {
      _areaController.text = place.area;
      _cityController.text = place.city;
      _stateController.text = place.state;
      _pinController.text = place.postalCode;
    }
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(savedAddressesKey);
      final addresses = encoded == null
          ? <SavedAddress>[]
          : (jsonDecode(encoded) as List<dynamic>)
                .map(
                  (item) => SavedAddress.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList();
      if (!mounted) return;
      setState(() {
        _savedAddresses = addresses;
        _loadingSavedAddresses = false;
      });
    } catch (error) {
      debugPrint('Could not load saved addresses for booking: $error');
      if (!mounted) return;
      setState(() => _loadingSavedAddresses = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load your saved addresses.')),
      );
    }
  }

  void _applySavedAddress(String? addressId) {
    if (addressId == null) return;
    final address = _savedAddresses.firstWhere(
      (savedAddress) => savedAddress.id == addressId,
    );
    setState(() {
      _selectedSavedAddressId = address.id;
      _addressType = _addressTypes.contains(address.addressType)
          ? address.addressType
          : 'Other';
      _addressController.text = address.address;
      _areaController.text = address.area;
      _cityController.text = address.city;
      _stateController.text = address.state;
      _pinController.text = address.pinCode;
      _landmarkController.text = address.landmark;
    });
  }

  void _clearSavedAddressSelection() {
    if (_selectedSavedAddressId != null) {
      setState(() => _selectedSavedAddressId = null);
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
            color: appInk,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
          ),
        ),
        centerTitle: true,
        backgroundColor: appCanvas,
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
                  const Icon(Icons.event_available_outlined, color: appTeal),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: appInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${weekdays[widget.date.weekday - 1]}, ${widget.date.day} ${months[widget.date.month - 1]} · ${widget.time}',
                          style: const TextStyle(color: appMuted, fontSize: 12),
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
                color: appInk,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.currentPlace == null
                  ? 'Use your location to fill the area details, then enter your exact house or street address.'
                  : 'Your location details are filled in. Enter your exact house or street address below.',
              style: TextStyle(color: appMuted, fontSize: 13),
            ),
            if (_savedAddresses.isNotEmpty) ...[
              const SizedBox(height: 17),
              DropdownButtonFormField<String>(
                initialValue: _selectedSavedAddressId,
                isExpanded: true,
                decoration: _addressDecoration(
                  label: 'Use a saved address',
                  hint: 'Choose an address from your address book',
                  icon: Icons.bookmark_outline_rounded,
                ),
                items: [
                  for (final address in _savedAddresses)
                    DropdownMenuItem<String>(
                      value: address.id,
                      child: Text(
                        '${address.label} · ${address.address}, ${address.localitySummary}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _applySavedAddress,
              ),
            ] else if (_loadingSavedAddresses) ...[
              const SizedBox(height: 17),
              const LinearProgressIndicator(color: appTeal),
            ],
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
                foregroundColor: appTeal,
                side: const BorderSide(color: appTeal),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
            if (_locationMessage != null) ...[
              const SizedBox(height: 7),
              Text(
                _locationMessage!,
                style: TextStyle(
                  color: _locationMessage!.startsWith('Location found')
                      ? appTeal
                      : const Color(0xFF9B6C1C),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Address type',
              style: TextStyle(fontWeight: FontWeight.w600, color: appInk),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 9,
              children: [
                for (final type in _addressTypes)
                  ChoiceChip(
                    label: Text(type),
                    selected: _addressType == type,
                    onSelected: (_) => setState(() {
                      _addressType = type;
                      _selectedSavedAddressId = null;
                    }),
                    selectedColor: const Color(0xFFDDF4EE),
                    labelStyle: TextStyle(
                      color: _addressType == type ? appTeal : appInk,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _addressType == type
                          ? appTeal
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
              onChanged: (_) => _clearSavedAddressSelection(),
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
              onChanged: (_) => _clearSavedAddressSelection(),
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
              onChanged: (_) => _clearSavedAddressSelection(),
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
                    onChanged: (_) => _clearSavedAddressSelection(),
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
                    onChanged: (_) => _clearSavedAddressSelection(),
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
              onChanged: (_) => _clearSavedAddressSelection(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: FilledButton(
          onPressed: _continue,
          style: FilledButton.styleFrom(
            backgroundColor: appTeal,
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
      prefixIcon: Icon(icon, color: appMuted, size: 20),
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
        borderSide: const BorderSide(color: appTeal, width: 1.5),
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
            id: '',
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
            clientRequestId: Booking.createClientRequestId(),
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
  final Future<Booking> Function(Booking) onBookingConfirmed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review booking'),
        centerTitle: true,
        backgroundColor: appCanvas,
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
                Icon(Icons.fact_check_outlined, size: 28, color: appTeal),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Review your care request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: appInk,
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
              color: appInk,
            ),
          ),
          const SizedBox(height: 11),
          ReviewCard(
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
                            color: appInk,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.service.subtitle,
                          style: const TextStyle(color: appMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    booking.service.price,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: appInk,
                    ),
                  ),
                ],
              ),
              const Divider(height: 25),
              ReviewRow(
                icon: Icons.calendar_month_outlined,
                label: 'Date & time',
                value:
                    '${weekdays[booking.date.weekday - 1]}, ${booking.date.day} ${months[booking.date.month - 1]} · ${booking.time}',
              ),
            ],
          ),
          const SizedBox(height: 21),
          const Text(
            'Service address',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: appInk,
            ),
          ),
          const SizedBox(height: 11),
          ReviewCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: BookingAddressBlock(booking: booking),
              ),
              if (booking.landmark.isNotEmpty) ...[
                const Divider(height: 25),
                ReviewRow(
                  icon: Icons.near_me_outlined,
                  label: 'Landmark',
                  value: booking.landmark,
                ),
              ],
            ],
          ),
          const SizedBox(height: 21),
          ReviewCard(
            children: [
              const Text(
                'Payment summary',
                style: TextStyle(fontWeight: FontWeight.w700, color: appInk),
              ),
              const SizedBox(height: 13),
              ReviewRow(
                icon: Icons.medical_services_outlined,
                label: 'Service fee',
                value: booking.service.price,
              ),
              const Divider(height: 22),
              ReviewRow(
                icon: Icons.receipt_long_outlined,
                label: 'Total payable',
                value: booking.service.price,
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Submitting this request does not charge your payment method. Payment stays pending until a real payment provider is connected.',
            textAlign: TextAlign.center,
            style: TextStyle(color: appMuted, fontSize: 12),
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
            backgroundColor: appTeal,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Proceed to payment'),
        ),
      ),
    );
  }
}

class PaymentPage extends StatelessWidget {
  const PaymentPage({
    super.key,
    required this.booking,
    required this.onBookingConfirmed,
  });

  final Booking booking;
  final Future<Booking> Function(Booking) onBookingConfirmed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        centerTitle: true,
        backgroundColor: appCanvas,
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
                  child: Text(
                    'Total amount',
                    style: TextStyle(color: appMuted),
                  ),
                ),
                Text(
                  booking.service.price,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: appInk,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Payment method preview',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: appInk,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: appTeal, width: 1.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.qr_code_rounded, color: appTeal, size: 27),
                SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPI',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: appInk,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Use your preferred UPI app',
                        style: TextStyle(fontSize: 12, color: appMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.radio_button_checked, color: appTeal),
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
            backgroundColor: appTeal,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Continue to submit request'),
        ),
      ),
    );
  }
}

class BookingConfirmationPage extends StatefulWidget {
  const BookingConfirmationPage({
    super.key,
    required this.booking,
    required this.onBookingConfirmed,
  });

  final Booking booking;
  final Future<Booking> Function(Booking) onBookingConfirmed;

  @override
  State<BookingConfirmationPage> createState() =>
      _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  bool _isSaving = false;
  String? _error;
  Booking? _savedBooking;

  Future<void> _submitBooking() async {
    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final saved = await widget.onBookingConfirmed(widget.booking);
      if (!mounted) return;
      setState(() {
        _savedBooking = saved;
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is FormatException
            ? error.message
            : 'Could not submit your request. Please try again.';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _savedBooking ?? widget.booking;
    final isSaved = _savedBooking != null;
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
                child: Icon(
                  isSaved
                      ? Icons.check_rounded
                      : Icons.medical_services_outlined,
                  color: appTeal,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSaved ? 'Care request submitted' : 'Submit your care request',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: appInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSaved
                  ? 'Your request is saved. Payment remains pending; no UPI payment has been processed.'
                  : 'This will send your appointment request to Deep Care. No payment will be charged in this demo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: appMuted, height: 1.45, fontSize: 13),
            ),
            const SizedBox(height: 28),
            ReviewCard(
              children: [
                ReviewRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Booking ID',
                  value: isSaved ? booking.id : 'Created after submission',
                ),
                const Divider(height: 24),
                ReviewRow(
                  icon: Icons.medical_services_outlined,
                  label: 'Service',
                  value: booking.service.name,
                ),
                const Divider(height: 24),
                ReviewRow(
                  icon: Icons.event_outlined,
                  label: 'Date & time',
                  value:
                      '${weekdays[booking.date.weekday - 1]}, ${booking.date.day} ${months[booking.date.month - 1]} · ${booking.time}',
                ),
                const Divider(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: BookingAddressBlock(booking: booking),
                ),
              ],
            ),
            const SizedBox(height: 19),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7E6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFC4484B)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                isSaved
                    ? 'The admin team will assign a verified provider. Assignment and visit updates will appear in My Bookings.'
                    : 'Your request is not saved until you submit it below.',
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
          onPressed: _isSaving
              ? null
              : isSaved
              ? () => Navigator.of(context).popUntil((route) => route.isFirst)
              : _submitBooking,
          style: FilledButton.styleFrom(
            backgroundColor: appTeal,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isSaving
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text('Submitting request…'),
                  ],
                )
              : Text(
                  isSaved
                      ? 'View my bookings'
                      : _error == null
                      ? 'Submit booking request'
                      : 'Retry submission',
                ),
        ),
      ),
    );
  }
}
