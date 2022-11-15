class Rack {
  final int id;
  final String name;
  final String url;
  final int locationID;

  Rack({
    required this.id,
    required this.name,
    required this.url,
    required this.locationID,
  });

  factory Rack.fromJson(Map<String, dynamic> json) {
    return Rack(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      locationID: json['location']['id'],
    );
  }
}
