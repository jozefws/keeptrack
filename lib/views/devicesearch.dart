import 'package:flutter/material.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/interfaces_api.dart';
import 'package:keeptrack/models/devices.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/views/deviceview.dart';
import 'package:searchable_listview/searchable_listview.dart';

class DeviceSearch extends StatefulWidget {
  const DeviceSearch({super.key});
  @override
  State<DeviceSearch> createState() => _DeviceInterfaceState();
}

class _DeviceInterfaceState extends State<DeviceSearch> {
  // Define the API classes to use in this view
  InterfacesAPI interfacesAPI = InterfacesAPI();
  DevicesAPI devicesAPI = DevicesAPI();

  // Define the variables to use in this view
  String deviceName = "Search for a device";
  Device? device;

  // Define the keys for the form
  final _searchDeviceKey = GlobalKey<FormState>();

  // Get the token from the provider
  getToken() async {
    return await NetboxAuthProvider().getToken();
  }

  // Show a snack bar with a message
  genSnack(String message) {
    hideSnack();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Hide the snack bar
  hideSnack() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  // Get the list of devices from the API
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
                  // Filter function to search the list as you type
                  asyncListCallback: () => _getDevices(),
                  asyncListFilter: (q, list) {
                    return list
                        .where((element) => element.name
                            .toLowerCase()
                            .contains(q.toLowerCase()))
                        .toList();
                  },
                  loadingWidget: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Loading devices..."),
                      ],
                    ),
                  ),
                  inputDecoration: InputDecoration(
                      filled: true,
                      labelText: "Search for a device",
                      border: const OutlineInputBorder(),
                      fillColor: Theme.of(context).colorScheme.surface),
                  builder: (device) => ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
