import 'dart:collection';
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

/// Activa logs si necesitas depurar.
const bool depu = true;
const bool cacheDepu = true;

/// Servicio HTTP para consultar InfluxDB (v2) desde Flutter (incluye Web).
class InfluxService {
  // ====== CONFIG ======
  // OJO: baseUrl debe ser el ORIGEN que sirva Influx (o tu reverse proxy),
  // SIN / al final. Ej: https://qartia.com  ó  https://31.222.232.41:8086
  final String baseUrl;
  final String token;
  final String org; // org name o id (en el query param suele ser name)
  final String bucket;

  final http.Client _client;

  // ====== CACHE ======
  final Duration cacheExpiration;
  final Map<String, SplayTreeMap<double, double>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  InfluxService({
    http.Client? client,
    this.baseUrl = "https://qartia.com/paneles_flutter",
    this.token =
        "ZYAEkWP65qrA9q9EDgxlgX56BOUBcAZ0f8VkuA1hBfK6eijwmMbIrm26Bwj-x7ZENLvkbODqWJsfXFqmp33chg==",
    this.org = "qartia",
    this.bucket = "Engine-UPCT",
    this.cacheExpiration = const Duration(minutes: 5),
  }) : _client = client ?? http.Client();

  /// Devuelve el último valor (double) de un campo para un topic/tag concreto.
  ///
  /// - measurement: ejemplo "cartagena-engine"
  /// - field: ejemplo "object_temperature"
  /// - filterTag: ejemplo "topic"
  /// - sensorTopic: ejemplo "sensor_rodamiento_frontal"
  Future<double?> getLatestSensorData({
    required String measurement,
    required String field,
    required String filterTag,
    required String sensorTopic,
  }) async {
    try {
      final fluxQuery = _buildFluxQuery(
        measurement: measurement,
        field: field,
        filterTag: filterTag,
        filterValue: sensorTopic,
        // último valor: buscamos “un rango razonable” y aplicamos last()
        start: DateTime.now().subtract(const Duration(days: 7)),
        stop: DateTime.now(),
        aggregateEvery: null,
        useLast: true,
        limit: 1,
      );

      final results = await _executeQuery(
        fluxQuery: fluxQuery,
        cacheKey:
            "LATEST|$bucket|$measurement|$field|$filterTag=$sensorTopic|1",
        // forzamos no-cache para latest si te interesa siempre frescura:
        bypassCache: true,
      );

      if (results.isNotEmpty) {
        return results.last.$2;
      }
    } catch (e) {
      Logger().e("❌ Error getLatestSensorData($measurement/$field): $e");
    }
    return null;
  }

