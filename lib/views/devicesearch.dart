import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/interfaces_api.dart';
import 'package:keeptrack/models/devices.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/views/deviceview.dart';
import 'package:keeptrack/views/hierarchysearch.dart';
import 'package:searchable_listview/searchable_listview.dart';

class DeviceSearch extends StatefulWidget {
  const DeviceSearch({super.key});
  @override
  State<DeviceSearch> createState() => _DeviceInterfaceState();
}

class _DeviceInterfaceState extends State<DeviceSearch> {
  InterfacesAPI interfacesAPI = InterfacesAPI();
  DevicesAPI devicesAPI = DevicesAPI();
  String deviceName = "Search for a device";
  Device? device;
  final _searchDeviceKey = GlobalKey<FormState>();

  getToken() async {
    return await NetboxAuthProvider().getToken();
  }

  genSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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

  Future<List<Device>> _getDevices() async {
    final d = await devicesAPI.getDevices(await getToken());
    return d;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _searchDeviceKey,
        child: Column(children: [
          Expanded(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SearchableList<Device>(
                  asyncListCallback: () => _getDevices(),
                  asyncListFilter: (q, list) {
                    return list
                        .where((element) => element.name
                            .toLowerCase()
                            .contains(q.toLowerCase()))
                        .toList();
                  },
                  inputDecoration: InputDecoration(
                      filled: true,
                      labelText: "Search for a device",
                      border: InputBorder.none,
                      fillColor: Theme.of(context).colorScheme.surface),
                  builder: (device) => ListTile(
                    contentPadding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                    tileColor: Theme.of(context).colorScheme.surface,
                    title: Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                        "${device.location?.display ?? ""} | ${device.rack?.name ?? "Unracked"} | U${device.position ?? "?"}"),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  DeviceView(device.name, device.id)));
                    },
                  ),
                )),
          )
        ]));
  }
}
