// lib/ui/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Importamos la librería de gráficas
import 'package:agro/services/influx_services.dart';
import 'dart:math'; // Para generar datos aleatorios

class SensorDetailScreen extends StatelessWidget {
  final Map<String, dynamic> sensorData;

  const SensorDetailScreen({super.key, required this.sensorData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sensorData['id']),
        backgroundColor: Colors.blue[50],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tarjeta de Resumen (Datos actuales estáticos)
            _buildSummaryCard(),
            
            const SizedBox(height: 24),
            const Text("Análisis de Vibraciones y Espectro", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // 2. LAS 4 GRÁFICAS SOLICITADAS
            // Cada una es independiente y tiene su propia alarma
            const _SensorChartCard(
              title: "Frequency Spectrum",
              lineColor: Colors.purple,
              yAxisLabel: "Magnitud (dB)",
              maxX: 100, // Eje X hasta 100 Hz
            ),
            const _SensorChartCard(
              title: "Peak Velocity Sensor",
              lineColor: Colors.green,
              yAxisLabel: "Velocidad (mm/s)",
            ),
            const _SensorChartCard(
              title: "Radial Bearing RMS Velocity",
              lineColor: Colors.orange,
              yAxisLabel: "Velocidad RMS (mm/s)",
            ),
            const _SensorChartCard(
              title: "Radial Bearing Peak Acceleration",
              lineColor: Colors.redAccent,
              yAxisLabel: "Aceleración (G)",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Estado Actual", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoColumn(icon: Icons.thermostat, label: "Temp", value: "${sensorData['val']}°C"),
                const _InfoColumn(icon: Icons.water_drop, label: "Humedad", value: "45%"),
                const _InfoColumn(icon: Icons.speed, label: "RMS", value: "2.4"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGET REUTILIZABLE PARA CADA GRÁFICA
// Incluye la gráfica y su configuración de alarma propia
// ---------------------------------------------------------------------------
class _SensorChartCard extends StatefulWidget {
  final String title;
  final Color lineColor;
  final String yAxisLabel;
  final double maxX;

  final String sensorId;
  final String fieldName;


  const _SensorChartCard({
    required this.title,
    required this.lineColor,
    required this.yAxisLabel,
    this.maxX = 10, // Por defecto 10 unidades de tiempo/muestra
  });

  @override
  State<_SensorChartCard> createState() => _SensorChartCardState();
}

class _SensorChartCardState extends State<_SensorChartCard> {
  double _alarmThreshold = 8.0; // Valor inicial de la alarma para esta gráfica
  late List<FlSpot> _dummyData;

  @override
  void initState() {
    super.initState();
    _dummyData = _generateRandomData();
  }

  // Generador de datos falsos para visualizar la gráfica ahora
  List<FlSpot> _generateRandomData() {
    final Random random = Random();
    return List.generate(11, (index) {
      double yVal = random.nextDouble() * 10; // Valor entre 0 y 10
      return FlSpot(index * (widget.maxX / 10), yVal);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la Gráfica
            Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.yAxisLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            
            const SizedBox(height: 20),

            // GRÁFICA (fl_chart)
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 12, // Un poco más que el max random (10) para margen
                  minX: 0,
                  maxX: widget.maxX,
                  // LÍNEA DE ALARMA (Horizontal roja)
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: _alarmThreshold,
                        color: Colors.red.withOpacity(0.8),
                        strokeWidth: 2,
                        dashArray: [5, 5], // Línea punteada
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10),
                          labelResolver: (line) => "Límite: ${line.y.toStringAsFixed(1)}",
                        ),
                      ),
                    ],
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _dummyData,
                      isCurved: true,
                      color: widget.lineColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: widget.lineColor.withOpacity(0.2), // Relleno suave debajo
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),
            const Divider(),

            // CONFIGURACIÓN DE ALARMA
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined, color: Colors.grey),
                const SizedBox(width: 8),
                const Text("Configurar Alarma eje Y:", style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _alarmThreshold,
                    min: 0,
                    max: 12,
                    divisions: 24,
                    activeColor: Colors.redAccent,
                    label: _alarmThreshold.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _alarmThreshold = value;
                      });
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _alarmThreshold.toStringAsFixed(1),
                    style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para columnas de info (el mismo de antes)
class _InfoColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoColumn({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.blueGrey, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}