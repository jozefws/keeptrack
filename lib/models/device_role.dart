import 'dart:ffi';

import 'package:keeptrack/models/device_types.dart';
import 'package:keeptrack/models/ip_addresses.dart';
import 'package:keeptrack/models/locations.dart';
import 'package:keeptrack/models/manufacturer.dart';
import 'package:keeptrack/models/racks.dart';
import 'package:keeptrack/models/tenant.dart';
import 'package:keeptrack/models/tags.dart';

class DeviceRole {
  final int id;
  final String url;
  final String display;
  final String name;
  final String slug;

  DeviceRole({
    required this.id,
    required this.url,
    required this.display,
    required this.name,
    required this.slug,
  });

  factory DeviceRole.fromJson(Map<String, dynamic> json) {
    return DeviceRole(
      id: json['id'],
      url: json['url'],
      display: json['display'],
      name: json['name'],
      slug: json['slug'],
    );
  }
}
