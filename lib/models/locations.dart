class Location {
  final int id;
  final String display;
  final Location? parent;

  Location({
    required this.id,
    required this.display,
    this.parent,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      display: json['display'],
      parent: json['parent'] != null ? Location.fromJson(json['parent']) : null,
    );
  }
}
