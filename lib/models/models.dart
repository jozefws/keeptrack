class Model {
  final int id;
  final String name;
  final String url;

  Model({
    required this.id,
    required this.name,
    required this.url,
  });

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      id: json['id'],
      name: json['name'],
      url: json['url'],
    );
  }
}
