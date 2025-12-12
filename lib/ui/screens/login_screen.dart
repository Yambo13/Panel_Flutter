// lib/ui/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para leer el texto
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Clave para validar el formulario
  final _formKey = GlobalKey<FormState>();
  
  // Estado para mostrar/ocultar contraseña y carga
  bool _isObscure = true;
  bool _isLoading = false;

 void _login() async {
    // 1. Validar que los campos no estén vacíos
    if (_formKey.currentState!.validate()) {
      
      // 2. Activar el indicador de carga
      setState(() => _isLoading = true);
      
      // 3. Simular un tiempo de espera de red (2 segundos)
      // Esto le da realismo y permite ver tu animación de carga
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return; // Seguridad por si la pantalla se cierra antes de terminar

      // 4. Comprobación "Hardcoded" (Fija)
      // AQUÍ es donde cambiarás esto por tu llamada a la API en el futuro
      if (_emailController.text.trim() == 'admin' && 
          _passwordController.text.trim() == '1234') {
        
        // --- ÉXITO ---
        // Navegar a la siguiente pantalla y ELIMINAR el login del historial
        // (Para que al dar 'atrás' no vuelvan al login)
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const DashboardScreen() ),
        );
        
      } else {
        // --- ERROR ---
        setState(() => _isLoading = false);
        
        // Mostrar mensaje de error (SnackBar)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Usuario o contraseña incorrectos'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating, // Flota sobre el fondo
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos el color primario del tema definido en main.dart
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      // Un fondo suave grisáceo para dar contraste a la tarjeta blanca
      backgroundColor: Colors.grey[100], 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            // Limitamos el ancho para que se vea bien en Web/PC
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 4, // Sombra suave
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- LOGOTIPO ---
                      // Usamos el asset que tienes definido en pubspec.yaml
                      Hero(
                        tag: 'logo',
                        child: Image.asset(
                          'assets/qartia_full_logo.jpg', 
                          height: 80, 
                          errorBuilder: (c, o, s) => const Icon(Icons.broken_image, size: 80),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      Text(
                        "Bienvenido",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Monitorización de Motores",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- CAMPO EMAIL/USUARIO ---
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Usuario / Email',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Campo requerido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // --- CAMPO CONTRASEÑA ---
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isObscure,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _isObscure = !_isObscure),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Ingrese su contraseña';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // --- BOTÓN DE LOGIN ---
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton( // FilledButton es el estándar moderno en Material 3
                          onPressed: _isLoading ? null : _login,
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24, 
                                  width: 24, 
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                )
                              : const Text("Ingresar", style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}