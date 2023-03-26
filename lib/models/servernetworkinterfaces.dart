class ServerNetworkInterfaces {
  final String? firmwareVersion;
  final String? driver;
  final String? interfaceName;
  final List<SNIList>? interfaces;

  ServerNetworkInterfaces(
      {this.firmwareVersion, this.driver, this.interfaceName, this.interfaces});

  factory ServerNetworkInterfaces.fromJson(Map<String, dynamic> json) {
    return ServerNetworkInterfaces(
      firmwareVersion: json['fw'] ?? "",
      driver: json['driver'] ?? "",
      interfaceName: json['ifname'],
      interfaces:
          (json['interfaces'] as List).map((e) => SNIList.fromJson(e)).toList(),
    );
  }
}

class SNIList {
  final String? MAC;
  final String? IP;
  final String? HostName;
  final String? IFace;
  final String? speed;

  SNIList({this.MAC, this.IP, this.HostName, this.IFace, this.speed});

  factory SNIList.fromJson(Map<String, dynamic> json) {
    return SNIList(
      MAC: json['mac'] ?? "",
      IP: json['ipaddr'] ?? "",
      HostName: json['hostname'] ?? "",
      IFace: json['iface'] ?? "",
      speed: json['speed'] ?? "",
    );
  }
}
