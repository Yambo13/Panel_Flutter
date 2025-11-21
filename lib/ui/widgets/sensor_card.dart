// lib/ui/widgets/sensor_card.dart
import 'package:flutter/material.dart';
import 'package:agro/models/sensor_data.dart';

class SensorCard extends StatelessWidget {
  final SensorData sensor;

  const SensorCard({super.key, required this.sensor});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              sensor.id,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _IconValue(
                  icon: Icons.thermostat_outlined,
                  value: '${sensor.temperatura.toStringAsFixed(1)}°C',
                  color: Colors.redAccent,
                ),
                _IconValue(
                  icon: Icons.water_drop_outlined,
                  value: '${sensor.humedad.toStringAsFixed(1)}%',
                  color: Colors.blueAccent,
                ),
                _IconValue(
                  icon: Icons.lightbulb_outline,
                  value: '${sensor.luminosidad.toStringAsFixed(0)} lx',
                  color: Colors.orangeAccent,
                ),
                _IconValue(
                  icon: Icons.battery_full,
                  value: '${sensor.bateria.toStringAsFixed(1)}%',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconValue extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _IconValue({
    required this.icon,
    required this.value,
    this.color = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 26, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
