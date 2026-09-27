import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/booking.dart';
import '../models/care_service.dart';

class BookingAddressBlock extends StatelessWidget {
  const BookingAddressBlock({super.key, required this.booking});
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
          color: appInk,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.55,
        ),
      ),
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


class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.children});

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

class ReviewRow extends StatelessWidget {
  const ReviewRow({
    super.key,
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
      Icon(icon, color: appTeal, size: 19),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: bold ? appInk : appMuted,
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
            color: appInk,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

