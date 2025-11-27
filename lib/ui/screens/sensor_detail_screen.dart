// lib/ui/screens/dashboard_screen.dart
import 'package:flutter/material.dart';



class SensorDetailScreen extends StatefulWidget {
  final Map<String, dynamic> sensorData;

  const SensorDetailScreen({super.key, required this.sensorData});

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  double _limiteAlarma = 5.0; //Estado local para el límite de alarma

  @override
  Widget build(BuildContext context) {
    final data = widget.sensorData;

    return Scaffold(
      appBar: AppBar(
        title: Text("Detalle del Sensor ${widget.sensorData['id']}"),
        backgroundColor: Colors.blue[50],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation:4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text("Valores en tiempo real", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const SizedBox(height:10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoColumn( icon: Icons.thermostat, label: "Temperatura", value: "${widget.sensorData['temperatura']} °C"),
                        const _InfoColumn( icon: Icons.water_drop, label: "Humedad", value: "45 %"),
                        const _InfoColumn( icon: Icons.wb_sunny, label: "Luminosidad", value: "300 lx"),
                        const _InfoColumn( icon: Icons.battery_full, label: "Batería", value: "85 %"),
                        const _InfoColumn( icon: Icons.speed, label: "Vibración", value: "2.4 mm/s"),
                      ]
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Sección de Gráficas (Placeholder)
            const Text("Histórico de Datos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.show_chart, size: 50, color: Colors.grey),
                    Text("[Aquí irán las Gráficas detalladas]"),
                  ],
                ),
              )
            ),
            
            const SizedBox(height: 24),
            // 3. Configuración de Alarmas
            const Text("Configuración de Alarmas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text("Nivel de Alerta para Vibración", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _limiteAlarma,
                          min: 0,
                          max: 10,
                          divisions: 100,
                          label: _limiteAlarma.toStringAsFixed(1),
                          activeColor: Colors.deepOrange,
                          onChanged: (value) {
                            setState(() {
                              _limiteAlarma = value;
                            });
                          },
                        ),
                      ),
                      Text("${_limiteAlarma.toStringAsFixed(1)} mm/s", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Alarma configurada en ${_limiteAlarma.toStringAsFixed(1)} mm/s para ${widget.sensorData['id']}")),
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text("Guardar Configuración"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  )
                ],
              ),
            ),
          ),        
        ],
      ),   
    ),  
  );
}
}

class _InfoColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoColumn({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blueGrey),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
  
