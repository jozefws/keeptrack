class DeviceModel {
  final int id;
  final String name;
  final String url;

  DeviceModel({
    required this.id,
    required this.name,
    required this.url,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      name: json['name'],
      url: json['url'],
    );
  }
}
