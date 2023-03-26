class Manufacturer {
  final int id;
  final String name;
  final String url;

  Manufacturer({
    required this.id,
    required this.name,
    required this.url,
  });

  factory Manufacturer.fromJson(Map<String, dynamic> json) {
    return Manufacturer(
      id: json['id'],
      name: json['name'],
      url: json['url'],
    );
  }
}
