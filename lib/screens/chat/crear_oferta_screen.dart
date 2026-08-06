// ─────────────────────────────────────────────────────────────────────────────
// screens/chat/crear_oferta_screen.dart — Creación de oferta de traspaso
//
// Permite al usuario construir una oferta de intercambio para enviar al rival.
// Una oferta puede incluir cualquier combinación de:
//   - Jugador que ofreces (de tu plantilla)
//   - Dinero que ofreces
//   - Jugador que solicitas (de la plantilla del rival)
//   - Dinero que solicitas
//   - Mensaje de texto
//
// Datos cargados al inicio:
//   - GET /api/ligas/<id>/mi-equipo           → tus jugadores (para ofrecer)
//   - GET /api/ligas/<id>/equipo/<rivalId>     → jugadores del rival (para solicitar)
//   - GET /api/ligas/<id>/mi-equipo            → saldo disponible del usuario
//
// Al confirmar → POST /api/chat/oferta/crear con todos los campos
// El backend crea un mensaje de tipo OFERTA en la conversación y emite
// 'new_message' por Socket.IO al destinatario.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';

class CrearOfertaScreen extends StatefulWidget {
  final int conversacionId;
  final int ligaId;
  final int otroUsuarioId;
  final String otroUsuarioNombre;

  const CrearOfertaScreen({
    Key? key,
    required this.conversacionId,
    required this.ligaId,
    required this.otroUsuarioId,
    required this.otroUsuarioNombre,
  }) : super(key: key);

  @override
  State<CrearOfertaScreen> createState() => _CrearOfertaScreenState();
}

class _CrearOfertaScreenState extends State<CrearOfertaScreen> {
  List<dynamic> _misJugadores = [];
  List<dynamic> _jugadoresRival = [];
  double? _saldoDisponible;

  Map<String, dynamic>? _jugadorOfrecido;
  Map<String, dynamic>? _jugadorSolicitado;

  double _dineroOfrecido = 0;
  double _dineroSolicitado = 0;

  final TextEditingController _mensajeController = TextEditingController();
  final TextEditingController _dineroOfrecidoController = TextEditingController();
  final TextEditingController _dineroSolicitadoController = TextEditingController();

