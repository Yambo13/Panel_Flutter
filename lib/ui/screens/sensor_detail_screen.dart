// lib/ui/screens/dashboard_screen.dart


// // lib/ui/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Importamos la librería de gráficas
import 'package:agro/services/influx_services.dart';
import 'dart:async';  //Para el timer


//Definicion de colores para las gráficas

const Color kChartPrimary = Color(0xFF00BFA5);
const Color kChartSecondary = Color(0xFF2979FF);
const Color kGridLineColor = Color(0xFFEEEEEE);
const Color kAxisTextColor = Color(0xFF9E9E9E);
const Color kAlarmColor = Color(0xFFE53935);





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
            _SensorChartCard(
              title: "Peak Velocity Sensor",
              lineColor: Colors.green,
              yAxisLabel: "Velocidad (mm/s)",
              measurement: "upct-it2-engine",
              fieldName: 'time_value_payload',
              filterTag: "id",
              sensorId: "12648430",
            )
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
    Key? key,
    required this.title,
    required this.lineColor,
    required this.yAxisLabel,
    required this.sensorId,
    required this.measurement,
    required this.fieldName,
    this.filterTag = "topic",
    this.maxX = 60, // Por defecto 60 min
  }) : super(key: key);

  @override
  State<_SensorChartCard> createState() => _SensorChartCardState();
}

class _SensorChartCardState extends State<_SensorChartCard> {
  double _alarmThreshold = 8.0; // Valor inicial de la alarma para esta gráfica
  final InfluxService _influxService = InfluxService(); //Instance de servicio InfluxDB

  // Variables de estado
  List<FlSpot> _spots = [];
  bool _isLoading = true;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    // Cargo los datos y programo el reloj 
    _fetchData();

