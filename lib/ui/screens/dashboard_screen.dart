// lib/ui/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:agro/services/influx_services.dart';
import 'package:agro/models/sensor_data.dart';
import 'package:agro/ui/widgets/sensor_card.dart';

/*
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}


class _DashboardScreenState extends State<DashboardScreen> {
  final influxService = InfluxService();

  final Map<String, String> sensors = {
    "Sensor_10": "a8610a3432286110",
    "Sensor_11": "a8610a3539407c08",
    "Sensor_12": "a8610a343238650e",
    "Sensor_13": "a8610a34363d860f",
    "Sensor_14": "a8610a33342b9316",
    "Sensor_15": "a8610a3436208816",
    "Sensor_16": "a8610a3234327704",
    "Sensor_17": "a8610a3539466c05",
    "Sensor_18": "a8610a343236640a",
    "Sensor_19": "a8610a33342e9315",
  };

  Future<List<SensorData>> fetchAllSensorData() async {
    List<SensorData> sensorDataList = [];

    for (var entry in sensors.entries) {
      final id = entry.key;
      final topic = entry.value;

      final temperatura = await influxService.getLatestSensorData(topic, "object_temperatura") ?? 0;
      final humedad = await influxService.getLatestSensorData(topic, "object_humedadSuelo") ?? 0;
      final luminosidad = await influxService.getLatestSensorData(topic, "object_luminosidad") ?? 0;
      final bateria = await influxService.getLatestSensorData(topic, "object_bateria") ?? 0;

      sensorDataList.add(SensorData(
        id: id,
        temperatura: temperatura,
        humedad: humedad,
        luminosidad: luminosidad,
        bateria: bateria,
      ));
    }

    return sensorDataList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panel de Sensores")),
      body: FutureBuilder<List<SensorData>>(
        future: fetchAllSensorData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sensores = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              itemCount: sensores.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // Puedes ajustar a 3 si quieres más compactado
                childAspectRatio: 0.9,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                return SensorCard(sensor: sensores[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
*/

class DashboardScreen extends StatefulWidget{
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>{
  
  final List<Map<String, dynamic>> sensores = [
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
        itemCount: sensores.length,
        itemBuilder: (context, index){
          final sensorGroup = sensores[index];
          return ExpansionTile(
            title: Text(sensorGroup["nombre"]),
            subtitle: Text("Estado: ${sensorGroup["estado"]}"),
            children: (sensorGroup["sensores"] as List<Map<String, dynamic>>).map((sensor) {
              return ListTile(
                title: Text(sensor["id"]),
                subtitle: Text(
                  "Temp: ${sensor["temperatura"]}°C, Humedad: ${sensor["humedad"]}%, Luminosidad: ${sensor["luminosidad"]} lx, Batería: ${sensor["bateria"]}%"
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _SensorDetailTile extends StatefulWidget {
  final Map<String, dynamic> sensorData;

  const _SensorDetailTile({required this.sensorData});

  @override
  State<_SensorDetailTile> createState() => _SensorDetailTileState();
}

class _SensorDetailTileState extends State<_SensorDetailTile> {
  double _limiteAlarma = 5.0; // Valor por defecto para la alarma

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.sensors, color: Colors.blueGrey),
      title: Text(widget.sensorData['id']), // Nombre del Sensor
      subtitle: Text("${widget.sensorData['tipo']} - Valor actual: ${widget.sensorData['val']}"),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Configuración de Alarma (Radial Bearing RMS)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text("Nivel de Alerta: "),
                  Expanded(
                    child: Slider(
                      value: _limiteAlarma,
                      min: 0,
                      max: 10,
                      divisions: 100,
                      label: _limiteAlarma.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _limiteAlarma = value;
                        });
                      },
                    ),
                  ),
                  Text(_limiteAlarma.toStringAsFixed(1)),
                ],
              ),
              const SizedBox(height: 10),
              // Aquí irían tus GRÁFICAS en el futuro
              Container(
                height: 150,
                color: Colors.grey[200],
                child: const Center(child: Text("[Espacio reservado para Gráficas]")),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Alarma configurada en $_limiteAlarma para ${widget.sensorData['id']}")),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text("Guardar Configuración"),
              )
            ],
          ),
        ),
      ],
    );
  }
}