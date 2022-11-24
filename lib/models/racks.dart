import 'package:keeptrack/models/tenant.dart';

class Rack {
  final int id;
  final String name;
  final String url;
  final Tenant? tenant;
  final int? deviceCount;
  final int? powerFeedCount;

  Rack({
    required this.id,
    required this.name,
    required this.url,
    this.tenant,
    this.deviceCount,
    this.powerFeedCount,
  });

  factory Rack.fromJson(Map<String, dynamic> json) {
    return Rack(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      tenant: json['tenant'] != null ? Tenant.fromJson(json['tenant']) : null,
      deviceCount: json['device_count'],
      powerFeedCount: json['powerfeed_count'],
    );
  }
}
