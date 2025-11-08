// lib/screens/my_team_screen.dart

import 'package:flutter/material.dart';

// Definir colores directamente aquí
const Color kPrimaryColor = Color(0xFF38003C);

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({Key? key}) : super(key: key);

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Información superior
        Container(
          color: kPrimaryColor,  // Cambiado
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'FICHAS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '19/24',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: const [
                      Text(
                        'JORNADA 9',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• 17/10 21.00h',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text(
                        'VALOR EQUIPO',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '€599.666.569',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        // TabBar
        Container(
          color: Colors.grey[900],
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.red,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'Alineación'),
              Tab(text: 'Plantilla'),
              Tab(text: 'Puntos'),
            ],
          ),
        ),
        // Contenido de las tabs
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              AlineacionTab(),
              PlantillaTab(),
              PuntosTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================
// TAB 1: ALINEACIÓN (Campo de fútbol)
// ============================================

class AlineacionTab extends StatelessWidget {
  const AlineacionTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green[800]!,
            Colors.green[600]!,
          ],
        ),
      ),
      child: Column(
        children: [
          // Formación y Capitán
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        '4 · 3 · 3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.shield, size: 18),
                  label: const Text('Asignar capitán'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,  // Cambiado
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          // Campo de juego
          Expanded(
            child: Stack(
              children: [
                // Líneas del campo
                CustomPaint(
                  size: Size.infinite,
                  painter: FieldPainter(),
                ),
                // Jugadores
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Portero
                    _PlayerRow(players: [
                      _PlayerData('A. Batalla', 'VAL', hasCheck: true),
                    ]),
                    // Defensas
                    _PlayerRow(players: [
                      _PlayerData('Eric', 'BAR', hasCheck: true),
                      _PlayerData('R.P. Bigas', 'ELC', hasCheck: true),
                      _PlayerData('Bellerin', 'BET', hasCheck: true),
                      _PlayerData('E. Militão', 'RMA', hasCheck: true),
                    ]),
                    // Medios
                    _PlayerRow(players: [
                      _PlayerData('Jauregiz...', 'ATH', hasCheck: true),
                      _PlayerData('Tchoua...', 'RMA', hasCheck: true),
                      _PlayerData('Hugo Sot...', 'CEL', hasCheck: true),
                    ]),
                    // Delanteros
                    _PlayerRow(players: [
                      _PlayerData('Pere Milla', 'ESP', hasCheck: true),
                      _PlayerData('Mbappé', 'RMA', hasCheck: true),
                      _PlayerData('Ez Abde', 'BET', hasCheck: true),
                    ]),
                  ],
                ),
              ],
            ),
          ),
          // Mensaje inferior
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ALINEACIÓN GUARDADA EL 17/10/2025 a las 07:38:42',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final List<_PlayerData> players;

  const _PlayerRow({required this.players});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: players.map((player) => _PlayerCard(player: player)).toList(),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final _PlayerData player;

  const _PlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Foto del jugador
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  'https://via.placeholder.com/70',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person, size: 40, color: Colors.white);
                  },
                ),
              ),
            ),
            // Escudo del equipo (esquina superior derecha)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Center(
                  child: Text(
                    player.team,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Check verde (esquina inferior derecha)
            if (player.hasCheck)
              Positioned(
                bottom: -5,
                right: -5,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Nombre
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            player.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _PlayerData {
  final String name;
  final String team;
  final bool hasCheck;

  _PlayerData(this.name, this.team, {this.hasCheck = false});
}

// Painter para dibujar las líneas del campo
class FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Línea del medio
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Círculo central
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      40,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================
// TAB 2: PLANTILLA (Lista de jugadores)
// ============================================

class PlantillaTab extends StatelessWidget {
  const PlantillaTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'PORTEROS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        _PlayerListItem(
          name: 'A. Batalla',
          team: 'Valencia',
          price: '€12.5M',
          image: 'https://via.placeholder.com/50',
        ),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'DEFENSAS',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        _PlayerListItem(
          name: 'Eric García',
          team: 'Barcelona',
          price: '€15.2M',
          image: 'https://via.placeholder.com/50',
        ),
        _PlayerListItem(
          name: 'R.P. Bigas',
          team: 'Elche',
          price: '€8.5M',
          image: 'https://via.placeholder.com/50',
        ),
        _PlayerListItem(
          name: 'Bellerín',
          team: 'Betis',
          price: '€10.3M',
          image: 'https://via.placeholder.com/50',
        ),
        _PlayerListItem(
          name: 'E. Militão',
          team: 'Real Madrid',
          price: '€18.7M',
          image: 'https://via.placeholder.com/50',
        ),
      ],
    );
  }
}

class _PlayerListItem extends StatelessWidget {
  final String name;
  final String team;
  final String price;
  final String image;

  const _PlayerListItem({
    required this.name,
    required this.team,
    required this.price,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(image),
        backgroundColor: Colors.grey[300],
        onBackgroundImageError: (exception, stackTrace) {},
        child: const Icon(Icons.person),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(team),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            price,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// TAB 3: PUNTOS (Campo con círculos de puntos)
// ============================================

class PuntosTab extends StatelessWidget {
  const PuntosTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green[800]!,
            Colors.green[600]!,
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Campo de juego con puntos
          Expanded(
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: FieldPainter(),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PlayerPointsRow(players: [
                      _PlayerPointsData('A. Batalla', 'VAL', 8),
                    ]),
                    _PlayerPointsRow(players: [
                      _PlayerPointsData('Eric', 'BAR', 12),
                      _PlayerPointsData('R.P. Bigas', 'ELC', 6),
                      _PlayerPointsData('Bellerin', 'BET', 9),
                      _PlayerPointsData('E. Militão', 'RMA', 15),
                    ]),
                    _PlayerPointsRow(players: [
                      _PlayerPointsData('Jauregizar', 'ATH', 7),
                      _PlayerPointsData('Tchouameni', 'RMA', 10),
                      _PlayerPointsData('Hugo Soto', 'CEL', 5),
                    ]),
                    _PlayerPointsRow(players: [
                      _PlayerPointsData('Pere Milla', 'ESP', 14),
                      _PlayerPointsData('Mbappé', 'RMA', 22),
                      _PlayerPointsData('Ez Abde', 'BET', 11),
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerPointsRow extends StatelessWidget {
  final List<_PlayerPointsData> players;

  const _PlayerPointsRow({required this.players});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: players.map((player) => _PlayerPointsCard(player: player)).toList(),
      ),
    );
  }
}

class _PlayerPointsCard extends StatelessWidget {
  final _PlayerPointsData player;

  const _PlayerPointsCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  'https://via.placeholder.com/70',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person, size: 40, color: Colors.white);
                  },
                ),
              ),
            ),
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: Center(
                  child: Text(
                    player.team,
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            // Círculo de puntos
            Positioned(
              bottom: -8,
              right: -8,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getPointsColor(player.points),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${player.points}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            player.name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Color _getPointsColor(int points) {
    if (points >= 15) return Colors.green[700]!;
    if (points >= 10) return Colors.orange[700]!;
    return Colors.red[700]!;
  }
}

class _PlayerPointsData {
  final String name;
  final String team;
  final int points;

  _PlayerPointsData(this.name, this.team, this.points);
}