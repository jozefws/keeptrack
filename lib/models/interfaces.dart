import 'package:keeptrack/models/cables.dart';

import 'devices.dart';

class Interface {
  final int id;
  final String name;
  final String url;
  final Device device;
  final String typeValue;
  final String typeLabel;
  final String? macAddress;
  final int? cableID;
  final bool occupied;

  Interface(
      {required this.id,
      required this.name,
      required this.url,
      required this.device,
      required this.typeValue,
      required this.typeLabel,
      this.cableID,
      required this.occupied,
      this.macAddress});

  factory Interface.fromJson(Map<String, dynamic> json) {
    return Interface(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      device: Device.fromJson(json['device']),
      typeValue: json['type']['value'],
      typeLabel: json['type']['label'],
      cableID: json['cable'] != null ? json['cable']['id'] : null,
      occupied: json['_occupied'] ?? false,
      macAddress: json['mac_address'],
    );
  }
}