  /// Historial para graficar (FlSpot) del último [hours] horas.
  ///
  /// Esto encaja con tu UI (FutureBuilder + LineChart).
  Future<List<FlSpot>> getHistoryData(
    String measurement,
    String field,
    String filterTag,
    String sensorTopic, {
    int hours = 24,
    Duration aggregateEvery = const Duration(minutes: 1),
    int? limit,
  }) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(hours: hours));
    final stop = now;

    final fluxQuery = _buildFluxQuery(
      measurement: measurement,
      field: field,
      filterTag: filterTag,
      filterValue: sensorTopic,
      start: start,
      stop: stop,
      aggregateEvery: aggregateEvery,
      useLast: false,
      limit: limit,
    );

    final cacheKey =
        "HIST|$bucket|$measurement|$field|$filterTag=$sensorTopic|${start.millisecondsSinceEpoch}|${stop.millisecondsSinceEpoch}|${aggregateEvery.inSeconds}|${limit ?? 0}";

    final tuples = await _fetchBetweenTimestamps(
      fluxQuery: fluxQuery,
      cacheKey: cacheKey,
      startTimestampMs: start.millisecondsSinceEpoch.toDouble(),
      endTimestampMs: stop.millisecondsSinceEpoch.toDouble(),
      limit: limit,
    );

    // FlChart: x e y son double.
    // x lo dejamos en ms epoch; si quieres “eje bonito”, conviertes luego.
    return tuples.map((p) => FlSpot(p.$1, p.$2)).toList(growable: false);
  }

  // =========================================================
  // ===================== CORE HTTP =========================
  // =========================================================

  String _buildFluxQuery({
    required String measurement,
    required String field,
    required String filterTag,
    required String filterValue,
    required DateTime start,
    required DateTime stop,
    required Duration? aggregateEvery,
    required bool useLast,
    int? limit,
  }) {
    // Influx Flux time(v: <ns>)
    final startNs = "${start.millisecondsSinceEpoch}000000";
    final stopNs = "${stop.millisecondsSinceEpoch}000000";

    final buf = StringBuffer()
      ..writeln('from(bucket: "$bucket")')
      ..writeln('  |> range(start: time(v: $startNs), stop: time(v: $stopNs))')
      ..writeln('  |> filter(fn: (r) => r["_measurement"] == "$measurement")')
      ..writeln('  |> filter(fn: (r) => r["_field"] == "$field")')
      ..writeln('  |> filter(fn: (r) => r["$filterTag"] == "$filterValue")');

    if (aggregateEvery != null) {
      // last en ventanas para reducir puntos
      buf.writeln(
          '  |> aggregateWindow(every: ${aggregateEvery.inSeconds}s, fn: last, createEmpty: false)');
    }

    if (useLast) {
      buf.writeln('  |> last()');
    }

    if (limit != null && limit > 0) {
      buf.writeln('  |> limit(n: $limit)');
    }

    return buf.toString();
  }

  Future<List<(double, double)>> _fetchBetweenTimestamps({
    required String fluxQuery,
    required String cacheKey,
    required double startTimestampMs,
    required double endTimestampMs,
    int? limit,
  }) async {
    // 1) intenta caché
    final cached = _fetchCacheData(
      key: cacheKey,
      startTimestampMs: startTimestampMs,
      endTimestampMs: endTimestampMs,
      limit: limit,
    );

    if (cached.isNotEmpty) {
      if (cacheDepu) {
        Logger().i("✅ Cache HIT: $cacheKey (${cached.length} puntos)");
      }
      return cached.entries.map((e) => (e.key, e.value)).toList();
    }

    // 2) pega a Influx
    final data = await _executeQuery(fluxQuery: fluxQuery, cacheKey: cacheKey);

    // 3) guarda en caché
    await _updateCache(cacheKey, data);

    // 4) devuelve (ya filtrado por rango)
    final filtered = _fetchCacheData(
      key: cacheKey,
      startTimestampMs: startTimestampMs,
      endTimestampMs: endTimestampMs,
      limit: limit,
    );

    return filtered.entries.map((e) => (e.key, e.value)).toList();
  }

  Future<List<(double, double)>> _executeQuery({
    required String fluxQuery,
    required String cacheKey,
    bool bypassCache = false,
  }) async {
    // si no bypass: y el caché no está expirado, no hace falta consultar
    if (!bypassCache && _cache.containsKey(cacheKey)) {
      final ts = _cacheTimestamps[cacheKey];
      if (ts != null && DateTime.now().difference(ts) < cacheExpiration) {
        if (cacheDepu) Logger().i("✅ Cache válido (no HTTP): $cacheKey");
        return _cache[cacheKey]!.entries.map((e) => (e.key, e.value)).toList();
      }
    }

    final uri = Uri.parse("$baseUrl/api/v2/query?org=a64aef386037d501");

    final headers = <String, String>{
      'Authorization': 'Token $token',
      'Accept': 'application/csv',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'query': fluxQuery,
      'type': 'flux',
      'dialect': {
        'header': true,
        'delimiter': ",",
        'annotations': ['datatype', 'group', 'default'],
      }
    });

    if (depu) {
      Logger().i("➡️ POST $uri");
      Logger().i("Flux:\n$fluxQuery");
    }

    final response = await _client.post(uri, headers: headers, body: body);

    if (response.statusCode == 200) {
      final parsed = _parseInfluxDBCsv(response.body);
      return parsed;
    } else {
      throw Exception("Influx HTTP ${response.statusCode}: ${response.body}");
    }
  }

  /// Parse CSV anotado de Influx a pares (timestampMs, value).
  List<(double, double)> _parseInfluxDBCsv(String csvData) {
    final spots = <(double, double)>[];

    final lines0 = csvData.split('\n');
    if (lines0.length <= 4) return spots;

    // Influx suele mandar 3 líneas de annotations antes del header real
    var lines = lines0.sublist(3);
    if (lines.isEmpty) return spots;

    final header = lines[0].split(',');
    final timeIndex = header.indexOf('_time');
    final valueIndex = header.indexOf('_value');

    if (timeIndex == -1 || valueIndex == -1) {
      if (depu) Logger().e("CSV sin _time/_value en header: ${lines[0]}");
      return spots;
    }

    // saltamos header
    lines = lines.sublist(1);

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final values = line.split(',');
      if (values.length <= valueIndex || values.length <= timeIndex) continue;

      try {
        final timeString = values[timeIndex];
        final valueString = values[valueIndex];

        final y = double.tryParse(valueString);
        if (y == null) continue;

        final t = DateTime.tryParse(timeString);
        if (t == null) continue;

        final x = t.millisecondsSinceEpoch.toDouble();
        spots.add((x, y));
      } catch (e) {
        if (depu) Logger().e("Error parseando línea CSV: $e");
      }
    }

    return spots;
  }

  /// Devuelve mapa timestamp->value desde caché (si no expiró) y filtrado por rango.
  Map<double, double> _fetchCacheData({
    required String key,
    required double startTimestampMs,
    required double endTimestampMs,
    int? limit,
  }) {
    final ts = _cacheTimestamps[key];
    if (ts == null) return {};

    // expiración
    if (DateTime.now().difference(ts) > cacheExpiration) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      if (cacheDepu) Logger().i("🧹 Cache expirado: $key");
      return {};
    }

    final map = _cache[key];
    if (map == null || map.isEmpty) return {};

    // SplayTreeMap está ordenado por key (timestamp)
    final result = <double, double>{};

    for (final entry in map.entries) {
      if (entry.key < startTimestampMs) continue;
      if (entry.key > endTimestampMs) break;
      result[entry.key] = entry.value;
    }

    if (limit != null && limit > 0 && result.length > limit) {
      // deja los últimos N
      final keys = result.keys.toList(growable: false);
      final slice = keys.sublist(keys.length - limit);
      return {for (final k in slice) k: result[k]!};
    }

    return result;
  }

  Future<void> _updateCache(String key, List<(double, double)> newData) async {
    _cache.putIfAbsent(key, () => SplayTreeMap<double, double>());
    final map = _cache[key]!;
    for (final p in newData) {
      map[p.$1] = p.$2;
    }
    _cacheTimestamps[key] = DateTime.now();
  }

  void disconnect() {
    _client.close();
  }
}
