import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/booking.dart';
import '../widgets/shared_widgets.dart';
import '../core/app_settings.dart';

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
                        color: appTeal,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No bookings yet',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: appInk,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your appointments will appear here once you complete the demo booking flow.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: appMuted, height: 1.5),
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
                    color: appInk,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your local demo appointments',
                  style: TextStyle(color: appMuted, fontSize: 13),
                ),
                const SizedBox(height: 18),
                for (final booking in bookings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BookingCard(
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

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking, required this.onTap});

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
                          color: appInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Booking ID: ${booking.id}',
                        style: const TextStyle(color: appMuted, fontSize: 11),
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
                      color: appTeal,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 23),
            ReviewRow(
              icon: Icons.event_outlined,
              label: 'Date & time',
              value:
                  '${weekdays[booking.date.weekday - 1]}, ${booking.date.day} ${months[booking.date.month - 1]} · ${booking.time}',
            ),
            const SizedBox(height: 13),
            BookingAddressBlock(booking: booking),
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
        backgroundColor: appCanvas,
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
                    color: appInk,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Demo booking · ${booking.id}',
                  style: const TextStyle(color: appMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ReviewCard(
            children: [
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
              if (booking.landmark.isNotEmpty) ...[
                const Divider(height: 24),
                ReviewRow(
                  icon: Icons.near_me_outlined,
                  label: 'Landmark',
                  value: booking.landmark,
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          ReviewCard(
            children: [
              const Text(
                'Care professional',
                style: TextStyle(fontWeight: FontWeight.w700, color: appInk),
              ),
              const SizedBox(height: 8),
              const Text(
                'A verified professional will be assigned when real booking services are connected.',
                style: TextStyle(color: appMuted, height: 1.45, fontSize: 12),
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

