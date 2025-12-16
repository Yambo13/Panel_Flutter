import 'dart:collection';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:logger/logger.dart';

class InfluxService {
  // Configuración
  //final String baseUrl = "https://212.128.44.184";
  //final String baseUrl = "https://31.222.232.41:8086"; // Asegúrate de que esta sea la IP correcta
  final String baseUrl = "https://qartia.com"; // URL base de InfluxDB
  final String token = "ZYAEkWP65qrA9q9EDgxlgX56BOUBcAZ0f8VkuA1hBfK6eijwmMbIrm26Bwj-x7ZENLvkbODqWJsfXFqmp33chg==";
  final String orgId = "qartia"; // ID de la organización para la URL
  final String bucket = "Engine-UPCT";

  final http.Client _client;
  
  // Sistema de Caché (Igual que http_service.dart)
  final Duration cacheExpiration = const Duration(minutes: 5);
  final Map<String, SplayTreeMap<double, double>> cache = {};
  final Map<String, DateTime> cacheTimestamps = {};
  
  // Flag de depuración
  final bool depu = true; 

  InfluxService() : _client = http.Client();

  /// Obtiene el último valor de un sensor (Sin caché persistente, suele requerir dato real)
  Future<double?> getLatestSensorData(String sensorTopic, String field) async {
    final query = '''
      from(bucket: "$bucket")
        |> range(start: -1d)
        |> filter(fn: (r) => r["_measurement"] == "agro-mqtt")
        |> filter(fn: (r) => r["topic"] == "application/daddcdf1-2657-4f31-aa11-f1d412934550/device/$sensorTopic/event/up")
        |> filter(fn: (r) => r["_field"] == "$field")
        |> last()
    ''';

    try {
      final results = await _executeQuery(query);
      
      if (results.isNotEmpty) {
        // results es una lista de tuplas (timestamp, valor), tomamos el valor del último
        final valor = results.last.$2;
        if (depu) print("Dato recibido para $sensorTopic ($field): $valor");
        return valor;
      }
    } catch (e) {
      Logger().e("❌ Error al consultar $sensorTopic ($field): $e");
    }
    return null;
  }

  /// Obtiene el historial para gráficas usando lógica HTTP + Caché
  Future<List<FlSpot>> getHistoryData(String measurement, String field, String filterTag, String filterValue) async {
    // Generamos una clave única para el caché
    String cacheKey = '$bucket|$measurement|$field|$filterValue';

    // Rango de tiempo: Simulamos -1d calculando timestamps (para que funcione la lógica de tu caché)
    final now = DateTime.now();
    final endTimestamp = now.millisecondsSinceEpoch;
    final startTimestamp = now.subtract(const Duration(days: 1)).millisecondsSinceEpoch;

    // 1. Intentar obtener del caché
    var cachedData = _fetchCacheData(
      cacheKey, 
      startTimestamp.toDouble(), 
      endTimestamp.toDouble()
    );

    if (cachedData.isNotEmpty) {
      if (depu) print("Cache hit para $field");
      return cachedData.entries
          .map((e) => FlSpot(e.key, e.value)) // Convertimos a FlSpot
          .toList();
    }

    // 2. Si no hay caché, construimos la consulta Flux
    // Nota: Usamos aggregateWindow para no saturar la gráfica si hay muchos datos
    final query = '''
      from(bucket: "$bucket")
        |> range(start: -1d)
        |> filter(fn: (r) => r["_measurement"] == "$measurement")
        |> filter(fn: (r) => r["$filterTag"] == "$filterValue")
        |> filter(fn: (r) => r["_field"] == "$field")
        |> aggregateWindow(every: 1h, fn: mean, createEmpty: false) 
        |> yield(name: "mean")
    ''';

    try {
      // Ejecutar consulta HTTP
      final newData = await _executeQuery(query);

      // 3. Actualizar Caché
      await _updateCache(cacheKey, newData);

      // 4. Convertir a FlSpot para la UI
      return newData.map((e) => FlSpot(e.$1, e.$2)).toList();

    } catch (e) {
      Logger().e("❌ Error al obtener historial para $measurement: $e");
      return [];
    }
  }

