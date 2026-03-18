import 'package:flutter/material.dart';
import '../../services/api_service.dart';

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
      final misJugadores = await ApiService.getMiEquipo(widget.ligaId);
      final jugadoresRival = await ApiService.getEquipoUsuario(
        widget.ligaId,
        widget.otroUsuarioId,
      );

      setState(() {
        _misJugadores = misJugadores;
        _jugadoresRival = jugadoresRival;
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
    // Validar que al menos se ofrezca o solicite algo
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
        Navigator.pop(context, true); // Retornar true para indicar éxito
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
        backgroundColor: Colors.blue,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TU OFRECES
                  _buildSeccionHeader('Tú ofreces', Colors.blue),
                  const SizedBox(height: 12),
                  
                  // Jugador ofrecido
                  _buildJugadorSelector(
                    titulo: 'Jugador',
                    jugadores: _misJugadores,
                    jugadorSeleccionado: _jugadorOfrecido,
                    onSelect: (jugador) {
                      setState(() => _jugadorOfrecido = jugador);
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Dinero ofrecido
                  TextField(
                    controller: _dineroOfrecidoController,
                    decoration: const InputDecoration(
                      labelText: 'Dinero (millones)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _dineroOfrecido = double.tryParse(value) ?? 0;
                      });
                    },
                  ),

                  const SizedBox(height: 24),
                  const Divider(thickness: 2),
                  const SizedBox(height: 24),

                  // SOLICITAS
                  _buildSeccionHeader('Tú solicitas', Colors.green),
                  const SizedBox(height: 12),
                  
                  // Jugador solicitado
                  _buildJugadorSelector(
                    titulo: 'Jugador de ${widget.otroUsuarioNombre}',
                    jugadores: _jugadoresRival,
                    jugadorSeleccionado: _jugadorSolicitado,
                    onSelect: (jugador) {
                      setState(() => _jugadorSolicitado = jugador);
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Dinero solicitado
                  TextField(
                    controller: _dineroSolicitadoController,
                    decoration: const InputDecoration(
                      labelText: 'Dinero (millones)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _dineroSolicitado = double.tryParse(value) ?? 0;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Mensaje opcional
                  TextField(
                    controller: _mensajeController,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  // Botón enviar
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _enviarOferta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: _enviando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Enviar oferta',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
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
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _mostrarSelectorJugadores(jugadores, onSelect),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  color: jugadorSeleccionado != null ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    jugadorSeleccionado?['nombre'] ?? 'Seleccionar jugador',
                    style: TextStyle(
                      color: jugadorSeleccionado != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                if (jugadorSeleccionado != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => onSelect(null),
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
      builder: (context) => ListView.builder(
        itemCount: jugadores.length,
        itemBuilder: (context, index) {
          final jugador = jugadores[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: jugador['foto_url'] != null
                  ? NetworkImage(jugador['foto_url'])
                  : null,
              child: jugador['foto_url'] == null
                  ? Text(jugador['nombre'][0].toUpperCase())
                  : null,
            ),
            title: Text(jugador['nombre']),
            subtitle: Text(jugador['posicion']),
            onTap: () {
              onSelect(jugador);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}