    //COnfigura cada cuanto quieres actualizar (ej:2 segundos)
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    // ·. Limpieza: Matar al reloj cuando salimos de la pantalla (Importante)
    _timer?.cancel();
    super.dispose();
  }

  //$ Fucnión de carga
  Future<void> _fetchData() async {
    //Pido los datos a la base
    final data = await _influxService.getHistoryData(
      widget.measurement, 
      widget.fieldName, 
      widget.filterTag, 
      widget.sensorId
    );

    //Si el widget sigue vivo (el usuario no se ha ido), actualizamos 
    if (mounted) {
      setState(() {
        _spots = data;
        _isLoading = false; //Ya tengo datos, esto quita el cargando
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //Calculo el maximo X para que la gráfica avance sola
    final currentMaxX = _spots.isNotEmpty ? _spots.last.x : widget.maxX;

    return Card(
      elevation: 0, // Quitamos elevación para un look más plano y limpio
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100), // Borde muy sutil en la tarjeta
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Título más elegante
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                //Icono animado en vivo 
                _isLoading
                  ? const SizedBox(height: 10, width: 10, child: CircularProgressIndicator(strokeWidth: 2))
                  : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Text("Live", style: TextStyle(fontSize: 10, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            Text(widget.yAxisLabel, style: TextStyle(fontSize: 12, color: kAxisTextColor)),
            const SizedBox(height: 24),

            SizedBox(
              height: 220, // Un poco más de altura
              child: _spots.isEmpty && _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _spots.isEmpty
                    ? Center(child: Text("Recibiendo datos....", style: TextStyle(color: kAxisTextColor))) 
                    : LineChart(
                        LineChartData(
                          minY: 0,
                          minX: 0,
                          maxX: currentMaxX,

                          // 1. INTERACTIVIDAD (TOOLTIP) PROFESIONAL
                          lineTouchData: LineTouchData(
                            handleBuiltInTouches: true,
                            touchTooltipData: LineTouchTooltipData(
                                tooltipBorderRadius: BorderRadius.circular(8),
                                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                    return touchedBarSpots.map((barSpot) {
                                      return LineTooltipItem(
                                        '${barSpot.y.toStringAsFixed(2)} ${widget.yAxisLabel}\n',
                                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold,),
                                          children: [
                                            TextSpan(
                                              text: 'Minuto ${barSpot.x.toInt()}',
                                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.normal, fontSize: 10),
                                            ),
                                          ],
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                          // 2. REJILLA SUTIL
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: _alarmThreshold > 0 ? _alarmThreshold / 2 : 5, // Intenta adaptar las líneas
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: kGridLineColor,
                                strokeWidth: 0.5,
                                dashArray: [4, 4], // Línea punteada sutil
                              );
                            },
                          ),
                          // 3. EJES LIMPIOS
                          titlesData: FlTitlesData(
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 22,
                                interval: currentMaxX / 5, // Muestra unos 5 labels en el eje X
                                getTitlesWidget: (value, meta) {
                                  if (value == 0 || value == currentMaxX) return const SizedBox.shrink();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6.0),
                                    child: Text("${value.toInt()}m", style: TextStyle(color: kAxisTextColor, fontSize: 10)),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: _alarmThreshold > 0 ? _alarmThreshold / 2 : null, // Intenta adaptar los labels
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                    if (value == 0) return const SizedBox.shrink();
                                    return Text(value.toStringAsFixed(1), style: TextStyle(color: kAxisTextColor, fontSize: 10), textAlign: TextAlign.right);
                                },
                              ),
                            ),
                          ),
                          // 4. SIN BORDES NEGROS
                          borderData: FlBorderData(show: false),
                      // 5. LÍNEA DE ALARMA MEJORADA
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: _alarmThreshold,
                                color: kAlarmColor.withOpacity(0.6),
                                strokeWidth: 1.5,
                                dashArray: [6, 2],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  style: TextStyle(color: kAlarmColor, fontWeight: FontWeight.bold, fontSize: 10),
                                  labelResolver: (line) => "Límite: ${line.y.toStringAsFixed(1)}",
                                ),
                              ),
                            ],
                          ),
                          // 6. LÍNEA DE DATOS CON GRADIENTE Y RELLENO
                          lineBarsData: [
                            LineChartBarData(
                              spots: _spots,
                              isCurved: true,
                              curveSmoothness: 0, // Curva suave pero precisa
                              // Usamos gradiente en lugar de color plano
                              gradient: const LinearGradient(
                                colors: [kChartPrimary, kChartSecondary],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              barWidth: 2.5, // Línea más fina y elegante
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: false), // Sin puntos, solo línea limpia
                              belowBarData: BarAreaData(
                                show: false,
                                // Gradiente vertical de relleno que se desvanece
                                gradient: LinearGradient(
                                  colors: [
                                    kChartPrimary.withOpacity(0.3),
                                    kChartSecondary.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                    ),
                  ),
            
              ),
            
            const SizedBox(height: 20),
            const Divider(),
            // SLIDER DE ALARMA (Con un pequeño retoque visual)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.notifications_active, color: kAlarmColor.withOpacity(0.8), size: 20),
                  const SizedBox(width: 12),
                  Text("Alarma:", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800])),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: kAlarmColor,
                        inactiveTrackColor: kAlarmColor.withOpacity(0.2),
                        thumbColor: kAlarmColor,
                        overlayColor: kAlarmColor.withOpacity(0.1),
                        trackHeight: 3.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                      ),
                      child: Slider(
                        value: _alarmThreshold,
                        min: 0,
                        max: 300, // Ajustado a un rango más realista
                        divisions: 100,
                        activeColor: kAlarmColor,
                        onChanged: (v) => setState(() => _alarmThreshold = v),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kAlarmColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: kAlarmColor.withOpacity(0.3))
                    ),
                    child: Text(
                      _alarmThreshold.toStringAsFixed(1),
                      style: TextStyle(color: kAlarmColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
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
  final InfluxService _influxService = InfluxService();
  
  // 1. ESTADO
  double _alarmThreshold = 5.0;
  List<List<FlSpot>> _allSpots = [[], [], []]; // Lista de listas (una por cada línea)
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 2. INICIAR CARGA Y TEMPORIZADOR
    _fetchAllData();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchAllData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Limpieza al salir
    super.dispose();
  }

  // 3. CARGA DE DATOS EN PARALELO
  Future<void> _fetchAllData() async {
    try {
      final results = await Future.wait(
        widget.fieldNames.map((field) => 
          _influxService.getHistoryData(
            widget.measurement, 
            field, 
            widget.filterTag, 
            widget.sensorId
          )
        )
      );

      if (mounted) {
        setState(() {
          _allSpots = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando multi-chart: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 4. CÁLCULO DE EJES DINÁMICOS (Max X y Max Y)
    double currentMaxX = widget.maxX;
    double currentMaxY = 0;

    // Buscamos el valor más alto en todas las líneas
    for (var list in _allSpots) {
      if (list.isNotEmpty) {
        if (list.last.x > currentMaxX) currentMaxX = list.last.x;
        for (var spot in list) {
          if (spot.y > currentMaxY) currentMaxY = spot.y;
        }
      }
    }

    // Ajuste con la alarma y margen superior ("aire")
    if (_alarmThreshold > currentMaxY) currentMaxY = _alarmThreshold;
    double finalMaxY = (currentMaxY * 1.2);
    if (finalMaxY == 0) finalMaxY = 10; // Mínimo por defecto

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con Título y Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                _isLoading 
                  ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2))
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text("LIVE", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Leyenda de colores
            Wrap(
              spacing: 12,
              children: List.generate(widget.legendLabels.length, (index) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: widget.lineColors[index], shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(widget.legendLabels[index], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                );
              }),
            ),
            
            const SizedBox(height: 24),

            // GRÁFICA
            SizedBox(
              height: 250,
              child: _allSpots.every((l) => l.isEmpty) && !_isLoading
                  ? Center(child: Text("Esperando datos...", style: TextStyle(color: kAxisTextColor)))
                  : LineChart(
                    LineChartData(
                      minY: 0,
                      minX: 0,
                      maxX: currentMaxX,
                      maxY: finalMaxY, // <--- Aplicamos el Y dinámico calculado
                      
                      // Interactividad (Tooltip que muestra 3 valores si se superponen)
                      lineTouchData: LineTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              return LineTooltipItem(
                                '${widget.legendLabels[barSpot.barIndex]}: ${barSpot.y.toStringAsFixed(2)}\n',
                                TextStyle(color: widget.lineColors[barSpot.barIndex], fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                        ),
                      ),

                      // Línea de Alarma
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: _alarmThreshold,
                            color: kAlarmColor.withOpacity(0.6),
                            strokeWidth: 1.5,
                            dashArray: [6, 2],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              style: TextStyle(color: kAlarmColor, fontWeight: FontWeight.bold, fontSize: 10),
                              labelResolver: (line) => "Límite: ${line.y.toStringAsFixed(1)}",
                            ),
                          ),
                        ],
                      ),

                      gridData: FlGridData(
                        show: true, 
                        drawVerticalLine: false,
                        horizontalInterval: finalMaxY / 5, // Intervalos dinámicos según la altura
                        getDrawingHorizontalLine: (value) => FlLine(color: kGridLineColor, strokeWidth: 0.5, dashArray: [4, 4]),
                      ),
                      
                      titlesData: FlTitlesData(
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                                if (value == 0 || value >= finalMaxY) return const SizedBox.shrink();
                                return Text(value.toStringAsFixed(1), style: TextStyle(color: kAxisTextColor, fontSize: 10));
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: currentMaxX / 5,
                            getTitlesWidget: (value, meta) {
                               return Padding(
                                 padding: const EdgeInsets.only(top: 6.0),
                                 child: Text("${value.toInt()}m", style: TextStyle(color: kAxisTextColor, fontSize: 10)),
                               );
                            },
                          ),
                        ),
                      ),
                      
                      borderData: FlBorderData(show: false),
                      
                      // Generación de las 3 líneas
                      lineBarsData: List.generate(_allSpots.length, (index) {
                        return LineChartBarData(
                          spots: _allSpots[index], // Datos en vivo
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: widget.lineColors[index],
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        );
                      }),
                    ),
                  ),
            ),

            const SizedBox(height: 20),
            const Divider(),

            // SLIDER DE ALARMA
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.notifications_active, color: kAlarmColor.withOpacity(0.8), size: 20),
                  const SizedBox(width: 12),
                  const Text("Alarma:", style: TextStyle(fontWeight: FontWeight.w600)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: kAlarmColor,
                        thumbColor: kAlarmColor,
                        inactiveTrackColor: kAlarmColor.withOpacity(0.2),
                        trackHeight: 3.0,
                        overlayColor: kAlarmColor.withOpacity(0.1),
                      ),
                      child: Slider(
                        value: _alarmThreshold,
                        min: 0,
                        // El slider también se adapta al máximo de la gráfica si los datos suben mucho
                        max: (finalMaxY > 25) ? finalMaxY : 25, 
                        divisions: 100,
                        onChanged: (v) => setState(() => _alarmThreshold = v),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: kAlarmColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(_alarmThreshold.toStringAsFixed(1), style: TextStyle(color: kAlarmColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
