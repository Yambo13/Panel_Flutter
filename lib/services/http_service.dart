import 'dart:collection';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

bool depu = false;
bool cacheDepu = false;

/// Service to interact with InfluxDB using HTTP.
class HttpService {
  
  final Duration cacheExpiration = const Duration(minutes: 5);

  final String baseUrl;
  final http.Client _client;

  final Map<String, SplayTreeMap<double, double>> cache = {};
  final Map<String, DateTime> cacheTimestamps = {};

  HttpService({required this.baseUrl}) : _client = http.Client();

  /// Fetches the chart data between two timestamps from the cache or from InfluxDB.
  /// 
  /// The [token] is the InfluxDB token to use for the request.
  /// The [bucket] is the InfluxDB bucket to use for the request.
  /// The [field] is the field to monitor.
  /// The [measurement] is the measurement to monitor.
  /// The [startTimestamp] is the start timestamp to fetch data from.
  /// The [endTimestamp] is the end timestamp to fetch data from.
  /// The [topic] is the optional topic to filter the data.
  /// Returns a list of tuples with the timestamp and value of each data point.
  /// ```dart
  /// List<(double, double)> data = await httpService.fetchChartDataBetweenTimestamps(token, bucket, "temperatura", measurement, 1742152177232, 1742152182827);
  /// ```
  Future<List<(double, double)>> fetchChartDataBetweenTimestamps(String token, String bucket, String field, String measurement, int startTimestamp, int endTimestamp, [String? topic, int? limit]) async {   // TODO: que un fetch use al otro
    String cacheKey = '$bucket|$measurement|$field';
    if (topic != null && topic.isNotEmpty) {
      cacheKey += '|$topic';
    }
    
    // Intentar obtener datos del caché
    var cachedData = _fetchCacheData(
      token,
      cacheKey, 
      startTimestamp.toDouble(), 
      endTimestamp.toDouble(),
      limit  // Pasar el límite al método _fetchCacheData
    );

    if (cachedData.isNotEmpty) {
      return cachedData.entries
          .map((e) => (e.key, e.value))
          .toList();
    }

    // Si no hay datos en caché, hacer la consulta
    if (cacheDepu) print("Cache miss. Fetching data from InfluxDB. Field: $cacheKey.");
    var newData = await _fetchFromInfluxDB(
      token, bucket, field, measurement, 
      startTimestamp, endTimestamp, topic, limit
    );

    // Actualizar el caché con los nuevos datos
    await _updateCache(cacheKey, newData);

    return newData;
  }

  Future<List<(double, double)>> _fetchFromInfluxDB(String token, String bucket, String field, String measurement, int startTimestamp, int endTimestamp, [String? topic, int? limit]) async {
    final uri = Uri.parse("$baseUrl/api/v2/query?orgID=a64aef386037d501");

    final headers = {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/csv',
    };

    // Construimos los filtros dinámicamente
    String topicFilter = (topic != null) ? '|> filter(fn: (r) => r["topic"] == "$topic")' : '';
    String limitFilter = (limit != null) ? '|> limit(n: $limit)' : '';

    // Mapeo de transformaciones matemáticas
    Map<String, String> fieldTransformations = {
      "temp": '''
        |> map(fn:(r) => ({r with _value:
          -15.3606 * r._value + 150.0
        }))
      ''',
      "pres": '''
        |> map(fn:(r) => ({r with _value:
          0.070307 * math.exp(x:(0.6459 + 2.0142 * math.log(x:r._value)))
        }))
      ''',
      "time_value_payload": '''
        |> map(fn:(r) => ({r with _value:
          r._value / 1000.0
        }))
      ''',
    };

    // Aplicamos transformaciones si hay algún campo que lo necesita
    String transformationBlock = fieldTransformations[field] ?? '';

    // Construimos la consulta Flux dinámicamente
    String query = '''
      import "math"

      from(bucket: "$bucket")
        |> range(start: time(v: ${startTimestamp}000000), stop: time(v: ${endTimestamp}000000))
        |> filter(fn: (r) => r["_measurement"] == "$measurement")
        |> filter(fn: (r) => r["_field"] == "$field")
        $topicFilter
        $limitFilter
        |> aggregateWindow(every: 60s, fn: last, createEmpty: false)
        $transformationBlock
        |> yield(name: "last")
    ''';

    // Convertimos la query en JSON
    String body = jsonEncode({
      'query': query,
      'type': 'flux',
      'dialect': {
        'header': true,
        'delimiter': ",",
        'annotations': ['datatype', 'group', 'default']
      }
    });

    try {      
      if (depu) print("Query: $query");
      final response = await _client.post(uri, headers: headers, body: body);
      if (depu) print("Lectura terminada. Timestamp: " + DateTime.now().millisecondsSinceEpoch.toDouble().toString() + ". Measurement: " + measurement + ". Field: " + field + ". Tamaño de respuesta: " + response.body.length.toString());

      if (response.statusCode == 200) {
        return _parseInfluxDBCsv(response.body);

      } else {
        throw Exception("Error en la solicitud HTTP. Código de estado: ${response.statusCode}. Mensaje: ${response.body}");
      }
    } catch (e) {
      Logger().e("Error al obtener datos HTTP: $e");
      return [];
    }
  }

