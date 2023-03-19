class Trace {
  final int id;
  final String name;
  final String url;

  Trace({
    required this.id,
    required this.name,
    required this.url,
  });

  factory Trace.fromJson(Map<String, dynamic> json) {
    return Trace(
      id: json['id'],
      name: json['name'],
      url: json['url'],
    );
  }
}
