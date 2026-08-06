// ─────────────────────────────────────────────────────────────────────────────
// services/notification_service.dart — Notificaciones push locales
//
// Usa flutter_local_notifications para mostrar notificaciones nativas de Android
// sin necesidad de un servidor de push (FCM). Las notificaciones se generan
// localmente en el dispositivo cuando llega un evento Socket.IO relevante.
//
// Inicialización:
//   - Se llama init() la primera vez que se conecta el socket (SocketService.connect())
//   - Solicita el permiso POST_NOTIFICATIONS en Android 13+
//   - Configurado en AndroidManifest.xml con el permiso correspondiente
//
// Canal Android: 'fantasy_channel' con importancia HIGH (aparece en cabecera)
//
// Eventos que generan notificación (ver SocketService):
//   new_message (OFERTA)  → "Nueva oferta de traspaso"
//   mercado_ganado        → "Fichaje completado: X por YM"
//   oferta_resuelta       → "Oferta aceptada/rechazada: X"
//   resultado_partido     → "Victoria/Empate/Derrota X-Y vs Z (+WM)"
//   posicion_final        → "Liga finalizada: X de Y con Z puntos"
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static int _nextId = 0;  // ID único incremental para cada notificación

  // Canal de notificación Android (requerido por Android O+)
  static const _androidChannel = AndroidNotificationDetails(
    'fantasy_channel',               // ID del canal (único por app)
    'Fantasy Football Manager',      // nombre visible en ajustes del sistema
    channelDescription: 'Notificaciones del juego',
    importance: Importance.high,     // aparece en cabecera del teléfono
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );
  static const _details = NotificationDetails(android: _androidChannel);

  /// Inicializa el plugin de notificaciones y solicita permiso en Android 13+.
  /// Es idempotente: si ya está inicializado, no hace nada.
  static Future<void> init() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: androidSettings));
    // Solicitar permiso POST_NOTIFICATIONS (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  /// Muestra una notificación local con título y cuerpo.
  /// Inicializa automáticamente si aún no se había hecho.
  /// Cada notificación tiene un ID único para no reemplazar notificaciones anteriores.
  static Future<void> show({required String title, required String body}) async {
    if (!_initialized) await init();
    await _plugin.show(_nextId++, title, body, _details);
  }
}
