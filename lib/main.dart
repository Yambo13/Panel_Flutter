import 'package:flutter/material.dart';
import 'package:agro/ui/screens/login_screen.dart';
// Ensure that the LoginScreen class exists in login_screen.dart and is exported.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Dashboard',
      debugShowCheckedModeBanner: false, //esto es para quitar la etiqueta de debug
      theme: ThemeData( // Tema de la aplicación
        primarySwatch: Colors.blue,
        useMaterial3: true, 
      ),
      home: const LoginScreen(),
      // Pantalla de logeo 
    );
  }
}
