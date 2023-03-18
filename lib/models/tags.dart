class Tag {
  final int id;
  final String name;
  final String color;

  Tag({
    required this.id,
    required this.name,
    required this.color,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(id: json['id'], name: json['display'], color: json['color']);
  }
}
