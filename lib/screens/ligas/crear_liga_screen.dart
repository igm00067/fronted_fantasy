// ─────────────────────────────────────────────────────────────────────────────
// screens/ligas/crear_liga_screen.dart — Formulario para crear una liga nueva
//
// Campos del formulario:
//   - Nombre de la liga (obligatorio)
//   - Nombre del equipo del creador (opcional, se genera automáticamente si vacío)
//   - Competición (dropdown cargado desde GET /api/competiciones)
//   - Número máximo de participantes (slider o selector, default 10)
//   - Presupuesto inicial (slider, default 100M)
//
// Al confirmar → POST /api/ligas con los datos del formulario
// El backend asigna al creador como primer participante y genera:
//   - Su EquipoFantasy con el nombre elegido
//   - El codigo_invitacion de 6 caracteres aleatorio
//
// Tras crear la liga, vuelve a HomeScreen con Navigator.pop().
// La lista de ligas se recarga en MisLigasScreen al volver.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CrearLigaScreen extends StatefulWidget {
  const CrearLigaScreen({Key? key}) : super(key: key);

  @override
  State<CrearLigaScreen> createState() => _CrearLigaScreenState();
}

class _CrearLigaScreenState extends State<CrearLigaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreLigaController = TextEditingController();
  final _nombreEquipoController = TextEditingController();
  
  List<dynamic> _competiciones = [];
  int? _competicionSeleccionada;
  int _maxParticipantes = 10;
  double _presupuestoInicial = 100.0;
  bool _cargando = false;
  bool _cargandoCompeticiones = true;

  @override
  void initState() {
    super.initState();
    _cargarCompeticiones();
  }

  @override
  void dispose() {
    _nombreLigaController.dispose();
    _nombreEquipoController.dispose();
    super.dispose();
  }

  Future<void> _cargarCompeticiones() async {
    try {
      final competiciones = await ApiService.getCompeticiones();
      setState(() {
        _competiciones = competiciones;
        _cargandoCompeticiones = false;
      });
    } catch (e) {
      setState(() => _cargandoCompeticiones = false);
      _mostrarError('Error al cargar competiciones: $e');
    }
  }

  Future<void> _crearLiga() async {
    if (!_formKey.currentState!.validate()) return;
    if (_competicionSeleccionada == null) {
      _mostrarError('Por favor selecciona una competición');
      return;
    }

    setState(() => _cargando = true);

    try {
      final response = await ApiService.crearLiga(
        nombre: _nombreLigaController.text.trim(),
        competicionId: _competicionSeleccionada!,
        nombreEquipo: _nombreEquipoController.text.trim(),
        maxParticipantes: _maxParticipantes,
        presupuestoInicial: _presupuestoInicial,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¡Liga creada!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Liga: ${response['liga']['nombre']}'),
                const SizedBox(height: 8),
                Text(
                  'Código de invitación:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    response['codigo_invitacion'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Comparte este código con tus amigos para que se unan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo
                  Navigator.pop(context); // Volver a home
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _mostrarError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Liga'),
      ),
      body: _cargandoCompeticiones
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nombre de la liga
                    TextFormField(
                      controller: _nombreLigaController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la Liga',
                        hintText: 'Ej: Liga de Amigos 2026',
                        prefixIcon: Icon(Icons.emoji_events),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nombre del equipo
                    TextFormField(
                      controller: _nombreEquipoController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de tu Equipo',
                        hintText: 'Ej: Los Galácticos',
                        prefixIcon: Icon(Icons.shield),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa un nombre para tu equipo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Selector de competición
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Competición Base',
                        prefixIcon: Icon(Icons.sports_soccer),
                        border: OutlineInputBorder(),
                      ),
                      value: _competicionSeleccionada,
                      items: _competiciones.map((comp) {
                        return DropdownMenuItem<int>(
                          value: comp['id'],
                          child: Row(
                            children: [
                              Text(comp['nombre']),
                              const SizedBox(width: 8),
                              Text(
                                '(${comp['pais']})',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _competicionSeleccionada = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor selecciona una competición';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Configuración avanzada
                    Text(
                      'Configuración Avanzada',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Máximo de participantes
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Máximo de participantes'),
                                Text(
                                  '$_maxParticipantes',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _maxParticipantes.toDouble(),
                              min: 2,
                              max: 20,
                              divisions: 18,
                              label: '$_maxParticipantes',
                              onChanged: (value) {
                                setState(() => _maxParticipantes = value.toInt());
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Presupuesto inicial
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Presupuesto inicial'),
                                Text(
                                  '${_presupuestoInicial.toStringAsFixed(0)}M',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _presupuestoInicial,
                              min: 50,
                              max: 200,
                              divisions: 30,
                              label: '${_presupuestoInicial.toStringAsFixed(0)}M',
                              onChanged: (value) {
                                setState(() => _presupuestoInicial = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón crear
                    ElevatedButton(
                      onPressed: _cargando ? null : _crearLiga,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _cargando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Crear Liga',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}