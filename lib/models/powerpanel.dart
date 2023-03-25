import 'package:keeptrack/models/locations.dart';

class PowerPanel {
  final int id;
  final String url;
  final String display;
  final Location? location;
  final String name;
  final int? powerFeedCount;

  PowerPanel({
    required this.id,
    required this.url,
    required this.display,
    this.location,
    required this.name,
    this.powerFeedCount,
  });

  factory PowerPanel.fromJson(Map<String, dynamic> json) {
    return PowerPanel(
      id: json['id'],
      url: json['url'],
      display: json['display'],
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
      name: json['name'],
      powerFeedCount: json['power_feeds_count'],
    );
  }
}
