import 'package:keeptrack/api/cables_api.dart';
import 'package:keeptrack/models/cables.dart';
import 'package:keeptrack/models/powerport.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';

import 'devices.dart';

class PowerOutlet {
  final int id;
  final String url;
  final String display;
  final Device? device;
  final String name;
  final String label;
  final String typeValue;
  final String typeLabel;
  final PowerPort? powerPort;
  final Cable? cable;
  final bool occupied;

  PowerOutlet({
    required this.id,
    required this.url,
    required this.display,
    required this.device,
    required this.name,
    required this.label,
    required this.typeValue,
    required this.typeLabel,
    required this.powerPort,
    required this.cable,
    required this.occupied,
  });

  static dynamic getToken() async {
    return await NetboxAuthProvider().getToken();
  }

  static Future<Cable?> getCable(String id) async {
    CablesAPI cablesAPI = CablesAPI();

    Cable? cable =
        await cablesAPI.getCableByID(await getToken(), id).then((value) {
      return value;
    });
    return cable;
  }

  static Cable? fetchCable(String id) {
    Future<Cable?> cable = getCable(id);
    cable.then((value) {
      return value;
    });
    return null;
  }

  factory PowerOutlet.fromJson(Map<String, dynamic> json) {
    PowerPort powerport = PowerPort(
      id: json['power_port']['id'],
      url: json['power_port']['url'],
      display: json['power_port']['display'],
      device: Device.fromJson(json['power_port']['device']),
      name: json['power_port']['name'],
      cable: fetchCable(json['power_port']['cable'].toString()),
      occupied: json['power_port']['_occupied'] ?? false,
    );

    return PowerOutlet(
      id: json['id'],
      url: json['url'],
      display: json['display'],
      device: Device.fromJson(json['device']),
      name: json['name'],
      label: json['label'],
      typeValue: json['type']['value'],
      typeLabel: json['type']['label'],
      powerPort: powerport,
      cable: json['cable'] != null ? Cable.fromJson(json['cable']) : null,
      occupied: json['_occupied'] ?? false,
    );
  }
}
