import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

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

