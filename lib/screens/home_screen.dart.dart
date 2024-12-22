import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../services/location_service.dart';
import '../services/background_location_service.dart';
import '../services/notification_service.dart';
import '../services/geofence_service.dart';
import '../services/action_service.dart';
import '../models/action_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// Localización actual para centrar el mapa
  LatLng? currentLocation;

  /// Lista de todos los puntos registrados mientras el usuario se desplaza
  List<LatLng> trackedLocations = [];

  /// Lista de timestamps para cada ubicación
  List<DateTime> trackedTimes = [];

  /// Suscripción al stream de posiciones
  StreamSubscription<Position>? positionSubscription;

  /// Controlador del mapa para poder centrar y hacer zoom programáticamente
  final MapController _mapController = MapController();

  /// Flag para mostrar/ocultar la polyline
  bool _showPolyline = false;

  /// Flag para mostrar/ocultar los marcadores rojos
  bool _showMarkers = true;

  /// Variable para rastrear la última ubicación donde se colocó un marcador
  LatLng? _lastMarkerLocation;

  /// Variable para rastrear la zona actual en la que se encuentra el usuario
  GeofenceZone? _currentZone;

  @override
  void initState() {
    super.initState();

    _loadCurrentLocation();
    _startTracking();

    NotificationService().initNotifications();

    _initBackgroundTracking();
  }

  Future<void> _initBackgroundTracking() async {
    await BackgroundLocationService().initBackgroundTracking();
    await BackgroundLocationService().startBackgroundTracking();
  }

  /// Obtiene la ubicación inicial una sola vez
  Future<void> _loadCurrentLocation() async {
    try {
      final position = await LocationService().getCurrentPosition();
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        // Añadimos la posición inicial a trackedLocations
        trackedLocations.add(currentLocation!);
        trackedTimes.add(DateTime.now());
        // Establecemos la última ubicación para marcadores
        _lastMarkerLocation = currentLocation;

        _currentZone = GeofenceService().getZoneForLocation(currentLocation!);
      });
    } catch (e) {
      print('Error al obtener la ubicación inicial: $e');
    }
  }

  /// Se suscribe al stream para registrar las ubicaciones a medida que cambian
  void _startTracking() {
    positionSubscription = LocationService()
        .getPositionStream(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, // Actualizaciones cada vez que cambia la ubicación
    )
        .listen((Position position) {
      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        // Actualizamos currentLocation para el círculo azul
        currentLocation = newLocation;
      });

      if (_lastMarkerLocation == null ||
          Distance().as(
                LengthUnit.Meter,
                _lastMarkerLocation!,
                newLocation,
              ) >=
              10) {
        setState(() {
          trackedLocations.add(newLocation);
          trackedTimes.add(DateTime.now());
          _lastMarkerLocation = newLocation;
        });
      }

      // Check geofence
      final zone = GeofenceService().getZoneForLocation(newLocation);

      // Manejo de notificaciones al entrar o salir de una zona
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

        // Actualizamos la zona actual
        _currentZone = zone;
      }
    }, onError: (error) {
      print('Error en el stream de ubicación: $error');
    });
  }

  /// Mueve la cámara a una coordenada dada con zoom
  void _goToCoordinate(LatLng latLng, {double zoom = 20}) {
    _mapController.move(latLng, zoom);
  }

  @override
  void dispose() {
    positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Definición de colores desde el tema
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = Theme.of(context).colorScheme.secondary;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Rastreo'),
        actions: [
          IconButton(
            icon: Icon(
              _showPolyline ? Icons.visibility_off : Icons.visibility,
              color: Colors.white,
            ),
            tooltip: _showPolyline ? 'Ocultar Ruta' : 'Mostrar Ruta',
            onPressed: () {
              setState(() {
                _showPolyline = !_showPolyline;
              });
            },
          ),
        ],
      ),
      // -------------------- DRAWER: para ver opciones --------------------
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF1A2332),
          child: ListView(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF1A2332),
                ),
                accountName: const Text(
                  'Usuario',
                  style: TextStyle(color: Colors.white),
                ),
                accountEmail: const Text(
                  'usuario@example.com',
                  style: TextStyle(color: Colors.white70),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: primaryColor,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.list, color: Colors.white),
                title: const Text(
                  'Lista de Coordenadas',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context); // Cierra el Drawer
                  _showCoordinatesList();
                },
              ),
              ListTile(
                leading: const Icon(Icons.map, color: Colors.white),
                title: Text(
                  _showPolyline ? 'Ocultar Ruta' : 'Mostrar Ruta',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context); // Cierra el Drawer
                  setState(() {
                    _showPolyline = !_showPolyline;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_edu, color: Colors.white),
                title: const Text(
                  'Registro de Acciones',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context); // Cierra el Drawer
                  _showActionsList();
                },
              ),
              Divider(color: Colors.white54),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.white),
                title: const Text(
                  'Configuraciones',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
      // ------------------------------------------------------------------------------
      body: currentLocation == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentLocation!,
                initialZoom: 18.0,
                maxZoom: 19.0,
                minZoom: 3.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.tracked',
                ),
                // Círculo Azul para la ubicación actual
                if (currentLocation != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: currentLocation!,
                        color: Colors.blue.withOpacity(0.4),
                        borderStrokeWidth: 2,
                        borderColor: Colors.white,
                        radius: 15,
                      ),
                    ],
                  ),
                // Polyline para la ruta
                if (_showPolyline)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: trackedLocations,
                        color: Theme.of(context).colorScheme.secondary,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
              ],
            ),

      // ---------------------- FLOATING ACTION BUTTONS ----------------------
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        overlayOpacity: 0.4,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add_comment, color: Colors.white),
            backgroundColor: Theme.of(context).primaryColor,
            label: 'Registrar Acción',
            onTap: _openActionDialog,
          ),
          SpeedDialChild(
            child: const Icon(Icons.add_location, color: Colors.white),
            backgroundColor: Theme.of(context).primaryColor,
            label: 'Registrar Zona',
            onTap: _openZoneDialog,
          ),
          SpeedDialChild(
            child: const Icon(Icons.my_location, color: Colors.white),
            backgroundColor: Theme.of(context).primaryColor,
            label: 'Mi Ubicación',
            onTap: () {
              if (currentLocation != null) {
                _goToCoordinate(currentLocation!, zoom: 18);
              }
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Muestra la lista de coordenadas
  // -------------------------------------------------------------------------
  void _showCoordinatesList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2332),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Lista de Coordenadas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.white54),
              Expanded(
                child: ListView.builder(
                  itemCount: trackedLocations.length,
                  itemBuilder: (BuildContext context, int index) {
                    final latLng = trackedLocations[index];
                    final dateTime = trackedTimes[index];
                    return ListTile(
                      leading: Icon(Icons.location_on,
                          color: Theme.of(context).colorScheme.secondary),
                      onTap: () {
                        Navigator.pop(context);
                        _goToCoordinate(latLng);
                      },
                      title: Text(
                        'Lat: ${latLng.latitude.toStringAsFixed(5)}, Lng: ${latLng.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Hora: ${dateTime.toLocal()}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Muestra la lista de acciones registradas
  // -------------------------------------------------------------------------
  void _showActionsList() {
    final actions = ActionService().actions;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2332),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Registro de Acciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.white54),
              Expanded(
                child: actions.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay acciones registradas.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: actions.length,
                        itemBuilder: (context, index) {
                          final a = actions[index];
                          return ListTile(
                            leading: Icon(Icons.task,
                                color: Theme.of(context).colorScheme.secondary),
                            title: Text(
                              'Zona: ${a.zoneId}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Acción: ${a.description}\nFecha: ${a.timestamp.toLocal()}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  // Diálogo para registrar una acción en la zona actual
  // ---------------------------------------------------------
  void _openActionDialog() async {
    if (currentLocation == null) return;

    final zone = GeofenceService().getZoneForLocation(currentLocation!);
    if (zone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No estás en ninguna zona para registrar acción.'),
        ),
      );
      return;
    }

    TextEditingController actionCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          title: Text(
            'Registrar Acción en ${zone.name}',
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: actionCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Describe la acción (texto)',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            TextButton(
              onPressed: () {
                final action = ZoneAction(
                  zoneId: zone.id,
                  timestamp: DateTime.now(),
                  description: actionCtrl.text,
                );
                ActionService().addAction(action);

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Acción registrada en ${zone.name}')),
                );
              },
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.greenAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------
  // Diálogo para registrar una nueva zona usando ubic. actual
  // ---------------------------------------------------------
  void _openZoneDialog() {
    if (currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se puede registrar zona sin ubicación.')),
      );
      return;
    }

    // Usamos la ubicación actual
    final double lat = currentLocation!.latitude;
    final double lng = currentLocation!.longitude;

    TextEditingController radiusCtrl = TextEditingController();
    TextEditingController nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A2332),
          title: const Text(
            'Registrar Nueva Zona',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ubicación actual:\nLat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: radiusCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Radio (metros)',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Zona',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            TextButton(
              onPressed: () {
                final rad = double.tryParse(radiusCtrl.text) ?? 0.0;
                final name =
                    nameCtrl.text.isNotEmpty ? nameCtrl.text : 'Sin nombre';

                final newZone = GeofenceZone(
                  id: 'zone_${DateTime.now().millisecondsSinceEpoch}',
                  center: LatLng(lat, lng),
                  radius: rad,
                  name: name,
                );
                GeofenceService().addZone(newZone);

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Zona "$name" registrada.')),
                );
              },
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.greenAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------
  // Muestra detalles de la zona
  // ---------------------------------------------------------
  void _showZoneDetails(GeofenceZone zone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2332),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                zone.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.white54),
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.white),
                title: Text(
                  'Centro: (${zone.center.latitude.toStringAsFixed(5)}, ${zone.center.longitude.toStringAsFixed(5)})',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.circle, color: Colors.white),
                title: Text(
                  'Radio: ${zone.radius} metros',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
