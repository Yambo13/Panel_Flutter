// lib/ui/screens/dashboard_screen.dart


// // lib/ui/screens/dashboard_screen.dart
import 'package:agro/models/sensor_data.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Importamos la librería de gráficas
import 'package:agro/services/influx_services.dart';
import 'dart:math'; // Para generar datos aleatorios


//Definicion de colores para las gráficas

// const Color kChartPrimary = Color(0xFF00BFA5);
// const Color kChartSecondary = Color(0xFF2979FF);
// const Color kChartAccent = Color(0xFFEEEEEE);
//  const Color kChartAccent = Color(0xFF9E9E9E);
// const Color kChartAccent = Color(0xFFE53935);





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
            _MultiSensorChartCard(
              title: "Frontal Sushi Sensor - Radial Bearing Peak Acceleration",
              yAxisLabel: "mm/s²",
              //Config de conexion
              measurement: "cartagena-engine",
              filterTag: "topic",  //Topic = sensor_rodamiento_frontal
              sensorId: sensorData['topic_id'] ?? sensorData['id'],

              //Los 3 campos a mostrar
              fieldNames: const [
                'object_X_Axis_PV_Acceleration',
                'object_Y_Axis_PV_Acceleration',
                'object_Z_Axis_PV_Acceleration1'
              ],

              //Colores para cada línea
              lineColors: const [
                Colors.blue,
                Colors.green,
                Colors.orange,
              ],

              //Leyenda
              legendLabels: const ["Eje X", "Eje Y", "Eje Z"],
            ),  
            _SensorChartCard(
              title: "Time Value Payload Sensor",
              lineColor: Colors.green,
              yAxisLabel: "Velocidad (mm/s)",
              measurement: "upct-it2-engine",
              fieldName: 'time_value_payload',
              filterTag: "id",
              sensorId: "12648430",
            ),
            _MultiSensorChartCard(
              title: "Radial Bearing RMS Velocity",
              yAxisLabel: "Velocidad RMS (mm/s)",

              //config de conexion
              measurement: "cartagena-engine",
              filterTag: "topic",  //Topic = sensor_rodamiento_frontal
              sensorId: sensorData['topic_id'] ?? sensorData['id'],

              //Los 3 campos a mostrar
              fieldNames: const [
                'object_X_Axis_PV_Velocity',
                'object_Y_Axis_PV_Velocity',
                'object_Z_Axis_PV_Velocity1'
              ],
              //Colores para cada línea
              lineColors: const [
                Colors.purple,
                Colors.orange,
                Colors.teal,
              ],

              //Leyenda
              legendLabels: const ["Eje X", "Eje Y", "Eje Z"],
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
  final Color  lineColor;
  final String yAxisLabel;
  final double maxX;

  final String sensorId;
  final String measurement;
  final String fieldName;  //Nombre del campo en influxDB
  final String filterTag; //Etiqueta para filtrar (por defecto topic)


  const _SensorChartCard({
    required this.title,
    required this.lineColor,
    required this.yAxisLabel,
    required this.sensorId,
    required this.measurement,
    required this.fieldName,
    this.filterTag = "topic",
    this.maxX = 60, // Por defecto 60 min
  });

  @override
  State<_SensorChartCard> createState() => _SensorChartCardState();
}

