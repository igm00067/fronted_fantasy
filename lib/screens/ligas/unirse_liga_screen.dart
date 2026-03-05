import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class UnirseLigaScreen extends StatefulWidget {
  const UnirseLigaScreen({Key? key}) : super(key: key);

  @override
  State<UnirseLigaScreen> createState() => _UnirseLigaScreenState();
}

class _UnirseLigaScreenState extends State<UnirseLigaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _nombreEquipoController = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreEquipoController.dispose();
    super.dispose();
  }

  Future<void> _unirse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final response = await ApiService.unirseALiga(
        codigoInvitacion: _codigoController.text.trim().toUpperCase(),
        nombreEquipo: _nombreEquipoController.text.trim(),
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¡Te has unido!'),
            content: Text(
              'Te has unido exitosamente a: ${response['liga']['nombre']}',
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unirse a Liga'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ilustración o icono
              Icon(
                Icons.group_add,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),

              // Descripción
              Text(
                'Ingresa el código de invitación que te compartió el creador de la liga',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Código de invitación
              TextFormField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  labelText: 'Código de Invitación',
                  hintText: 'Ej: ABC12345',
                  prefixIcon: Icon(Icons.key),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el código';
                  }
                  if (value.length < 6) {
                    return 'El código debe tener al menos 6 caracteres';
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
                  hintText: 'Ej: Mi Dream Team',
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
              const SizedBox(height: 32),

              // Botón unirse
              ElevatedButton(
                onPressed: _cargando ? null : _unirse,
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
                        'Unirse a la Liga',
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