  /// Parses the CSV data returned by InfluxDB.
  /// 
  /// Returns a list of tuples with the timestamp and value of each data point.
  /// ```dart
  /// List<(double, double)> data = parseInfluxDBCsv(csvData);
  /// ```
  List<(double, double)> _parseInfluxDBCsv(String csvData) {

    List<(double, double)> spots = [];
    if (depu) print("Datos: " + csvData);
    
    // Check if the CSV data has at least 5 lines before splitting
    List<String> lines = csvData.split('\n');
    if (lines.length <= 4) {
      if (depu) Logger().e("CSV data does not contain enough lines to process.");
      return spots;
    }
    // Ignore the first 3 lines (metadata)
    lines = lines.sublist(3);

    // Find the indices of _time and _value in the header line
    List<String> header = lines[0].split(',');
    int timeIndex = header.indexOf('_time');
    int valueIndex = header.indexOf('_value');

    // Check if the header line contains the required fields
    if (timeIndex == -1 || valueIndex == -1) {
      if (depu) Logger().e("CSV data does not contain the required fields.");
      return spots;
    }

    // Ignore the header line
    lines = lines.sublist(1);

    // Process each line

    for (String line in lines) {
      // Ignore empty lines
      if (line.trim().isEmpty) {
        continue;
      }

      // Separate each line by commas
      List<String> values = line.split(',');

      try {
        String timeString = values[timeIndex]; // _time
        String valueString = values[valueIndex]; // _value

        if (double.tryParse(valueString) != null) {
          double y = double.parse(valueString);
          DateTime time = DateTime.parse(timeString);
          double x = time.millisecondsSinceEpoch.toDouble();

          spots.add((x, y));

        } else {
          Logger().e("Error al procesar línea: $line - Valor no numérico: $valueString");
        }
      } catch (e) {
        Logger().e("Error al procesar línea: $line - $e");
      }
    }
    // if (depu) print("Datos: " + spots.toString());
    return spots;
  }

