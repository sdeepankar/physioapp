import 'package:flutter/material.dart';

class CareService {
  const CareService(
    this.name,
    this.subtitle,
    this.icon,
    this.color,
    this.price, {
    this.id = '',
    this.priceAmount = 0,
    this.priceUnit = 'per_visit',
  });

  factory CareService.fromRow(Map<String, dynamic> row) {
    final name = row['name'] as String? ?? 'Care service';
    final priceAmount = (row['basePrice'] as num?)?.toDouble() ?? 0;
    final visual = careServices.cast<CareService?>().firstWhere(
      (service) => service!.name.toLowerCase() == name.toLowerCase(),
      orElse: () => null,
    );
    final description = row['description'] as String? ?? '';
    final unit = row['priceUnit'] as String? ?? 'per_visit';
    final rupee = String.fromCharCode(0x20B9);
    final formattedPrice = priceAmount == priceAmount.roundToDouble()
        ? '$rupee${priceAmount.toStringAsFixed(0)}'
        : '$rupee${priceAmount.toStringAsFixed(2)}';

    return CareService(
      name,
      description.isNotEmpty ? description : (visual?.subtitle ?? ''),
      visual?.icon ?? Icons.medical_services_outlined,
      visual?.color ?? const Color(0xFF43A8D4),
      unit == 'from' ? 'From $formattedPrice' : formattedPrice,
      id: row[r'$id'] as String? ?? '',
      priceAmount: priceAmount,
      priceUnit: unit,
    );
  }

  final String id;
  final double priceAmount;
  final String priceUnit;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String price;
}

const careServices = <CareService>[
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
