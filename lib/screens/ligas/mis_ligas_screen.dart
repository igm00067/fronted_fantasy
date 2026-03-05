import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'detalle_liga_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MisLigasScreen extends StatefulWidget {
  const MisLigasScreen({Key? key}) : super(key: key);

  @override
  State<MisLigasScreen> createState() => _MisLigasScreenState();
}

class _MisLigasScreenState extends State<MisLigasScreen> {
  List<dynamic> _ligas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarLigas();
  }

  Future<void> _cargarLigas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final ligas = await ApiService.getMisLigas();
      setState(() {
        _ligas = ligas;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _navegarADetalleLiga(Map<String, dynamic> liga) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Recargar datos completos de la liga
      final authHeaders = await ApiService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/ligas/${liga['id']}'),
        headers: authHeaders,
      );

      if (mounted) {
        Navigator.pop(context); // Cerrar loading
      }

      if (response.statusCode == 200) {
        final ligaCompleta = jsonDecode(response.body);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleLigaScreen(liga: ligaCompleta),
            ),
          );
        }
      } else {
        throw Exception('Error al cargar liga');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
        title: const Text('Mis Ligas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarLigas,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 60, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar ligas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!.replaceAll('Exception: ', ''),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _cargarLigas,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _ligas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tienes ligas',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crea una nueva o únete con un código',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _ligas.length,
                      itemBuilder: (context, index) {
                        final liga = _ligas[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                liga['nombre'][0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              liga['nombre'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Código: ${liga['codigo_invitacion']}'),
                                Text(
                                  'Participantes: ${liga['num_participantes']}/${liga['max_participantes']}',
                                ),
                                Text(
                                  'Presupuesto: ${liga['presupuesto_inicial']}M',
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _navegarADetalleLiga(liga),
                          ),
                        );
                      },
                    ),
    );
  }
}