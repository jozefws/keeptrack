import 'package:keeptrack/models/interfaces.dart';
import 'package:keeptrack/models/poweroutlet.dart';
import 'package:keeptrack/models/powerport.dart';

class ComboModel {
  final int id;
  final String name;
  final String url;
  final String objectType;
  final bool occupied;
  final Interface? interface;
  final PowerPort? powerPort;
  final PowerOutlet? powerOutlet;

  ComboModel({
    required this.id,
    required this.name,
    required this.url,
    required this.objectType,
    required this.occupied,
    this.interface,
    this.powerPort,
    this.powerOutlet,
  });
}
