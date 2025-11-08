import 'package:flutter/material.dart';
import 'my_leagues_screen.dart';
import 'rankings_screen.dart';
import 'my_team_screen.dart';
import 'daily_market_screen.dart';
import 'activity_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Lista de pantallas
  final List<Widget> _screens = [
    const MyLeaguesScreen(),
    const RankingsScreen(),
    const MyTeamScreen(),
    const DailyMarketScreen(),
    const ActivityScreen(),
  ];

  // Lista de títulos para el AppBar
  final List<String> _titles = [
    'Mis Ligas',
    'Clasificación',
    'Mi Equipo',
    'Mercado del Día',
    'Actividad',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Abrir notificaciones
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
  currentIndex: _selectedIndex,
  onTap: (index) {
    setState(() {
      _selectedIndex = index;
    });
  },
  selectedItemColor: const Color(0xFF38003C),  // Color morado cuando está seleccionado
  unselectedItemColor: Colors.grey[700],        // Gris oscuro cuando NO está seleccionado
  selectedFontSize: 12,
  unselectedFontSize: 11,
  type: BottomNavigationBarType.fixed,
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.emoji_events),
      label: 'Mis Ligas',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.leaderboard),
      label: 'Clasificación',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.groups),
      label: 'Mi Equipo',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_bag),
      label: 'Mercado',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart),
      label: 'Actividad',
    ),
  ],
),
    );
  }
}