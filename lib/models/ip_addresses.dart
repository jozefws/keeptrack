class IPAddress {
  final int id;
  final String name;
  final String url;
  final String address;

  IPAddress({
    required this.id,
    required this.name,
    required this.url,
    required this.address,
  });

  factory IPAddress.fromJson(Map<String, dynamic> json) {
    return IPAddress(
      id: json['id'],
      name: json['display'],
      url: json['url'],
      address: json['address'],
    );
  }
}
