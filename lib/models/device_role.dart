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
