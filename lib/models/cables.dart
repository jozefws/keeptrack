import 'package:keeptrack/models/interfaces.dart';

class Cable {
  final int id;
  final String label;
  final String url;
  final Interface? terminationAId;
  final Interface? terminationBId;
  final String state;
  final String type;
  final String? color;

  Cable({
    required this.id,
    required this.label,
    required this.url,
    this.terminationAId,
    this.terminationBId,
    required this.state,
    required this.type,
    this.color,
  });

  factory Cable.fromJson(Map<String, dynamic> json) {
    return Cable(
      id: json['id'],
      label: json['display'],
      url: json['url'],
      terminationAId: json['termination_a'] != null
          ? Interface.fromJson(json['termination_a'][0]['object'])
          : null,
      terminationBId: json['termination_b'] != null
          ? Interface.fromJson(json['termination_b'][0]['object'])
          : null,
      state: json['status']['label'],
      type: json['type']['label'],
      color: json['color'],
    );
  }
}
