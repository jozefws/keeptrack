import 'servernetworkinterfaces.dart';

class CustomFields {
  final String? supportDocsLink;
  final String? firmware;
  final List<ServerNetworkInterfaces?> serverNetworkInterfaces;
  final String? cpuType;
  final String? cpuCount;
  final String? cpuCores;
  final String? cpuThreads;
  final String? serverRam;

  CustomFields({
    this.supportDocsLink,
    this.firmware,
    this.serverNetworkInterfaces = const [],
    this.cpuType,
    this.cpuCount,
    this.cpuCores,
    this.cpuThreads,
    this.serverRam,
  });

  factory CustomFields.fromJson(Map<String, dynamic> json) {
    return CustomFields(
      supportDocsLink: json['support_docs_link'] ?? "",
      firmware: json['firmware'].toString(),
      serverNetworkInterfaces: json['server_network_interfaces'] != null
          ? List<ServerNetworkInterfaces?>.from(
              json['server_network_interfaces'].map((x) =>
                  x != null ? ServerNetworkInterfaces.fromJson(x) : null))
          : [],
      cpuType: json['server_cpu_info']?['cpu_type'],
      cpuCount: json['server_cpu_info']?['cpu_count'].toString(),
      cpuCores: json['server_cpu_info']?['conf_cores'].toString(),
      cpuThreads: json['server_cpu_info']?['conf_threads'].toString(),
      serverRam: filterRam(json['server_ram_info']),
    );
  }

  static filterRam(json) {
    if (json == null) {
      return "null";
    }
    if (json is String) {
      return json;
    }
    if (json is Map<String, dynamic>) {
      if (json['total'] != null) {
        return json['total'];
      }
      if (json['used'] != null) {
        return json['used'];
      }
    }
    return "null";
  }
}
