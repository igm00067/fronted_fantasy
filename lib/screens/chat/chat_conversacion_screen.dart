import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import 'dart:async';

class ChatConversacionScreen extends StatefulWidget {
  final int conversacionId;
  final Map<String, dynamic> otroUsuario;
  final int ligaId;

  const ChatConversacionScreen({
    Key? key,
    required this.conversacionId,
    required this.otroUsuario,
    required this.ligaId,
  }) : super(key: key);

  @override
  State<ChatConversacionScreen> createState() => _ChatConversacionScreenState();
}

class _ChatConversacionScreenState extends State<ChatConversacionScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _mensajes = [];
  bool _cargando = true;
  bool _enviando = false;
  bool _otroUsuarioEscribiendo = false;
  int? _currentUserId;

  Timer? _typingTimer;
  Timer? _typingIndicatorTimer;

  @override
  void initState() {
    super.initState();
    _cargarUsuarioActual();
    _cargarMensajes();
    _configurarSocketListeners();
    SocketService.joinConversation(widget.conversacionId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _typingIndicatorTimer?.cancel();
    SocketService.leaveConversation(widget.conversacionId);

    // Limpiar listeners
    SocketService.onNewMessage = null;
    SocketService.onMessageSent = null;
    SocketService.onUserTyping = null;

    super.dispose();
  }

  Future<void> _cargarUsuarioActual() async {
    try {
      final userData = await ApiService.getCurrentUser();
      setState(() {
        _currentUserId = userData['id'];
      });
    } catch (e) {
      print('Error cargando usuario: $e');
    }
  }

  void _configurarSocketListeners() {
    // Limpiar listeners anteriores primero
    SocketService.onNewMessage = null;
    SocketService.onMessageSent = null;
    SocketService.onUserTyping = null;

    // Ahora configurar los nuevos
    SocketService.onNewMessage = (data) {
      if (!mounted) return;
      
      if (data['conversacion_id'] == widget.conversacionId) {
        // Evitar duplicados
        final yaExiste = _mensajes.any((m) =>
            m['id'] == data['id'] ||
            (m['contenido'] == data['contenido'] &&
                m['remitente_id'] == data['remitente_id'] &&
                m['created_at'] == data['created_at']));

        if (!yaExiste) {
          setState(() {
            _mensajes.add(data);
          });
          _scrollToBottom();
        }
      }
    };

    SocketService.onMessageSent = (data) {
      if (!mounted) return;
      
      if (data['conversacion_id'] == widget.conversacionId) {
        // Buscar y reemplazar el mensaje temporal con el real
        final index = _mensajes.indexWhere((m) =>
            m['contenido'] == data['contenido'] &&
            m['remitente_id'] == data['remitente_id']);

        if (index != -1 && mounted) {
          setState(() {
            _mensajes[index] = data;
          });
        }
      }
    };

    // Typing desactivado por problemas de rendimiento
    /*
    SocketService.onUserTyping = (data) {
      if (!mounted) return;
      
      if (data['conversacion_id'] == widget.conversacionId) {
        final isTyping = data['is_typing'] ?? false;
        
        if (_otroUsuarioEscribiendo != isTyping) {
          setState(() {
            _otroUsuarioEscribiendo = isTyping;
          });
        }

        _typingIndicatorTimer?.cancel();

        if (isTyping) {
          _typingIndicatorTimer = Timer(const Duration(seconds: 3), () {
            if (mounted && _otroUsuarioEscribiendo) {
              setState(() {
                _otroUsuarioEscribiendo = false;
              });
            }
          });
        }
      }
    };
    */
  }  // ← Aquí estaba el problema, faltaba cerrar la llave

  Future<void> _cargarMensajes() async {
    setState(() => _cargando = true);

    try {
      final mensajes = await ApiService.getMensajes(widget.conversacionId);
      setState(() {
        _mensajes = mensajes;
        _cargando = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTyping() {
    // Desactivado por problemas de rendimiento
  }

  Future<void> _enviarMensaje() async {
    final texto = _messageController.text.trim();
    if (texto.isEmpty) return;

    setState(() => _enviando = true);

    try {
      // Añadir mensaje optimista (se mostrará inmediatamente)
      final mensajeTemp = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'conversacion_id': widget.conversacionId,
        'remitente_id': _currentUserId,
        'contenido': texto,
        'tipo': 'TEXTO',
        'leido': false,
        'created_at': DateTime.now().toIso8601String(),
        'remitente': {
          'id': _currentUserId,
          'nombre': 'Tú',
        }
      };

      setState(() {
        _mensajes.add(mensajeTemp);
        _messageController.clear();
      });

      _scrollToBottom();

      // Enviar vía WebSocket
      await SocketService.sendMessage(
        conversacionId: widget.conversacionId,
        contenido: texto,
      );

      setState(() => _enviando = false);
    } catch (e) {
      setState(() => _enviando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 18,
              child: Text(
                widget.otroUsuario['nombre'][0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otroUsuario['nombre'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  // Typing indicator desactivado
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Opciones
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _mensajes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay mensajes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Envía el primer mensaje',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _mensajes.length,
                        itemBuilder: (context, index) {
                          final mensaje = _mensajes[index];
                          return _buildMensajeBubble(mensaje);
                        },
                      ),
          ),

          // Barra de entrada de mensaje
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Próximamente: Hacer oferta'),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    // onChanged desactivado para evitar problemas de teclado
                    onSubmitted: (_) => _enviarMensaje(),
                  ),
                ),
                IconButton(
                  icon: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Colors.blue),
                  onPressed: _enviando ? null : _enviarMensaje,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMensajeBubble(Map<String, dynamic> mensaje) {
    final bool esMio = mensaje['remitente_id'] == _currentUserId;
    final remitente = mensaje['remitente'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!esMio) ...[
            CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 16,
              child: Text(
                remitente?['nombre']?[0]?.toUpperCase() ?? '?',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: esMio ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(esMio ? 16 : 4),
                  bottomRight: Radius.circular(esMio ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mensaje['contenido'] ?? '',
                    style: TextStyle(
                      color: esMio ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatearHora(mensaje['created_at']),
                    style: TextStyle(
                      color: esMio ? Colors.white70 : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearHora(String? fechaStr) {
    if (fechaStr == null) return '';
    try {
      final fecha = DateTime.parse(fechaStr);
      final ahora = DateTime.now();

      if (fecha.year == ahora.year &&
          fecha.month == ahora.month &&
          fecha.day == ahora.day) {
        return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
      } else {
        return '${fecha.day}/${fecha.month} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }
}