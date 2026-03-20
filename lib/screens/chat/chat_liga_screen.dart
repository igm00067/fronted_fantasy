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
    final clasificacion = await ApiService.getClasificacion(widget.ligaId);

    setState(() {
      _currentUserId = userData['id'];
      // ← CAMBIO: Usar 'clasificacion' en lugar de 'participantes'
      _participantes = clasificacion['clasificacion'] ?? [];
      _cargando = false;
    });
  } catch (e) {
    setState(() {
      _error = e.toString();
      _cargando = false;
    });
  }
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
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
            // Badge de posición
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getPositionColor(participante['posicion']),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '${participante['posicion']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
            Text(
              participante['equipo_nombre'],
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.stars, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 4),
                Text(
                  '${participante['puntos_totales']} pts',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chat_bubble, color: Colors.blue),
        onTap: () => _abrirChat(participante),
      ),
    );
  }

  Color _getPositionColor(int posicion) {
    if (posicion == 1) return Colors.amber;
    if (posicion == 2) return Colors.grey[400]!;
    if (posicion == 3) return Colors.brown[300]!;
    return Colors.blue;
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
        Navigator.push(
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