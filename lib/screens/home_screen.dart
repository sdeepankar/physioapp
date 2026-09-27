import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/booking.dart';
import '../models/care_service.dart';
import '../services/location_service.dart';
import '../widgets/shared_widgets.dart';
import '../core/app_settings.dart';

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
                HomeHeader(
                  currentPlace: currentPlace,
                  isLocating: isLocating,
                  onLocationTap: onLocationTap,
                  onSearchTap: onSearchTap,
                  onNotificationsTap: onNotificationsTap,
                  hasUnreadNotifications: hasUnreadNotifications,
                ),
                const SizedBox(height: 22),
                CareBanner(onExplore: onBrowseServices),
                const SizedBox(height: 27),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Our services',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: appInk,
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
                  itemCount: careServices.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 17,
                    crossAxisSpacing: 10,
                    childAspectRatio: .79,
                  ),
                  itemBuilder: (context, index) => ServiceTile(
                    service: careServices[index],
                    onTap: () => onServiceTap(careServices[index]),
                  ),
                ),
                const SizedBox(height: 24),
                AppointmentCard(
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

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
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
                    color: appMuted,
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
                          color: appTeal,
                        ),
                      )
                    else
                      const Icon(
                        Icons.location_on_rounded,
                        size: 15,
                        color: appTeal,
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
                          color: appInk,
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
      HeaderButton(
        icon: Icons.search_rounded,
        label: 'Search',
        onTap: onSearchTap,
      ),
      const SizedBox(width: 8),
      HeaderButton(
        icon: Icons.notifications_none_rounded,
        label: 'Notifications',
        badge: hasUnreadNotifications,
        onTap: onNotificationsTap,
      ),
    ],
  );
}

class HeaderButton extends StatelessWidget {
  const HeaderButton({
    super.key,
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
              Icon(icon, color: appInk, size: 22),
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

class CareBanner extends StatelessWidget {
  const CareBanner({super.key, required this.onExplore});
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
                foregroundColor: appTeal,
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
        backgroundColor: appCanvas,
        title: const Text(
          'Select a service',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: appInk,
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
                Icon(Icons.favorite_rounded, color: appTeal, size: 26),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Professional care,\nright at your doorstep.',
                    style: TextStyle(
                      color: appInk,
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
              color: appInk,
            ),
          ),
          const SizedBox(height: 12),
          for (final service in careServices)
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
                                  color: appInk,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                service.subtitle,
                                style: const TextStyle(
                                  color: appMuted,
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
                              color: appMuted,
                            ),
                            Text(
                              'From ${service.price}',
                              style: const TextStyle(
                                color: appMuted,
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

class ServiceTile extends StatelessWidget {
  const ServiceTile({super.key, required this.service, required this.onTap});
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
            color: appInk,
          ),
        ),
      ],
    ),
  );
}

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({super.key, required this.nextVisit, required this.onVisitTap});

  final Booking? nextVisit;
  final VoidCallback onVisitTap;

  @override
  Widget build(BuildContext context) {
    final booking = nextVisit;
    final dateLabel = booking == null
        ? ''
        : '${weekdays[booking.date.weekday - 1]}, ${booking.date.day} ${months[booking.date.month - 1]} · ${booking.time}';

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
                    color: appTeal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Your next visit',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: appInk,
                      ),
                    ),
                  ),
                  Icon(
                    booking == null
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.chevron_right_rounded,
                    size: 16,
                    color: appMuted,
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
                        child: Icon(Icons.event_note_rounded, color: appTeal),
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
                              color: appInk,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap to explore and book a care service',
                            style: TextStyle(fontSize: 11, color: appMuted),
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
                              color: appInk,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateLabel,
                            style: const TextStyle(fontSize: 11, color: appMuted),
                          ),
                          if (booking.localitySummary.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              booking.localitySummary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: appMuted,
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
              child: Icon(icon, size: 38, color: appTeal),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: appInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: appMuted, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}
