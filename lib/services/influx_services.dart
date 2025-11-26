import 'package:influxdb_client/api.dart';

class InfluxService {
  final String url = "http://31.222.232.41:8086";
  final String token = "KIGmOo_ggh-I0s4tbQJKLVCDEJmYDYRJxs_1O5BiCADZd1VabysX1wNUtdoKMk4SSqB6RW2WAjWfAwJ-GkfhAw==";
  final String org = "qartia";
  final String bucket = "AgroNext-UPCT";

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

}
