// lib/ui/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:agro/services/influx_services.dart';
import 'package:agro/models/sensor_data.dart';
import 'package:agro/ui/widgets/sensor_card.dart';

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
