import 'dart:math' as math;

double distanceInKm({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) {
  const earthRadiusKm = 6371.0;
  final dLat = _degreesToRadians(toLat - fromLat);
  final dLng = _degreesToRadians(toLng - fromLng);

  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_degreesToRadians(fromLat)) *
          math.cos(_degreesToRadians(toLat)) *
          math.pow(math.sin(dLng / 2), 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadiusKm * c;
}

String distanceLabelKm(double distanceKm) {
  if (distanceKm < 1) {
    return '${(distanceKm * 1000).round()} m away';
  }

  return '${distanceKm.toStringAsFixed(distanceKm < 10 ? 1 : 0)} km away';
}

double _degreesToRadians(double degrees) => degrees * (math.pi / 180);
