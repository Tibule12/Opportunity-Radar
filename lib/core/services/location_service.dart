import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class AppLocation {
  const AppLocation({
    required this.latitude,
    required this.longitude,
    this.addressText,
  });

  final double latitude;
  final double longitude;
  final String? addressText;
}

class LocationService {
  Future<AppLocation> getCurrentLocation({bool includeAddress = true}) async {
    await _ensurePermission();
    final position = await Geolocator.getCurrentPosition();

    String? addressText;
    if (includeAddress) {
      addressText = await reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }

    return AppLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      addressText: addressText,
    );
  }

  Stream<AppLocation> liveLocationStream() async* {
    await _ensurePermission();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 15,
    );

    await for (final position in Geolocator.getPositionStream(locationSettings: settings)) {
      yield AppLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }
  }

  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) {
      return null;
    }

    final placemark = placemarks.first;
    final segments = [
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.administrativeArea,
    ].where((segment) => segment != null && segment!.trim().isNotEmpty).cast<String>().toList();

    if (segments.isEmpty) {
      return null;
    }

    return segments.join(', ');
  }

  Future<void> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('Location services are disabled on this device.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission was not granted.');
    }
  }
}

