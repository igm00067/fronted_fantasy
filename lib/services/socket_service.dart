// ─────────────────────────────────────────────────────────────────────────────
// services/socket_service.dart — Cliente WebSocket (Socket.IO)
//
// Gestiona la conexión persistente con el servidor Flask-SocketIO.
// Se usa para:
//   1. Chat en tiempo real (mensajes de texto, indicador de escritura)
//   2. Notificaciones de juego (resultado de partido, fichaje ganado, oferta resuelta)
//   3. Eventos de simulación en vivo (para partido_screen.dart)
//
// Conexión:
//   - Se conecta al arrancar la app y al hacer login
//   - Envía el JWT en el campo 'auth' de Socket.IO para autenticarse
//   - El servidor une al usuario automáticamente a la sala 'user_{id}'
//   - Para recibir eventos de simulación, la pantalla debe llamar a joinLiga()
//
// Callbacks (patrón observer simplificado):
//   - Las pantallas asignan sus handlers a onNewMessage, onMessageSent, etc.
//   - clearListeners() limpia todos al navegar o desconectar
//
// Notificaciones push locales (flutter_local_notifications):
//   Se disparan automáticamente al recibir ciertos eventos del servidor:
//     new_message (OFERTA)  → "Nueva oferta de traspaso"
//     mercado_ganado        → "Fichaje completado: X por YM"
//     oferta_resuelta       → "Oferta aceptada/rechazada"
//     resultado_partido     → "Victoria/Empate/Derrota X-Y vs Z (+WM)"
//     posicion_final        → "Liga finalizada: X de Y con Z puntos"
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class SocketService {
  static IO.Socket? socket;
  static bool _isConnected = false;

  static bool get isConnected => _isConnected;

  // ── Callbacks para el chat (asignados por chat_conversacion_screen.dart) ────
  static Function(Map<String, dynamic>)? onNewMessage;    // nuevo mensaje recibido
  static Function(Map<String, dynamic>)? onMessageSent;  // confirmación de envío propio
  static Function(Map<String, dynamic>)? onUserTyping;   // el otro está escribiendo
  static Function()? onConnected;
  static Function()? onDisconnected;

  /// Limpia todos los callbacks. Se llama al salir de la pantalla de chat
  /// o al desconectar, para evitar llamar a funciones de pantallas ya cerradas.
  static void clearListeners() {
    onNewMessage = null;
    onMessageSent = null;
    onUserTyping = null;
    onConnected = null;
    onDisconnected = null;
  }
  
  /// Establece la conexión WebSocket con el servidor.
  /// Si ya hay una conexión activa, no hace nada.
  /// Inicializa NotificationService antes de conectar (permisos de notificaciones).
  /// El JWT se envía en el campo 'auth' para autenticar la conexión en el servidor.
  static Future<void> connect() async {
    if (socket != null && socket!.connected) {
      debugPrint('⚠️ Socket ya está conectado');
      return;
    }

    clearListeners(); // limpiar callbacks anteriores de sesiones previas

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        debugPrint('❌ No hay token de autenticación');
        return;
      }
      
      debugPrint('🔌 Conectando a WebSocket...');
      await NotificationService.init();

      socket = IO.io(
        'http://10.0.2.2:5000',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()
            .setAuth({'token': token})
            .build(),
      );
      
      // Event listeners
      socket!.onConnect((_) {
        debugPrint('✅ Conectado a WebSocket');
        _isConnected = true;
        onConnected?.call();
      });
      
      socket!.onDisconnect((_) {
        debugPrint('❌ Desconectado de WebSocket');
        _isConnected = false;
        onDisconnected?.call();
      });
      
      socket!.on('connected', (data) {
        debugPrint('✅ Confirmación del servidor: $data');
      });
      
      socket!.on('new_message', (data) {
        debugPrint('💬 Nuevo mensaje recibido: $data');
        final d = Map<String, dynamic>.from(data);
        onNewMessage?.call(d);
        // Notificación para ofertas entrantes
        if (d['tipo'] == 'OFERTA') {
          NotificationService.show(
            title: 'Nueva oferta de traspaso',
            body: 'Tienes una oferta pendiente de responder',
          );
        }
      });
      
      socket!.on('message_sent', (data) {
        debugPrint('✅ Mensaje enviado confirmado: $data');
        onMessageSent?.call(Map<String, dynamic>.from(data));
      });
      
      socket!.on('user_typing', (data) {
        debugPrint('⌨️ Usuario escribiendo: $data');
        onUserTyping?.call(Map<String, dynamic>.from(data));
      });
      
      // ── Notificaciones de juego ──────────────────────────────────
      socket!.on('mercado_ganado', (data) {
        final d = Map<String, dynamic>.from(data);
        final jugador = d['jugador_nombre'] ?? 'jugador';
        final precio = d['precio'] ?? 0.0;
        NotificationService.show(
          title: 'Fichaje completado',
          body: 'Has fichado a $jugador por ${precio}M',
        );
      });

      socket!.on('oferta_resuelta', (data) {
        final d = Map<String, dynamic>.from(data);
        final estado = (d['estado'] as String? ?? '');
        final jugador = d['jugador_nombre'] ?? 'el jugador';
        if (estado == 'ACEPTADA') {
          NotificationService.show(
            title: 'Oferta aceptada',
            body: 'Tu oferta por $jugador ha sido aceptada',
          );
        } else if (estado == 'RECHAZADA') {
          NotificationService.show(
            title: 'Oferta rechazada',
            body: 'Tu oferta por $jugador ha sido rechazada',
          );
        }
      });

      socket!.on('resultado_partido', (data) {
        final d = Map<String, dynamic>.from(data);
        final resultado = d['resultado'] as String? ?? '';
        final gf = d['goles_favor'] ?? 0;
        final gc = d['goles_contra'] ?? 0;
        final rival = d['rival'] ?? 'Rival';
        final premio = d['premio'] ?? 0.0;
        switch (resultado) {
          case 'victoria':
            NotificationService.show(
              title: 'Victoria',
              body: 'Ganaste $gf-$gc a $rival (+${premio}M)',
            );
            break;
          case 'empate':
            NotificationService.show(
              title: 'Empate',
              body: 'Empataste $gf-$gc contra $rival (+${premio}M)',
            );
            break;
          default:
            NotificationService.show(
              title: 'Derrota',
              body: 'Perdiste $gf-$gc ante $rival',
            );
        }
      });

      socket!.on('posicion_final', (data) {
        final d = Map<String, dynamic>.from(data);
        final pos = d['posicion'] ?? '?';
        final total = d['total'] ?? '?';
        final puntos = d['puntos'] ?? 0;
        NotificationService.show(
          title: 'Liga finalizada',
          body: 'Has quedado $pos de $total con $puntos puntos',
        );
      });
      // ─────────────────────────────────────────────────────────────

      socket!.on('error', (data) {
        debugPrint('❌ Error del socket: $data');
      });
      
      socket!.onConnectError((data) {
        debugPrint('❌ Error de conexión: $data');
        _isConnected = false;
      });
      
    } catch (e) {
      debugPrint('❌ Error conectando socket: $e');
      _isConnected = false;
    }
  }
  
  static Future<void> disconnect() async {
    if (socket != null) {
      socket!.disconnect();
      socket!.dispose();
      socket = null;
      _isConnected = false;
      clearListeners();  // ← AÑADIDO: Limpiar al desconectar
      debugPrint('👋 Socket desconectado');
    }
  }
  
  /// Envía un mensaje de texto a través del WebSocket (evento 'send_message').
  /// Si el socket no está conectado, intenta reconectar antes de enviar.
  /// El servidor lo guarda en BD y lo reenvía al destinatario (evento 'new_message').
  static Future<void> sendMessage({
    required int conversacionId,
    required String contenido,
  }) async {
    if (socket == null || !socket!.connected) {
      debugPrint('❌ Socket no conectado');
      await connect();
      await Future.delayed(const Duration(seconds: 1));
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      socket!.emit('send_message', {
        'conversacion_id': conversacionId,
        'contenido': contenido,
        'token': token,
      });
      
      debugPrint('📤 Mensaje enviado via socket');
    } catch (e) {
      debugPrint('❌ Error enviando mensaje: $e');
    }
  }
  
  /// Notifica al servidor que el usuario está escribiendo (o dejó de escribir).
  /// El servidor reenvía el evento 'user_typing' al otro usuario de la conversación.
  /// Se usa para mostrar el indicador "..." en el chat.
  static void setTyping({
    required int conversacionId,
    required bool isTyping,
  }) async {
    if (socket == null || !socket!.connected) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      socket!.emit('typing', {
        'conversacion_id': conversacionId,
        'is_typing': isTyping,
        'token': token,
      });
    } catch (e) {
      debugPrint('❌ Error enviando typing: $e');
    }
  }
  
  /// Une al usuario a la sala de una conversación ('conv_{id}').
  /// Actualmente usado para el indicador de escritura; los mensajes llegan
  /// directamente a la sala personal 'user_{id}' sin necesitar unirse a conv.
  static void joinConversation(int conversacionId) async {
    if (socket == null || !socket!.connected) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      socket!.emit('join_conversation', {
        'conversacion_id': conversacionId,
        'token': token,
      });
      
      debugPrint('✅ Unido a conversación $conversacionId');
    } catch (e) {
      debugPrint('❌ Error uniéndose a conversación: $e');
    }
  }
  
  static void leaveConversation(int conversacionId) {
    if (socket == null || !socket!.connected) return;
    
    socket!.emit('leave_conversation', {
      'conversacion_id': conversacionId,
    });
    
    debugPrint('👋 Salió de conversación $conversacionId');
  }
}