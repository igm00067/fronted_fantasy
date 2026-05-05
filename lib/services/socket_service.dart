import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  static IO.Socket? socket;
  static bool _isConnected = false;
  
  static bool get isConnected => _isConnected;
  
  // Callbacks para manejar eventos
  static Function(Map<String, dynamic>)? onNewMessage;
  static Function(Map<String, dynamic>)? onMessageSent;
  static Function(Map<String, dynamic>)? onUserTyping;
  static Function()? onConnected;
  static Function()? onDisconnected;
  
  // ← AÑADIDO: Limpiar todos los listeners
  static void clearListeners() {
    onNewMessage = null;
    onMessageSent = null;
    onUserTyping = null;
    onConnected = null;
    onDisconnected = null;
  }
  
  static Future<void> connect() async {
    if (socket != null && socket!.connected) {
      debugPrint('⚠️ Socket ya está conectado');
      return;
    }
    
    // ← AÑADIDO: Limpiar listeners antes de conectar
    clearListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        debugPrint('❌ No hay token de autenticación');
        return;
      }
      
      debugPrint('🔌 Conectando a WebSocket...');
      
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
        onNewMessage?.call(Map<String, dynamic>.from(data));
      });
      
      socket!.on('message_sent', (data) {
        debugPrint('✅ Mensaje enviado confirmado: $data');
        onMessageSent?.call(Map<String, dynamic>.from(data));
      });
      
      socket!.on('user_typing', (data) {
        debugPrint('⌨️ Usuario escribiendo: $data');
        onUserTyping?.call(Map<String, dynamic>.from(data));
      });
      
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