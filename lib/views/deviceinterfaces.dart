import 'package:flutter/material.dart';
import 'package:keeptrack/api/interfaces_api.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';

class DeviceInterfaces extends StatefulWidget {
  const DeviceInterfaces({super.key});
  // final String device;
  // final int deviceID;
  @override
  State<DeviceInterfaces> createState() => _DeviceInterfaceState();
}

class _DeviceInterfaceState extends State<DeviceInterfaces> {
  InterfacesAPI interfacesAPI = InterfacesAPI();

  getToken() async {
    return await NetboxAuthProvider().getToken();
  }

  Future<List<DropdownMenuItem<String>>?> _getInterfacesByDevice(
      String deviceID) async {
    if (deviceID == "") {
      return [];
    }
    final i =
        await interfacesAPI.getInterfacesByDevice(await getToken(), deviceID);
    return i
        .map((e) => DropdownMenuItem(
              value: e.id.toString(),
              child: Text(e.name),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: const Text('Device Interfaces'),
        titleTextStyle: const TextStyle(fontSize: 16),
      ),
      body: const Center(
        child: Text('Device Interfaces'),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
