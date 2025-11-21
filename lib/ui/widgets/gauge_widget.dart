// gauge_widget.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class GaugeWidget extends StatelessWidget {
  final String sensorId;
  final double value;
  final String unit;
  final Color color;

  const GaugeWidget({
    super.key,
    required this.sensorId,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 150,
      child: Column(
        children: [
          Expanded(
            child: SfRadialGauge(
              axes: [
                RadialAxis(
                  minimum: 0,
                  maximum: unit == "°C" ? 40 : 100,
                  showLabels: false,
                  showTicks: false,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.1,
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  ranges: [
                    GaugeRange(
                      startValue: 0,
                      endValue: value,
                      color: color,
                      startWidth: 5,
                      endWidth: 5,
                    ),
                  ],
                  pointers: [
                    NeedlePointer(value: value),
                  ],
                ),
              ],
            ),
          ),
          Text("$sensorId\n${value.toStringAsFixed(2)} $unit", textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
