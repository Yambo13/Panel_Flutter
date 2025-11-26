// lib/ui/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:agro/services/influx_services.dart';
import 'package:agro/models/sensor_data.dart';
import 'package:agro/ui/widgets/sensor_card.dart';
import 'package:agro/ui/screens/login_screen.dart';
import 'package:agro/ui/screens/dashboard_screen.dart';
/*
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // Simple placeholder UI for the dashboard; replace with your actual implementation.
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: const Center(child: Text("Dashboard content goes here")),
    );
  }
}
*/



class LoginScreen extends StatefulWidget{
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();

}

/*
class _LoginScreenState extends State<LoginScreen>{
  @override
  Widget build (BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text("Login Screen")),
      body: Center(
        child: Text("This is the login screen"),
      ),
    );
  }
} */

class _LoginScreenState extends State<LoginScreen>{
  @override
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login(){
    final username = _userController.text;
    final password = _passwordController.text;

    // Aquí puedes agregar la lógica de autenticación
    if( username.isNotEmpty && password.isNotEmpty){
      // Navegar a la pantalla del dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, ingrese usuario y contraseña")),
      );
    }
  }

  @override
  Widget build (BuildContext context){
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.agriculture, size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              const Text( 
                "Bienvenido a AgroNext",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _userController,
                decoration: const InputDecoration(
                  labelText: "Usuario",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person)
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _login,
                child: const Text("Iniciar Sesión"),
              ),
            ],
          ),
        ),
      ),
    );
}




}