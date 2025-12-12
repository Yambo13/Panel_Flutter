// lib/ui/screens/dashboard_screen.dart
// import 'package:flutter/material.dart';
// import 'package:agro/ui/screens/dashboard_screen.dart';




// class LoginScreen extends StatefulWidget{
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();

// }


// class _LoginScreenState extends State<LoginScreen>{
//   @override
//   final _userController = TextEditingController();
//   final _passwordController = TextEditingController();

//   void _login(){
//     final username = _userController.text;
//     final password = _passwordController.text;

//     // Aquí puedes agregar la lógica de autenticación
//     if( username.isNotEmpty && password.isNotEmpty){
//       // Navegar a la pantalla del dashboard
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const DashboardScreen()),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Por favor, ingrese usuario y contraseña")),
//       );
//     }
//   }

//   @override
//   Widget build (BuildContext context){
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Image.asset(
//                 'assets/qartia_full_logo.jpg',
//                 width: 250,
//                 height: 250,
//                 fit: BoxFit.contain,
//               ),
//               const SizedBox(height: 20),
//               const Text( 
//                 "Bienvenido a Qartia Visual Sensor Dashboard",
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
//               ),
//               const SizedBox(height: 40),

//               TextField(
//                 controller: _userController,
//                 decoration: const InputDecoration(
//                   labelText: "Usuario",
//                   border: OutlineInputBorder(),
//                   prefixIcon: Icon(Icons.person)
//                 ),
//               ),
//               const SizedBox(height: 16.0),
//               TextField(
//                 controller: _passwordController,
//                 decoration: const InputDecoration(
//                   labelText: "Contraseña",
//                   border: OutlineInputBorder(),
//                   prefixIcon: Icon(Icons.lock),
//                 ),
//                 obscureText: true,
//               ),
//               const SizedBox(height: 24.0),
//               ElevatedButton(
//                 onPressed: _login,
//                 child: const Text("Iniciar Sesión"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
// }

// }