  bool _cargando = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargarJugadores();
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    _dineroOfrecidoController.dispose();
    _dineroSolicitadoController.dispose();
    super.dispose();
  }

  Future<void> _cargarJugadores() async {
    setState(() => _cargando = true);
    try {
      final results = await Future.wait([
        ApiService.getMiEquipo(widget.ligaId),
        ApiService.getEquipoUsuario(widget.ligaId, widget.otroUsuarioId),
        ApiService.getSaldoDisponible(widget.ligaId),
      ]);
      setState(() {
        _misJugadores = results[0] as List<dynamic>;
        _jugadoresRival = results[1] as List<dynamic>;
        _saldoDisponible = results[2] as double;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _enviarOferta() async {
    if (_jugadorOfrecido == null && _dineroOfrecido == 0 &&
        _jugadorSolicitado == null && _dineroSolicitado == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes ofrecer o solicitar algo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      await ApiService.crearOferta(
        conversacionId: widget.conversacionId,
        jugadorOfrecidoId: _jugadorOfrecido?['id'],
        dineroOfrecido: _dineroOfrecido,
        jugadorSolicitadoId: _jugadorSolicitado?['id'],
        dineroSolicitado: _dineroSolicitado,
        mensaje: _mensajeController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oferta enviada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _enviando = false);
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
        title: const Text('Crear oferta'),
        actions: [
          if (_saldoDisponible != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_wallet,
                          size: 14, color: AppTheme.secondaryColor),
                      const SizedBox(width: 5),
                      Text(
                        '${_saldoDisponible!.toStringAsFixed(1)}M',
                        style: const TextStyle(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TU OFRECES
                  _buildSeccionHeader('Tú ofreces', const Color(0xFF2979FF)),
                  const SizedBox(height: 12),
                  _buildJugadorSelector(
                    titulo: 'Jugador (opcional)',
                    jugadores: _misJugadores,
                    jugadorSeleccionado: _jugadorOfrecido,
                    onSelect: (j) => setState(() => _jugadorOfrecido = j),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dineroOfrecidoController,
                    decoration: const InputDecoration(
                      labelText: 'Dinero (millones)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        setState(() => _dineroOfrecido = double.tryParse(v) ?? 0),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // TÚ SOLICITAS
                  _buildSeccionHeader(
                      'Tú solicitas', const Color(0xFF00C853)),
                  const SizedBox(height: 12),
                  _buildJugadorSelector(
                    titulo: 'Jugador de ${widget.otroUsuarioNombre} (opcional)',
                    jugadores: _jugadoresRival,
                    jugadorSeleccionado: _jugadorSolicitado,
                    onSelect: (j) => setState(() => _jugadorSolicitado = j),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dineroSolicitadoController,
                    decoration: const InputDecoration(
                      labelText: 'Dinero (millones)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        setState(() => _dineroSolicitado = double.tryParse(v) ?? 0),
                  ),

                  const SizedBox(height: 24),
                  TextField(
                    controller: _mensajeController,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje (opcional)',
                      prefixIcon: Icon(Icons.message),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _enviando ? null : _enviarOferta,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _enviando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('Enviar oferta',
                            style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSeccionHeader(String titulo, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          titulo,
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildJugadorSelector({
    required String titulo,
    required List<dynamic> jugadores,
    required Map<String, dynamic>? jugadorSeleccionado,
    required Function(Map<String, dynamic>?) onSelect,
  }) {
    final seleccionado = jugadorSeleccionado != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _mostrarSelectorJugadores(jugadores, onSelect),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariantColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: seleccionado
                    ? AppTheme.secondaryColor
                    : AppTheme.borderColor,
                width: seleccionado ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  seleccionado ? Icons.check_circle : Icons.person_search,
                  color: seleccionado
                      ? AppTheme.secondaryColor
                      : AppTheme.textSecondaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    jugadorSeleccionado?['nombre'] ?? 'Seleccionar jugador',
                    style: TextStyle(
                      color: seleccionado
                          ? Colors.white
                          : AppTheme.textSecondaryColor,
                      fontWeight: seleccionado
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (seleccionado)
                  GestureDetector(
                    onTap: () => onSelect(null),
                    child: const Icon(Icons.close,
                        size: 18, color: AppTheme.textSecondaryColor),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarSelectorJugadores(
    List<dynamic> jugadores,
    Function(Map<String, dynamic>?) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            color: AppTheme.surfaceVariantColor,
            child: Row(
              children: [
                const Icon(Icons.people, color: AppTheme.secondaryColor),
                const SizedBox(width: 10),
                const Text('Seleccionar jugador',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: jugadores.isEmpty
                ? const Center(
                    child: Text('No hay jugadores disponibles',
                        style: TextStyle(color: AppTheme.textSecondaryColor)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: jugadores.length,
                    itemBuilder: (context, index) {
                      final jugador = jugadores[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getPosicionColor(
                                jugador['posicion'] ?? ''),
                            child: Text(
                              jugador['posicion'] ?? '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11),
                            ),
                          ),
                          title: Text(jugador['nombre'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${jugador['posicion']}  •  Media: ${jugador['media_fifa']}',
                            style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12),
                          ),
                          trailing: const Icon(Icons.add_circle,
                              color: AppTheme.secondaryColor),
                          onTap: () {
                            onSelect(jugador);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getPosicionColor(String posicion) {
    switch (posicion) {
      case 'POR': return const Color(0xFFE69B00);
      case 'DEF': return const Color(0xFF1565C0);
      case 'MED': return const Color(0xFF2E7D32);
      case 'DEL': return const Color(0xFFC62828);
      default:    return Colors.grey;
    }
  }
}
