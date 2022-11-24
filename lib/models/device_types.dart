import 'package:keeptrack/models/manufacturer.dart';

class DeviceType {
  final int id;
  final String name;
  final String url;
  final Manufacturer manufacturer;
  final String modelName;

  DeviceType({
    required this.id,
    required this.name,
    required this.url,
    required this.manufacturer,
    required this.modelName,
  });

  factory DeviceType.fromJson(Map<String, dynamic> json) {
    return DeviceType(
      id: json['id'],
      name: json['display'],
      url: json['url'],
      manufacturer: Manufacturer.fromJson(json['manufacturer']),
      modelName: json['model'],
    );
  }
}
