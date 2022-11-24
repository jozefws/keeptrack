import 'package:keeptrack/models/device_types.dart';
import 'package:keeptrack/models/ip_addresses.dart';
import 'package:keeptrack/models/manufacturer.dart';
import 'package:keeptrack/models/racks.dart';
import 'package:keeptrack/models/tenant.dart';

class Device {
  final int id;
  final String name;
  final String url;
  final DeviceType? deviceType;
  final Manufacturer? manufacturer;
  final Rack? rack;
  final Tenant? tenant;
  final String? position;
  final IPAddress? primaryIP;
  final String? comments;

  Device(
      {required this.id,
      required this.name,
      required this.url,
      this.deviceType,
      this.manufacturer,
      this.rack,
      this.tenant,
      this.position,
      this.primaryIP,
      this.comments});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
        id: json['id'],
        name: json['name'],
        url: json['url'],
        deviceType: json['device_type'] != null
            ? DeviceType.fromJson(json['device_type'])
            : null,
        manufacturer: json['manufacturer'] != null
            ? Manufacturer.fromJson(json['manufacturer'])
            : null,
        rack: json['rack'] != null ? Rack.fromJson(json['rack']) : null,
        tenant: json['tenant'] != null ? Tenant.fromJson(json['tenant']) : null,
        position: json['position'].toString(),
        primaryIP: json['primary_ip'] != null
            ? IPAddress.fromJson(json['primary_ip'])
            : null,
        comments: json['comments']);
  }
}
