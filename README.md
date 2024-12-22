Mapa de Rastreo con Geofencing
Esta aplicación móvil basada en Flutter permite a los usuarios rastrear su ubicación en tiempo real, registrar acciones y geocercas (geofences) y visualizar rutas en un mapa interactivo. Además, envía notificaciones al usuario al entrar o salir de zonas predefinidas.

Características
Rastreo de ubicación en tiempo real.
Visualización de la ruta recorrida con una polyline.
Registro y visualización de acciones en zonas específicas.
Creación y gestión de geocercas (zonas geográficas).
Notificaciones al entrar o salir de una zona.
Interfaz con menús y opciones configurables.
Requisitos
Dependencias
Flutter SDK (versión estable más reciente)
Dart SDK
Plugins usados:
flutter_map
geolocator
flutter_speed_dial
latlong2


Uso de la Aplicación
Iniciar la aplicación
La aplicación mostrará un mapa centrado en la ubicación actual del usuario.

Funciones principales:

Registrar acción: Utiliza el botón flotante para registrar una acción en una zona específica.
Crear zona: Crea nuevas geocercas para delimitar áreas específicas.
Visualizar rutas: Alterna la visibilidad de las rutas usando el botón correspondiente en el menú.
Historial de acciones: Accede al registro de acciones desde el menú lateral.
Notificaciones:
Recibirás alertas al entrar o salir de zonas configuradas.


Guía para instalar y ejecutar en local
Paso 1: Clonar el repositorio
Abre tu terminal o consola y clona el repositorio:

git clone https://github.com/<TU-USUARIO>/<NOMBRE-DEL-REPO>.git
cd <NOMBRE-DEL-REPO>


Paso 2: Instalar dependencias
Asegúrate de estar en el directorio raíz del proyecto y ejecuta:

flutter pub get


Paso 3: Configurar permisos
Android
Abre el archivo android/app/src/main/AndroidManifest.xml y verifica que los permisos estén configurados:

<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

Configura el archivo android/app/src/main/res/values/styles.xml para añadir cualquier API Key requerida (si aplicable).


iOS
Abre el archivo ios/Runner/Info.plist y añade los siguientes permisos:

<key>NSLocationWhenInUseUsageDescription</key>
<string>Se necesita acceso a tu ubicación para mostrar tu posición en el mapa.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Se necesita acceso a tu ubicación para rastrear tu posición en segundo plano.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Se necesita acceso a tu ubicación para funcionalidades de geofencing.</string>


Si usas notificaciones, configura también los permisos para enviar notificaciones en iOS.

Paso 4: Ejecutar la aplicación
Conecta un dispositivo físico o inicia un emulador (Android o iOS). Luego, ejecuta:

flutter run

