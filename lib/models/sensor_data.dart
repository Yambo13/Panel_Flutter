class SensorData {
  final String id;
  final double temperatura;
  final double humedad;
  final double luminosidad;
  final double bateria;
  //final double object_radial_velocity;    Esto son los valores de la alarma que puede settear el cliente

  SensorData({
    required this.id,
    required this.temperatura,
    required this.humedad,
    required this.luminosidad,
    required this.bateria,
    //required this.object_radial_velocity,       
  });
}
