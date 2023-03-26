import 'package:keeptrack/models/cables.dart';

import 'devices.dart';

class PowerPort {
  final int id;
  final String url;
  final String display;
  final Device? device;
  final String name;
  final String? label;
  final String? typeValue;
  final String? typeLabel;
  final int? maximumDraw;
  final int? allocatedDraw;
  final Cable? cable;
  final bool occupied;

  PowerPort({
    required this.id,
    required this.url,
    required this.display,
    required this.device,
    required this.name,
    this.label,
    this.typeValue,
    this.typeLabel,
    this.maximumDraw,
    this.allocatedDraw,
    required this.cable,
    required this.occupied,
  });

  factory PowerPort.fromJson(Map<String, dynamic> json) {
    return PowerPort(
      id: json['id'],
      url: json['url'],
      display: json['display'],
      device: Device.fromJson(json['device']),
      name: json['name'],
      label: json['label'],
      typeValue: json['type']['value'],
      typeLabel: json['type']['label'],
      maximumDraw: json['maximum_draw'],
      allocatedDraw: json['allocated_draw'],
      cable: json['cable'] != null ? Cable.fromJson(json['cable']) : null,
      occupied: json['_occupied'] ?? false,
    );
  }
}