  // -----------------------------------------------------------------------
  // MÉTODOS PRIVADOS (Lógica extraída de http_service.dart)
  // -----------------------------------------------------------------------

  /// Realiza la petición HTTP raw a InfluxDB
  Future<List<(double, double)>> _executeQuery(String fluxQuery) async {
    final uri = Uri.parse("$baseUrl/paneles_flutter/api/v2/query?orgID=a64aef386037d501");
    
    final headers = {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/csv',
    };

    final body = jsonEncode({
      'query': fluxQuery,
      'type': 'flux',
      'dialect': {
        'header': true,
        'delimiter': ",",
        'annotations': ['datatype', 'group', 'default']
      }
    });

    if (depu) print("Ejecutando Query HTTP...");
    final response = await _client.post(uri, headers: headers, body: body);

    if (response.statusCode == 200) {
      return _parseInfluxDBCsv(response.body);
    } else {
      throw Exception("Error HTTP ${response.statusCode}: ${response.body}");
    }
  }

  /// Parsea el CSV de InfluxDB manualmente (Igual que en http_service.dart)
  List<(double, double)> _parseInfluxDBCsv(String csvData) {
    List<(double, double)> spots = [];
    
    List<String> lines = csvData.split('\n');
    // Necesitamos al menos metadatos + header + 1 dato
    if (lines.length <= 4) return spots; 

    // Ignorar las primeras 3 líneas (annotations de tipo datos)
    // Nota: A veces Influx devuelve 1 o 3 líneas de anotación dependiendo del dialecto.
    // Asumimos el estándar del dialecto configurado en _executeQuery.
    
    // Buscamos la cabecera real (la que empieza por result,table,_start...)
    int headerIndex = -1;
    for(int i=0; i<lines.length; i++) {
        if(lines[i].contains("_time") && lines[i].contains("_value")) {
            headerIndex = i;
            break;
        }
    }

    if (headerIndex == -1) return spots;

    List<String> header = lines[headerIndex].split(',');
    int timeIndex = header.indexOf('_time');
    int valueIndex = header.indexOf('_value');

    if (timeIndex == -1 || valueIndex == -1) return spots;

    // Procesar datos (líneas después del header)
    for (int i = headerIndex + 1; i < lines.length; i++) {
      String line = lines[i];
      if (line.trim().isEmpty) continue;

      List<String> values = line.split(',');
      // Validación básica de longitud para evitar crash
      if (values.length <= timeIndex || values.length <= valueIndex) continue;

      try {
        String timeString = values[timeIndex];
        String valueString = values[valueIndex];

        if (double.tryParse(valueString) != null) {
          double y = double.parse(valueString);
          DateTime time = DateTime.parse(timeString);
          double x = time.millisecondsSinceEpoch.toDouble(); // Usamos timestamp como X

          spots.add((x, y));
        }
      } catch (e) {
        // Ignorar líneas corruptas
      }
    }
    
    return spots;
  }

  // --- MÉTODOS DE CACHÉ (Copia de http_service.dart) ---

  Map<double, double> _fetchCacheData(String key, double start, double end) {
    if (!cache.containsKey(key) || 
        DateTime.now().difference(cacheTimestamps[key] ?? DateTime(0)) > cacheExpiration) {
      return {};
    }

    var cachedData = cache[key]!;
    var result = SplayTreeMap<double, double>();

    var filteredEntries = cachedData.entries
        .where((entry) => entry.key >= start && entry.key <= end);

    for (var entry in filteredEntries) {
      result[entry.key] = entry.value;
    }
    
    return result;
  }

  Future<void> _updateCache(String key, List<(double, double)> newData) async {
    if (!cache.containsKey(key)) {
      cache[key] = SplayTreeMap<double, double>();
    }
    for (var point in newData) {
      cache[key]![point.$1] = point.$2;
    }
    cacheTimestamps[key] = DateTime.now();
  }

  void disconnect() {
    _client.close();
  }
}