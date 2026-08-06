// ─────────────────────────────────────────────────────────────────────────────
// main.dart — Punto de entrada de la aplicación Flutter
//
// Configura el tema oscuro, inicializa los providers de estado global
// y decide qué pantalla mostrar según el estado de autenticación.
//
// Árbol de widgets:
//   MyApp
//   └── MultiProvider (inyecta los 3 providers globales)
//       └── MaterialApp (tema oscuro, sin banner de debug)
//           └── Consumer<AuthProvider> (observa cambios de sesión)
//               ├── CircularProgressIndicator  (mientras verifica el token)
//               ├── HomeScreen                 (si autenticado)
//               └── LoginScreen                (si no autenticado)
//
// Providers globales:
//   AuthProvider   — sesión del usuario (login/logout/registro)
//   LigasProvider  — lista de ligas del usuario (mis-ligas)
//   MercadoProvider — estado del mercado (no usado globalmente aún)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/ligas_provider.dart';
import 'providers/mercado_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'config/app_theme.dart';

void main() async {
  // Necesario antes de usar plugins nativos (SharedPreferences, notificaciones, etc.)
  WidgetsFlutterBinding.ensureInitialized();

  // Barra de estado transparente con iconos claros (estética dark theme)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthProvider se crea primero porque verifica el JWT al instanciarse
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LigasProvider()),
        ChangeNotifierProvider(create: (_) => MercadoProvider()),
      ],
      child: MaterialApp(
        title: 'Fantasy Football Manager',
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        // Consumer escucha cambios en AuthProvider y redirige automáticamente
        // cuando el usuario inicia o cierra sesión.
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Mientras AuthProvider verifica el JWT guardado → spinner
            if (authProvider.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // JWT válido → ir a la pantalla principal
            if (authProvider.isAuthenticated) {
              return const HomeScreen();
            }

            // Sin sesión → pantalla de login/registro
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}