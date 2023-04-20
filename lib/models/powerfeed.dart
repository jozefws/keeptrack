import 'package:keeptrack/models/cables.dart';
import 'package:keeptrack/models/powerpanel.dart';

class PowerFeed {
  final int id;
  final String url;
  final PowerPanel powerPanel;
  final String name;
  final String? statusValue;
  final String? statusLabel;
  final String? typeValue;
  final String? typeLabel;
  final String? supplyValue;
  final String? supplyLabel;
  final String? phaseValue;
  final String? phaseLabel;
  final String? voltage;
  final String? amperage;
  final String? maxUtilization;
  final Cable? cable;
  final bool occupied;

  PowerFeed({
    required this.id,
    required this.url,
    required this.powerPanel,
    required this.name,
    this.statusValue,
    this.statusLabel,
    this.typeValue,
    this.typeLabel,
    this.supplyValue,
    this.supplyLabel,
    this.phaseValue,
    this.phaseLabel,
    this.voltage,
    this.amperage,
    this.maxUtilization,
    required this.cable,
    required this.occupied,
  });

  factory PowerFeed.fromJson(Map<String, dynamic> json) {
    return PowerFeed(
      id: json['id'],
      url: json['url'],
      powerPanel: PowerPanel.fromJson(json['power_panel']),
      name: json['name'],
      statusValue: json['status']['value'],
      statusLabel: json['status']['label'],
      typeValue: json['type']['value'],
      typeLabel: json['type']['label'],
      supplyValue: json['supply']['value'],
      supplyLabel: json['supply']['label'],
      phaseValue: json['phase']['value'],
      phaseLabel: json['phase']['label'],
      voltage: json['voltage'].toString(),
      amperage: json['amperage'].toString(),
      maxUtilization: json['max_utilization'].toString(),
      cable: json['cable'] != null ? Cable.fromJson(json['cable']) : null,
      occupied: json['_occupied'] ?? false,
    );
  }
}
