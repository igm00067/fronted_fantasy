import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../config/app_theme.dart';
import 'crear_oferta_screen.dart';
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
  }

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

  Future<void> _abrirCrearOferta() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearOfertaScreen(
          conversacionId: widget.conversacionId,
          ligaId: widget.ligaId,
          otroUsuarioId: widget.otroUsuario['id'],
          otroUsuarioNombre: widget.otroUsuario['nombre'],
        ),
      ),
    );

    // Si se creó la oferta, recargar mensajes
    if (resultado == true) {
      _cargarMensajes();
    }
  }

  Future<void> _responderOferta(int ofertaId, String accion) async {
    try {
      // Mostrar diálogo de confirmación
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(accion == 'ACEPTAR' ? 'Aceptar oferta' : 'Rechazar oferta'),
          content: Text(
            accion == 'ACEPTAR'
                ? '¿Estás seguro de aceptar esta oferta? El intercambio se realizará inmediatamente.'
                : '¿Estás seguro de rechazar esta oferta?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: accion == 'ACEPTAR' ? Colors.green : Colors.red,
              ),
              child: Text(accion == 'ACEPTAR' ? 'Aceptar' : 'Rechazar'),
            ),
          ],
        ),
      );

      if (confirmar != true) return;

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await ApiService.responderOferta(
        ofertaId: ofertaId,
        accion: accion,
      );

      // Cerrar loading
      if (mounted) Navigator.pop(context);

      // Recargar mensajes
      _cargarMensajes();

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accion == 'ACEPTAR'
                  ? '¡Oferta aceptada! El intercambio se ha realizado.'
                  : 'Oferta rechazada',
            ),
            backgroundColor: accion == 'ACEPTAR' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Cerrar loading si hay error
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
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
              child: Text(
                widget.otroUsuario['nombre'],
                style: const TextStyle(fontSize: 16),
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
              color: AppTheme.surfaceColor,
              border: const Border(top: BorderSide(color: AppTheme.borderColor)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.swap_horiz, color: Colors.blue),
                  onPressed: _abrirCrearOferta,
                  tooltip: 'Hacer oferta',
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
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
    final tipo = mensaje['tipo'] ?? 'TEXTO';

    // Si es una oferta, mostrar card especial
    if (tipo == 'OFERTA') {
      return _buildOfertaCard(mensaje, esMio);
    }

    // Mensaje normal
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
                color: esMio ? const Color(0xFF2979FF) : AppTheme.surfaceVariantColor,
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
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatearHora(mensaje['created_at']),
                    style: TextStyle(
                      color: esMio ? Colors.white70 : AppTheme.textSecondaryColor,
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

  Widget _buildOfertaCard(Map<String, dynamic> mensaje, bool esMio) {
    final oferta = mensaje['oferta'];
    if (oferta == null) return const SizedBox.shrink();

    final estado = oferta['estado'] ?? 'PENDIENTE';
    final jugadorOfrecido = oferta['jugador_ofrecido'];
    final jugadorSolicitado = oferta['jugador_solicitado'];
    final dineroOfrecido = oferta['dinero_ofrecido'] ?? 0.0;
    final dineroSolicitado = oferta['dinero_solicitado'] ?? 0.0;

    Color estadoColor = Colors.orange;
    IconData estadoIcon = Icons.hourglass_empty;
    String estadoTexto = 'Pendiente';

    if (estado == 'ACEPTADA') {
      estadoColor = Colors.green;
      estadoIcon = Icons.check_circle;
      estadoTexto = 'Aceptada';
    } else if (estado == 'RECHAZADA') {
      estadoColor = Colors.red;
      estadoIcon = Icons.cancel;
      estadoTexto = 'Rechazada';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.only(
          left: esMio ? 40 : 0,
          right: esMio ? 0 : 40,
        ),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: estadoColor, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.swap_horiz, color: estadoColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    esMio ? 'Tu oferta' : 'Oferta recibida',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: estadoColor,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(estadoIcon, size: 14, color: estadoColor),
                        const SizedBox(width: 4),
                        Text(
                          estadoTexto,
                          style: TextStyle(
                            color: estadoColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Ofrece
              if (jugadorOfrecido != null || dineroOfrecido > 0) ...[
                Text(
                  esMio ? 'Ofreces:' : 'Te ofrece:',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                if (jugadorOfrecido != null)
                  Text(
                    '⚽ ${jugadorOfrecido['nombre']} (${jugadorOfrecido['posicion']})',
                    style: const TextStyle(fontSize: 14),
                  ),
                if (dineroOfrecido > 0)
                  Text(
                    '💰 ${dineroOfrecido.toStringAsFixed(1)}M',
                    style: const TextStyle(fontSize: 14),
                  ),
                const SizedBox(height: 8),
              ],

              // Solicita
              if (jugadorSolicitado != null || dineroSolicitado > 0) ...[
                Text(
                  esMio ? 'Solicitas:' : 'Te solicita:',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                if (jugadorSolicitado != null)
                  Text(
                    '⚽ ${jugadorSolicitado['nombre']} (${jugadorSolicitado['posicion']})',
                    style: const TextStyle(fontSize: 14),
                  ),
                if (dineroSolicitado > 0)
                  Text(
                    '💰 ${dineroSolicitado.toStringAsFixed(1)}M',
                    style: const TextStyle(fontSize: 14),
                  ),
                const SizedBox(height: 8),
              ],

              // Mensaje
              if (oferta['mensaje'] != null && oferta['mensaje'].toString().isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  '"${oferta['mensaje']}"',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ],

              // Botones de acción (solo si no es mía y está pendiente)
              if (!esMio && estado == 'PENDIENTE') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _responderOferta(oferta['id'], 'RECHAZAR'),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Rechazar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _responderOferta(oferta['id'], 'ACEPTAR'),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Aceptar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Hora
              const SizedBox(height: 8),
              Text(
                _formatearHora(mensaje['created_at']),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
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