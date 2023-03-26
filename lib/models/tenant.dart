class Tenant {
  final int id;
  final String name;
  final String url;
  final String? groupName;
  final int? deviceCount;

  Tenant({
    required this.id,
    required this.name,
    required this.url,
    this.groupName,
    this.deviceCount,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    String gn;
    // check if json has a group attribute
    if (json['group'] != null) {
      gn = json['group']['name'];
    } else {
      gn = '';
    }
    return Tenant(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      groupName: gn,
      deviceCount: json['device_count'] ?? 0,
    );
  }
}
