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
     useMaterial3: true,
     colorScheme: ColorScheme.fromSeed(
       seedColor: const Color(0xFF1E88E5),
       brightness: Brightness.light,
     ),
     //Aquí se pueden personalizar ewstilos globales de texto o botones
     ),
     home: const LoginScreen(),
     // Pantalla de logeo
   );
 }
}


