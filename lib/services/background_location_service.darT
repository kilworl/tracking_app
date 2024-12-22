
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'geofence_service.dart'; 
import 'notification_service.dart'; 

class BackgroundLocationService {
  static final BackgroundLocationService _instance =
      BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  StreamSubscription<Position>? _bgSubscription;


  GeofenceZone? _currentZone;

  /// Inicializa lo necesario para el tracking en background
  Future<void> initBackgroundTracking() async {
    
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // El servicio de ubicación no está habilitado
      return;
    }

    // Verificar permisos de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permisos denegados
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permisos denegados permanentemente
      return;
    }

 
  }

  /// Inicia el stream de ubicación en segundo plano
  Future<void> startBackgroundTracking() async {
    _bgSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, 
      ),
    ).listen((Position position) {
      final newLocation = LatLng(position.latitude, position.longitude);

      // NUEVO: Verificar cambios de zona
      final zone = GeofenceService().getZoneForLocation(newLocation);

      if (zone != _currentZone) {
        if (_currentZone != null && zone == null) {
          // Salió de una zona
          NotificationService().showNotification(
            'Has salido de la zona',
            'Has salido de ${_currentZone!.name}.',
          );
        } else if (_currentZone == null && zone != null) {
          // Entró en una zona
          NotificationService().showNotification(
            'Has entrado en una zona',
            'Has entrado a ${zone.name}.',
          );
        } else if (_currentZone != null &&
            zone != null &&
            zone.id != _currentZone!.id) {
          // Cambió de una zona a otra
          NotificationService().showNotification(
            'Cambio de zona',
            'Has salido de ${_currentZone!.name} y entrado a ${zone.name}.',
          );
        }

       
        _currentZone = zone;
      }

      
      print('[BG Tracking] Nueva posición: '
          '${position.latitude}, ${position.longitude}');
    });
  }

  Future<void> stopBackgroundTracking() async {
    await _bgSubscription?.cancel();
  }
}