  /// Fetches the chart data between two timestamps from the cache.
  ///
  /// The [token] is the InfluxDB token to use for the request.
  /// The [key] is the cache key to use for the request.
  /// The [startTimestamp] is the start timestamp to fetch data from.
  /// The [endTimestamp] is the end timestamp to fetch data from.
  /// Returns a map with the timestamp and value of each data point.
  /// ```dart
  /// Map<double, double> data = httpService.fetchCacheData("bucket1|measurement1|temperatura", 1742152177232, 1742152182827);
  /// ```
  Map<double, double> _fetchCacheData(String token, String key, double startTimestamp, double endTimestamp, [int? limit]) {
    // Verificar si el caché existe y no ha expirado
    if (!cache.containsKey(key) || 
        DateTime.now().difference(cacheTimestamps[key]!) > cacheExpiration) {
      return {};
    }

    var cachedData = cache[key]!;
    var result = SplayTreeMap<double, double>();

    // Obtener el rango solicitado
    var filteredEntries = cachedData.entries
        .where((entry) => entry.key >= startTimestamp && entry.key <= endTimestamp)
        .toList();

    // Si hay límite, tomar solo los últimos N elementos
    if (limit != null && filteredEntries.length > limit) {
      filteredEntries = filteredEntries.skip(filteredEntries.length - limit).toList();
    }

    // Añadir al resultado
    for (var entry in filteredEntries) {
      result[entry.key] = entry.value;
    }

    // Verificar si tenemos datos incompletos
    bool hasMissingDataBefore = cachedData.isNotEmpty && cachedData.firstKey()! > startTimestamp;
    bool hasMissingDataAfter = cachedData.isNotEmpty && cachedData.lastKey()! < endTimestamp;

    if (hasMissingDataBefore || hasMissingDataAfter) {
      _updateCacheRange(token, key, startTimestamp, endTimestamp);
      return result;
    }
    
    if (cacheDepu) print("Cache hit. Returning data from cache. Field: $key.");
    return result;
  }

  Future<void> _updateCacheRange(String token, String key, double startTimestamp, double endTimestamp, [int? limit]) async {
    var parts = key.split('|');
    if (parts.length < 3) return;

    var bucket = parts[0];
    var measurement = parts[1];
    var field = parts[2];
    var topic = (parts.length > 3 && parts[3].isNotEmpty) ? parts[3] : null;

    var cachedData = cache[key]!;
    var firstCachedTime = cachedData.firstKey()!;
    var lastCachedTime = cachedData.lastKey()!;

    List<(double, double)> newData = [];

    // Obtener datos anteriores si faltan
    if (startTimestamp < firstCachedTime) {
      if (cacheDepu) print("Cache medio-hit. Obteniendo datos anteriores. startTimestamp: $startTimestamp < firstCachedTime: $firstCachedTime.");
      var olderData = await _fetchFromInfluxDB(
        token,
        bucket,
        field,
        measurement,
        startTimestamp.toInt(),
        firstCachedTime.toInt() - 1, // -1 para evitar solapamiento, TODO: revisar
        topic,
        limit                        // TODO: no sería limit, sería limit - lo que ya se tiene
      );
      newData.addAll(olderData);
    }

    // Obtener datos posteriores si faltan
    if (endTimestamp > lastCachedTime) {
      if ((limit != null && limit > 1) && cacheDepu) print("Cache medio-hit. Obteniendo datos posteriores. endTimestamp: $endTimestamp > lastCachedTime: $lastCachedTime.");
      var newerData = await _fetchFromInfluxDB(
        token,
        bucket,
        field,
        measurement,
        lastCachedTime.toInt() + 1, // +1 para evitar solapamiento, TODO: revisar 
        endTimestamp.toInt(),
        topic,
        limit                        // TODO: no sería limit, sería limit - lo que ya se tiene
      );
      newData.addAll(newerData);
    }

    // Actualizar caché solo si hay nuevos datos
    if (newData.isNotEmpty) {
      await _updateCache(key, newData);
    }
  }

  Future<void> _updateCache(String key, List<(double, double)> newData) async {
    if (!cache.containsKey(key)) {
      cache[key] = SplayTreeMap<double, double>();
    }

    // Actualizar datos manteniendo los existentes que no se solapan
    for (var point in newData) {
      cache[key]![point.$1] = point.$2;
    }

    // Actualizar timestamp
    cacheTimestamps[key] = DateTime.now();
  }

  void disconnect() {
    _client.close();
  }
}