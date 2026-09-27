import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/care_service.dart';
import '../core/app_settings.dart';
import '../models/booking.dart';
import 'booking_history_screen.dart';

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
    final matches = careServices
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
            color: appInk,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
          ),
        ),
        backgroundColor: appCanvas,
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
                      style: TextStyle(color: appMuted),
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
                              color: appTeal,
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
      backgroundColor: appCanvas,
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
                    color: appTeal,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'You’re all caught up',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: appInk,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Booking updates will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: appMuted),
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
                    child: Icon(Icons.event_available_outlined, color: appTeal),
                  ),
                  title: Text(
                    '${booking.service.name} booking confirmed',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${booking.date.day} ${months[booking.date.month - 1]} · ${booking.time}',
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

