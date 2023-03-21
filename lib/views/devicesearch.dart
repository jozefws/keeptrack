import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/interfaces_api.dart';
import 'package:keeptrack/models/devices.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/views/deviceview.dart';
import 'package:keeptrack/views/hierarchysearch.dart';

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
        Container(
          color: Theme.of(context).colorScheme.onInverseSurface,
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
              child: Text(
                "Search for Device",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Container(
              margin: const EdgeInsets.all(24),
              child: DropdownSearch<Device>(
                itemAsString: (item) => item.name,
                dropdownBuilder: (context, item) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.all(10),
                    child: Text(
                      item?.name ?? deviceName,
                    ),
                  );
                },
                popupProps: PopupProps.modalBottomSheet(
                    showSearchBox: true,
                    searchDelay: const Duration(milliseconds: 100),
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: device?.name ?? deviceName,
                      ),
                    ),
                    modalBottomSheetProps: ModalBottomSheetProps(
                        isScrollControlled: true,
                        backgroundColor: Theme.of(context).primaryColor,
                        anchorPoint: const Offset(0.5, 5)),
                    constraints: const BoxConstraints(
                        maxHeight: 400, maxWidth: double.infinity),
                    itemBuilder: (context, item, isSelected) => Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.all(10),
                          child: Text(item.name),
                        )),
                asyncItems: (devList) => _getDevices(),
                onChanged: (value) {
                  setState(() {
                    deviceName = value?.name ?? "";
                    device = value;
                  });
                },
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              child: FloatingActionButton.extended(
                  heroTag: "deviceView",
                  onPressed: () {
                    if (deviceName == "") {
                      genSnack("Please select a location");
                      return;
                    }
                    //open material route to search by hierarchy
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              DeviceView(device?.name ?? "", device?.id ?? 0)),
                    );
                  },
                  label: const Text("View Device"),
                  icon: const Icon(Icons.search)),
            ),
          ]),
        ),
      ]),
    );
  }
}
