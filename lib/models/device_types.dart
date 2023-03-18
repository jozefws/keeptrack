import 'package:keeptrack/models/manufacturer.dart';

class DeviceType {
  final int id;
  final String name;
  final String url;
  final Manufacturer? manufacturer;
  final String? modelName;
  final String? unitHeight;
  final String? weightUnit;
  final String? weight;

  DeviceType({
    required this.id,
    required this.name,
    required this.url,
    this.manufacturer,
    this.modelName,
    this.unitHeight,
    this.weightUnit,
    this.weight,
  });

  factory DeviceType.fromJson(Map<String, dynamic> json) {
    return DeviceType(
      id: json['id'],
      name: json['display'],
      url: json['url'],
      manufacturer: Manufacturer.fromJson(json['manufacturer']),
      modelName: json['model'],
      unitHeight: json['u_height'].toString(),
      weightUnit: json['weight_unit']?['value'],
      weight: json['weight'].toString(),
    );
  }
}
