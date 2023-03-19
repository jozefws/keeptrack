class Location {
  final int id;
  final String name;
  final String url;

  Location({
    required this.id,
    required this.name,
    required this.url,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      name: json['display'],
      url: json['url'],
    );
  }
}
