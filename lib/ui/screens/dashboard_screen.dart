// lib/ui/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:agro/services/influx_services.dart';
import 'package:agro/models/sensor_data.dart';
import 'package:agro/ui/widgets/sensor_card.dart';
import 'package:agro/ui/screens/sensor_detail_screen.dart';



class DashboardScreen extends StatefulWidget{
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>{
  
  final List<Map<String, dynamic>> maquinas = [
   {
      "nombre": "Moto-Bomba Norte",
      "estado": "Activa",
      "sensores": [
        {"id": "Sensor_motor_1", "temperatura": 23.5, "humedad": 45.0, "luminosidad": 300.0, "bateria": 85.0},
        {"id": "Sensor_motor_2", "temperatura": 24.0, "humedad": 50.0, "luminosidad": 320.0, "bateria": 80.0},
        {"id": "Sensor_bomba_1", "temperatura": 23.5, "humedad": 45.0, "luminosidad": 300.0, "bateria": 85.0},
        {"id": "Sensor_bomba_2", "temperatura": 24.0, "humedad": 50.0, "luminosidad": 320.0, "bateria": 80.0},
      ]
   },
   {
    "nombre": "Moto-Bomba Sur",
    "estado": "Mantenimiento",
    "sensores": [
      {"id": "Sensor_motor_1", "temperatura": 22.5, "humedad": 40.0, "luminosidad": 280.0, "bateria": 90.0},
      {"id": "Sensor_motor_2", "temperatura": 23.0, "humedad": 42.0, "luminosidad": 290.0, "bateria": 88.0},
      {"id": "Sensor_bomba_1", "temperatura": 22.5, "humedad": 40.0, "luminosidad": 280.0, "bateria": 90.0},
      {"id": "Sensor_bomba_2", "temperatura": 23.0, "humedad": 42.0, "luminosidad": 290.0, "bateria": 88.0},
    ]
   },
  ];

  @override
  Widget build (BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de control de Sensores"),
        backgroundColor: const Color.fromARGB(255, 46, 154, 231),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              //volver al login 
              Navigator.of(context).pushReplacementNamed('/');
            },
          )
        ],
    ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: maquinas.length,
        itemBuilder: (context, index){
          final maquina = maquinas[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ExpansionTile(
              collapsedBackgroundColor: Colors.blue[50],
              leading: const Icon(Icons.settings_suggest, size: 30),
              title: Text(
                maquina["nombre"],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text("Estado: ${maquina["estado"]}"),
              children: [
                //Lista de sensores para esta maquina
                ...(maquina["sensores"] as List).map((sensor) {
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        leading: const Icon(Icons.sensors, color: Colors.blueGrey),
                        title: Text(
                          sensor["id"], 
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize:  15),
                        ),
                        subtitle: Text(
                          "Temp: ${sensor["temperatura"]}°C, Humedad: ${sensor["humedad"]}%, Luminosidad: ${sensor["luminosidad"]} lx, Batería: ${sensor["bateria"]}%",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          // Navegar a la pantalla de detalles del sensor
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SensorDetailScreen(sensorData: sensor as Map<String, dynamic>),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 20, endIndent: 20), //Linea separadora fina
                    ],
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

}      