class _SensorChartCardState extends State<_SensorChartCard> {
  double _alarmThreshold = 8.0; // Valor inicial de la alarma para esta gráfica
  final InfluxService _influxService = InfluxService(); //Instance de servicio InfluxDB


  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la Gráfica
            Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.yAxisLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 5),

            // GRÁFICA (fl_chart)
            SizedBox(
              height: 250,
              child: FutureBuilder<List<FlSpot>>(
                future: _influxService.getHistoryData(widget.measurement, widget.fieldName, widget.filterTag, widget.sensorId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error al cargar datos: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No hay datos disponibles"));
                  }
                  //Si hay datos, construyo la gráfica
                  final dataPoints = snapshot.data!;

                  //Calculo el maximo X para ajustar la vista
                  final currentMaxX = dataPoints.isNotEmpty ? dataPoints.last.x : widget.maxX;

                  return LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: dataPoints.map((e) => e.y).reduce(max) * 1.2, // Máximo Y con margen
                      minX: 0,
                      maxX: currentMaxX,
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: _alarmThreshold,
                            color: Colors.redAccent,
                            strokeWidth: 2,
                            dashArray: [5, 5],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.centerRight,
                              style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.bold),
                              labelResolver: (line) => 'Alarma: ${_alarmThreshold.toStringAsFixed(1)}',
                            ),
                          ),
                        ],
                      ),
                      gridData: const FlGridData (show: true, drawVerticalLine: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                      ),
                      borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                      lineBarsData: [
                        LineChartBarData(
                          spots: dataPoints, //datos reales
                          isCurved: true,
                          color: widget.lineColor,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show:true, color: widget.lineColor),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),


            //SLider de la alarma
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
                    divisions: 48,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

//Widget para manejar multiples lineas en una gráfica 
class _MultiSensorChartCard extends StatefulWidget {
  final String title;
  final String yAxisLabel;
  final double maxX;

  final String sensorId;
  final String measurement;
  final String filterTag;

  //Acepto lista en lugar de solo string

  final List<String> fieldNames;  //Nombres de los campos en influxDB
  final List<Color> lineColors; //Colores para cada línea
  final List<String> legendLabels; //Etiquetas para la leyenda

  const _MultiSensorChartCard({
    required this.title,
    required this.yAxisLabel,
    required this.sensorId,
    required this.measurement,
    required this.fieldNames,
    required this.lineColors,
    required this.legendLabels,
    required this.filterTag,
    this.maxX = 60, // Por defecto 60 min
  });

  @override
  State<_MultiSensorChartCard> createState() => _MultiSensorChartCardState();
}

class _MultiSensorChartCardState extends State<_MultiSensorChartCard> {
  final InfluxService _influxService = InfluxService(); //Instance de servicio InfluxDB

  //Función para cargar datos de múltiples campos
  Future<List<List<FlSpot>>> _fetchAllData() async {
    //Future.wait para pedir los 3 campos a la vez
    return await Future.wait(widget.fieldNames.map((field) =>  
        _influxService.getHistoryData(
          widget.measurement,
          field,
          widget.filterTag,
          widget.sensorId,
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

            Wrap(
              spacing: 12,
              children: List.generate(widget.legendLabels.length, (index) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: widget.lineColors[index]),
                      const SizedBox(width: 4),
                      Text(widget.legendLabels[index], style: const TextStyle(fontSize: 12)),
                  ],
                );
              }),
            ),
            
            const SizedBox(height: 20),

            SizedBox(
              height: 250,
              child: FutureBuilder<List<List<FlSpot>>>(
                future: _fetchAllData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error al cargar datos: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No hay datos disponibles"));
                  }
                  //Si hay datos, construyo la gráfica
                  final allDataPoints = snapshot.data!;

                  //Calculo el maximo X para ajustar la vista
                  double currentMaxX = widget.maxX;
                  for (var list in allDataPoints) {
                    if (list.isNotEmpty && list.last.x > currentMaxX) currentMaxX = list.last.x;
                  }
                  return LineChart(
                    LineChartData(
                      minY: 0,
                      //maxY automatico o con margen da igual
                      minX: 0,
                      maxX: currentMaxX,
                      gridData: const FlGridData (show: true, drawVerticalLine: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                      ),
                      borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                      lineBarsData: List.generate(allDataPoints.length, (index) {
                        return LineChartBarData(
                          spots: allDataPoints[index], //datos reales
                          isCurved: true,
                          color: widget.lineColors[index],
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show:true, color: widget.lineColors[index]),
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
}
}