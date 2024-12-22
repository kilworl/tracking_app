import 'package:latlong2/latlong.dart';

class GeofenceZone {
  final String id;
  final LatLng center;
  final double radius; // en metros
  final String name;

  GeofenceZone({
    required this.id,
    required this.center,
    required this.radius,
    required this.name,
  });
}

class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();
  factory GeofenceService() => _instance;
  GeofenceService._internal();

  // Lista interna de zonas
  final List<GeofenceZone> _zones = [
    GeofenceZone(
      id: 'zone1',
      center: LatLng(40.4168, -3.7038),
      radius: 500.0,
      name: 'Zona test',
    ),
    GeofenceZone(
      id: 'zone2',
      center: LatLng(41.3874, 2.1686),
      radius: 600.0,
      name: 'Zona test 2',
    ),
  ];

  GeofenceZone? getZoneForLocation(LatLng location) {
    final Distance distanceCalc = const Distance();
    for (var zone in _zones) {
      final double distanceToCenter = distanceCalc(location, zone.center);
      if (distanceToCenter <= zone.radius) {
        return zone;
      }
    }
    return null;
  }

  /// Retorna todas las zonas
  List<GeofenceZone> getAllZones() => _zones;

  /// Agrega una nueva zona a la lista
  void addZone(GeofenceZone zone) {
    _zones.add(zone);
  }
}
