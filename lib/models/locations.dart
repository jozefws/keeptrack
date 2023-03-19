class Location {
  final int id;
  final String display;
  final String slug;
  final Location? parent;

  Location({
    required this.id,
    required this.display,
    required this.slug,
    this.parent,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'],
      display: json['display'],
      slug: json['slug'] ?? "nullslug",
      parent: json['parent'] != null ? Location.fromJson(json['parent']) : null,
    );
  }
}
