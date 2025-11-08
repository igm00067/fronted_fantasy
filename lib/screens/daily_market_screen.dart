import 'package:flutter/material.dart';


class DailyMarketScreen extends StatelessWidget {
  const DailyMarketScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Mercado del Día',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Descubre jugadores destacados',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}