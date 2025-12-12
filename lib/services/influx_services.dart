import 'package:influxdb_client/api.dart';
import 'package:fl_chart/fl_chart.dart';




class InfluxService {
  final String url = "/api/v2/query";
  //final String url = "http://31.222.232.41:8086";
  final String token = "ZYAEkWP65qrA9q9EDgxlgX56BOUBcAZ0f8VkuA1hBfK6eijwmMbIrm26Bwj-x7ZENLvkbODqWJsfXFqmp33chg==";
  final String org = "qartia";
  final String bucket = "Engine-UPCT";

  late InfluxDBClient client;

  InfluxService() {
    client = InfluxDBClient(
      url: url,
      token: token,
      org: org,
      bucket: bucket,
    );
  }

  Future<double?> getLatestSensorData(String sensorTopic, String field) async {
    try {
      final queryService = client.getQueryService();

      final query = '''
        from(bucket: "$bucket")
          |> range(start: -1d)
          |> filter(fn: (r) => r["_measurement"] == "agro-mqtt")
          |> filter(fn: (r) => r["topic"] == "application/daddcdf1-2657-4f31-aa11-f1d412934550/device/$sensorTopic/event/up")
          |> filter(fn: (r) => r["_field"] == "$field")
          |> last()
      ''';

      final recordStream = await queryService.query(query);
      final records = await recordStream.toList();

      if (records.isNotEmpty) {

        final valor = records.first['_value'];
        print("Dato recibido para $sensorTopic ($field): $valor");
        return records.first['_value'] as double?;
      }
    } catch (e) {
      print("❌ Error al consultar $sensorTopic ($field): $e");
    }

    return null;
  }

//Obtiene el historial de un campo especifico para las gráficas
Future<List<FlSpot>> getHistoryData(String measurement, String field, String filterTag, String filterValue) async {
    try {
      final queryService = client.getQueryService();

      //Consulta: Última hora (-1h) o último día (-1d). Ajusta según necesidad 
      final query = '''
        from(bucket: "$bucket")
          |> range(start: -1d)
          |> filter(fn: (r) => r["_measurement"] == "$measurement")
          |> filter(fn: (r) => r["$filterTag"] == "$filterValue")
          |> filter(fn: (r) => r["_field"] == "$field")
          |> limit(n: 100)
      ''';

      final recordStream = await queryService.query(query);
      final records = await recordStream.toList();

      List<FlSpot> spots = [];
      //Convierto los registros de InfluxDB a puntos X,Y
      for (var i = 0; i < records.length; i++) {
        final rawValue = records[i]['_value'];
        double? finalValue;
        final timeString = records[i]['_time'];
        final date = DateTime.parse(timeString);
        //intento de conexión a bruto
        if (rawValue is num) {
          finalValue = rawValue.toDouble();
        } else if (rawValue is String) {
          finalValue = double.tryParse(rawValue);
        }

        //Si obtengo un numero válido lo añado a la lista de puntos
        if (finalValue != null) {
          spots.add(FlSpot(i.toDouble(), finalValue));
        }else {
          print("⚠️ Valor no numérico ignorado en el historial: $rawValue (Tipo: ${rawValue.runtimeType})");
        }
      }

      //LOG para verificar los puntos obtenidos
      print("Datos para $filterValue ($field): ${spots.length} puntos.");
      return spots;

    } catch (e) {
      print("❌ Error al obtener historial para $e");
      return []; //Si falla devuñelve lista vacía
    }

  }




}
