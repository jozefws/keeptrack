import 'package:keeptrack/models/customfields.dart';
import 'package:keeptrack/models/device_role.dart';
import 'package:keeptrack/models/device_types.dart';
import 'package:keeptrack/models/ip_addresses.dart';
import 'package:keeptrack/models/locations.dart';
import 'package:keeptrack/models/manufacturer.dart';
import 'package:keeptrack/models/racks.dart';
import 'package:keeptrack/models/tenant.dart';
import 'package:keeptrack/models/tags.dart';

class Device {
  final int id;
  final String name;
  final String? assetTag;
  final String? serial;
  final String url;
  final DeviceType? deviceType;
  final DeviceRole? deviceRole;
  final Manufacturer? manufacturer;
  final Rack? rack;
  final Tenant? tenant;
  final int? position;
  final String? facingPosition;
  final IPAddress? primaryIP;
  final String? comments;
  final String? description;
  final String? status;
  final List<Tag>? tags;
  final Location? location;
  final CustomFields? customFields;

  Device(
      {required this.id,
      required this.name,
      required this.url,
      this.assetTag,
      this.serial,
      this.deviceType,
      this.deviceRole,
      this.manufacturer,
      this.rack,
      this.tenant,
      this.position,
      this.facingPosition,
      this.primaryIP,
      this.comments,
      this.description,
      this.status,
      this.tags,
      this.location,
      this.customFields});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
        id: json['id'],
        name: json['name'],
        url: json['url'],
        assetTag: json['asset_tag'],
        serial: json['serial'],
        deviceType: json['device_type'] != null
            ? DeviceType.fromJson(json['device_type'])
            : null,
        deviceRole: json['device_role'] != null
            ? DeviceRole.fromJson(json['device_role'])
            : null,
        manufacturer: json['manufacturer'] != null
            ? Manufacturer.fromJson(json['manufacturer'])
            : null,
        rack: json['rack'] != null ? Rack.fromJson(json['rack']) : null,
        tenant: json['tenant'] != null ? Tenant.fromJson(json['tenant']) : null,
        position: json['position']?.round() ?? 0,
        facingPosition: json['face']?['label'],
        primaryIP: json['primary_ip']?['address'] != null
            ? IPAddress.fromJson(json['primary_ip'])
            : null,
        comments: json['comments'],
        description: json['description'],
        status: json['status']?['label'],
        location: json['location'] != null
            ? Location.fromJson(json['location'])
            : null,
        tags: json['tags'] != null
            ? List<Tag>.from(json['tags'].map((x) => Tag.fromJson(x)))
            : null,
        customFields: json['custom_fields'] != null
            ? CustomFields.fromJson(json['custom_fields'])
            : null);
  }
}
