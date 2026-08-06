// ─────────────────────────────────────────────────────────────────────────────
// screens/chat/chat_liga_screen.dart — Lista de conversaciones de la liga
//
// Muestra todos los participantes de la liga y las conversaciones existentes.
// El usuario puede tocar cualquier participante para abrir/crear una conversación.
//
// Dos secciones:
//   "Participantes" → lista de todos los miembros de la liga (excepto uno mismo)
//                      Tocar → getOCrearConversacion() → ChatConversacionScreen
//   "Mensajes"      → conversaciones existentes con su último mensaje
//                      Tocar → ChatConversacionScreen directamente
//
// Datos: GET /api/ligas/<id> (para participantes) +
//        GET /api/chat/conversaciones/<ligaId> (para conversaciones con mensajes)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import 'chat_conversacion_screen.dart';

class ChatLigaScreen extends StatefulWidget {
  final int ligaId;

  const ChatLigaScreen({Key? key, required this.ligaId}) : super(key: key);

  @override
  State<ChatLigaScreen> createState() => _ChatLigaScreenState();
}

class _ChatLigaScreenState extends State<ChatLigaScreen> {
  List<dynamic> _participantes = [];
  List<dynamic> _conversaciones = [];
  int? _currentUserId;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final userData = await ApiService.getCurrentUser();
      final ligaData = await ApiService.getLiga(widget.ligaId);
      final clasificacion = await ApiService.getClasificacion(widget.ligaId);

      // Cargar conversaciones existentes para obtener ultimo mensaje y no leidos
      List<dynamic> conversaciones = [];
      try {
        conversaciones = await ApiService.getConversaciones(widget.ligaId);
      } catch (_) {
        // Si falla, seguimos sin conversaciones
      }

      // Crear mapa de abandonado por usuario_id desde los participantes de la liga
      final participantesLiga = ligaData['participantes'] as List<dynamic>? ?? [];
      final abandonadoMap = <int, bool>{};
      for (final p in participantesLiga) {
        abandonadoMap[p['usuario_id']] = p['abandonado'] == true;
      }

      // Enriquecer clasificacion con campo abandonado
      final listaClasificacion = clasificacion['clasificacion'] as List<dynamic>? ?? [];
      for (final c in listaClasificacion) {
        c['abandonado'] = abandonadoMap[c['usuario_id']] ?? false;
      }

      setState(() {
        _currentUserId = userData['id'];
        _participantes = listaClasificacion;
        _conversaciones = conversaciones;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  /// Busca la conversación existente con un usuario para obtener último mensaje y no leídos
  Map<String, dynamic>? _getConversacionConUsuario(int usuarioId) {
    for (final conv in _conversaciones) {
      final otroUsuario = conv['otro_usuario'];
      if (otroUsuario != null && otroUsuario['id'] == usuarioId) {
        return conv as Map<String, dynamic>;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text('Error al cargar miembros', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!.replaceAll('Exception: ', ''),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_participantes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: AppTheme.textSecondaryColor),
            SizedBox(height: 16),
            Text('No hay miembros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _participantes.length,
        itemBuilder: (context, index) {
          final participante = _participantes[index];
          if (participante['usuario_id'] == _currentUserId) {
            return const SizedBox.shrink();
          }
          return _buildMiembroCard(participante);
        },
      ),
    );
  }

  Widget _buildMiembroCard(Map<String, dynamic> participante) {
    final bool abandonado = participante['abandonado'] == true;
    final int usuarioId = participante['usuario_id'];
    final conversacion = _getConversacionConUsuario(usuarioId);

    // Obtener último mensaje y no leídos de la conversación
    String? ultimoMensajeTexto;
    int mensajesNoLeidos = 0;

    if (conversacion != null) {
      final ultimoMensaje = conversacion['ultimo_mensaje'];
      if (ultimoMensaje != null) {
        final contenido = ultimoMensaje['contenido'] as String? ?? '';
        final tipo = ultimoMensaje['tipo'] as String? ?? 'TEXTO';
        if (tipo == 'OFERTA') {
          ultimoMensajeTexto = 'Oferta de intercambio';
        } else {
          ultimoMensajeTexto = contenido;
        }
      }
      mensajesNoLeidos = conversacion['mensajes_no_leidos'] ?? 0;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Opacity(
        opacity: abandonado ? 0.5 : 1.0,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                backgroundColor: abandonado ? Colors.grey : Colors.blue,
                radius: 28,
                child: Text(
                  participante['usuario_nombre'][0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              if (mensajesNoLeidos > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.surfaceColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        mensajesNoLeidos > 99 ? '99+' : '$mensajesNoLeidos',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            participante['usuario_nombre'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (abandonado) ...[
                Text(
                  'Ha abandonado la liga',
                  style: TextStyle(
                    color: Colors.red[400],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ] else if (ultimoMensajeTexto != null) ...[
                Text(
                  ultimoMensajeTexto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mensajesNoLeidos > 0
                        ? Colors.white
                        : Colors.grey[500],
                    fontSize: 13,
                    fontWeight: mensajesNoLeidos > 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ] else ...[
                Text(
                  participante['equipo_nombre'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
          trailing: abandonado
              ? Icon(Icons.block, color: Colors.red[300])
              : const Icon(Icons.chat_bubble, color: Colors.blue),
          onTap: abandonado ? null : () => _abrirChat(participante),
        ),
      ),
    );
  }

  Future<void> _abrirChat(Map<String, dynamic> participante) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Obtener o crear conversación
      final conversacion = await ApiService.getOCrearConversacion(
        otroUsuarioId: participante['usuario_id'],
        ligaId: widget.ligaId,
      );

      // Cerrar loading
      if (mounted) Navigator.pop(context);

      // Navegar al chat
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatConversacionScreen(
              conversacionId: conversacion['id'],
              otroUsuario: {
                'id': participante['usuario_id'],
                'nombre': participante['usuario_nombre'],
              },
              ligaId: widget.ligaId,
            ),
          ),
        );
        // Recargar al volver del chat para actualizar último mensaje y no leídos
        _cargarDatos();
      }
    } catch (e) {
      // Cerrar loading si hay error
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
