import 'package:flutter/material.dart';


class RankingsScreen extends StatelessWidget {
  const RankingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Pantalla de Clasificación',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Próximamente implementaremos esta sección',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}