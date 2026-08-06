// ─────────────────────────────────────────────────────────────────────────────
// screens/auth/login_screen.dart — Pantalla de login y registro
//
// Pantalla única que alterna entre dos modos:
//   Modo LOGIN    (_isLogin=true)   → campos email + contraseña
//   Modo REGISTRO (_isLogin=false)  → campos nombre + email + contraseña
//
// Flujo de login exitoso:
//   1. _submit() → AuthProvider.login() → ApiService.login()
//   2. login guarda el JWT en SharedPreferences
//   3. AuthProvider.notifyListeners() → Consumer<AuthProvider> en main.dart
//   4. Consumer redirige automáticamente a HomeScreen (sin Navigator.push)
//   5. SocketService.connect() establece conexión WebSocket con el JWT
//
// Flujo de registro exitoso:
//   1. _submit() → AuthProvider.register() → POST /api/auth/register
//   2. El backend envía email de verificación
//   3. Se muestra _registracionExitosa=true con banner informativo
//   4. El usuario debe verificar su email antes de poder hacer login
//
// Manejo de email no verificado:
//   Si el backend devuelve codigo='email_no_verificado', se muestra un banner
//   naranja con botón "Reenviar correo" → _reenviarVerificacion()
//
// Recuperación de contraseña:
//   _mostrarDialogoRecuperacion() abre AlertDialog con campo email
//   → POST /api/auth/forgot-password → el backend envía email con enlace
//   El enlace abre un formulario HTML en el backend (no en la app móvil)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api/auth_api.dart';
import '../../services/socket_service.dart';
import '../../config/app_theme.dart';

/// Pantalla de entrada a la app. Muestra login o registro según _isLogin.
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _forgotEmailController = TextEditingController(); // pre-rellena con el email del campo principal

  bool _isLogin = true;           // true=login, false=registro
  bool _isLoading = false;        // bloquea el botón mientras la petición está en curso
  bool _obscurePassword = true;   // toggle para ver/ocultar contraseña
  bool _registracionExitosa = false; // muestra banner verde tras registrarse
  String _emailRegistrado = '';      // email mostrado en el banner de registro exitoso
  String _emailNoVerificado = '';    // email del usuario que intentó loguear sin verificar

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  /// Valida el formulario y ejecuta login o registro según el modo actual.
  /// En modo login: autentica y conecta el socket si tiene éxito.
  /// En modo registro: registra y muestra el banner informativo.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_isLogin) {
        setState(() => _emailNoVerificado = ''); // limpia banner anterior
        await authProvider.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        // Conectar WebSocket tras login exitoso para recibir eventos en tiempo real
        await SocketService.connect();
      } else {
        await authProvider.register(
          nombre: _nombreController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          setState(() {
            _registracionExitosa = true;
            _emailRegistrado = _emailController.text.trim();
            _isLogin = true;
            _emailController.clear();
            _passwordController.clear();
            _nombreController.clear();
            _formKey.currentState?.reset();
          });
        }
        return;
      }
    } on Exception catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg.startsWith('EMAIL_NO_VERIFICADO:')) {
        final emailSinVerificar = msg.replaceFirst('EMAIL_NO_VERIFICADO:', '');
        if (mounted) setState(() => _emailNoVerificado = emailSinVerificar);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Reenvía el email de verificación al usuario con email no verificado.
  /// Muestra SnackBar verde si tuvo éxito, rojo si hubo error de red o servidor.
  Future<void> _reenviarVerificacion() async {
    try {
      await AuthApi.resendVerification(_emailNoVerificado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correo de verificación reenviado. Revisa tu bandeja de entrada.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
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

  /// Muestra un AlertDialog para solicitar recuperación de contraseña.
  /// Pre-rellena el campo email con lo que el usuario ya había escrito.
  /// El backend envía el enlace de recuperación → /api/auth/forgot-password.
  Future<void> _mostrarDialogoRecuperacion() async {
    _forgotEmailController.text = _emailController.text.trim(); // pre-rellena
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Introduce tu email y te enviaremos las instrucciones para restablecer tu contraseña.',
              style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _forgotEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = _forgotEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Introduce un email válido'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await AuthApi.forgotPassword(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Si el email está registrado, recibirás las instrucciones en breve.'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              } on Exception catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor, AppTheme.backgroundColor],
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sports_soccer,
                      size: 64,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Fantasy Football',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Inicia sesión en tu cuenta' : 'Crea tu cuenta gratis',
                    style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Banner registro exitoso
                  if (_registracionExitosa)
                    _buildBanner(
                      icon: Icons.mark_email_unread,
                      color: Colors.green[700]!,
                      title: '¡Cuenta creada!',
                      message:
                          'Hemos enviado un correo de verificación a $_emailRegistrado. '
                          'Verifica tu cuenta antes de iniciar sesión.',
                    ),

                  // Banner email no verificado
                  if (_emailNoVerificado.isNotEmpty)
                    _buildBannerConAccion(
                      icon: Icons.email_outlined,
                      color: Colors.orange[700]!,
                      title: 'Email no verificado',
                      message:
                          'Debes verificar tu email antes de acceder. '
                          'Revisa tu bandeja de entrada.',
                      actionLabel: 'Reenviar correo de verificación',
                      onAction: _reenviarVerificacion,
                    ),

                  // Formulario
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Campo nombre (solo en registro)
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu nombre';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Campo email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu email';
                            }
                            if (!value.contains('@')) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo contraseña
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu contraseña';
                            }
                            if (!_isLogin && value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),

                        // Olvidé contraseña (solo en login)
                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _mostrarDialogoRecuperacion,
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 24),

                        // Botón submit
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Cambiar entre login y registro
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _registracionExitosa = false;
                              _emailNoVerificado = '';
                              _formKey.currentState?.reset();
                            });
                          },
                          child: Text(
                            _isLogin
                                ? '¿No tienes cuenta? Regístrate'
                                : '¿Ya tienes cuenta? Inicia sesión',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Banner informativo simple (sin botón de acción).
  /// Usado para mostrar el mensaje de "cuenta creada, verifica tu email".
  Widget _buildBanner({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Banner informativo con botón de acción.
  /// Usado para el banner naranja de "email no verificado" con botón "Reenviar correo".
  Widget _buildBannerConAccion({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: color,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
            ),
            child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
