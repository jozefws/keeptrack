import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:keeptrack/api/deviceTypes_api.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/models/device_types.dart';
import 'package:keeptrack/models/devices.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/views/hierarchysearch.dart';
import 'package:keeptrack/views/interfaceView.dart';

class DeviceView extends StatefulWidget {
  const DeviceView(this.deviceName, this.deviceID, {super.key});
  final String deviceName;
  final int deviceID;

  @override
  State<DeviceView> createState() => _DeviceViewState();
}

class _DeviceViewState extends State<DeviceView> {
  DevicesAPI devicesAPI = DevicesAPI();
  DeviceTypesAPI deviceTypesAPI = DeviceTypesAPI();

  Future<Device?> getDeviceById() async {
    var i = await devicesAPI.getDeviceByID(
        await getToken(), widget.deviceID.toString());
    return i;
  }

  Future<DeviceType?> getDeviceTypeById(int id) async {
    var i =
        await deviceTypesAPI.getDeviceTypeById(await getToken(), id.toString());
    if (i != null) {
      return i;
    }
    return null;
  }

  getToken() async {
    return await NetboxAuthProvider().getToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text(widget.deviceName),
        titleTextStyle: const TextStyle(fontSize: 16),
      ),
      persistentFooterButtons: [
        FloatingActionButton.extended(
          heroTag: "newSearch",
          onPressed: () {
            Navigator.popUntil(context, ModalRoute.withName("/"));
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text("New Search"),
        ),
        FloatingActionButton.extended(
          heroTag: "viewInterfaces",
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HierarchySearch(
                        widget.deviceName, widget.deviceID, "DEVICE")));
          },
          icon: const Icon(Icons.settings_ethernet),
          label: const Text("View Interfaces"),
        ),
      ],
      resizeToAvoidBottomInset: false,
      // display all racks in a vertical list
      body: FutureBuilder(
          future: getDeviceById(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data != null) {
                return Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: displayDevice(snapshot.data!));
              } else {
                return errorDisplayingDevice();
              }
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
    );
  }

  displayDevice(Device device) {
    return Container(
      height: MediaQuery.of(context).size.height,
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.left,
                    ),
                    Text(
                      "${device.rack?.name} > U${device.position} (${device.facingPosition})",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      "Primary IP: ${device.primaryIP?.address ?? "Undefined"}",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ],
            ),

            //scrollable row of tags as chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Chip(
                      side: BorderSide.none,
                      label: Text(
                        device.status!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: device.status == "Active"
                          ? Colors.green
                          : Colors.deepOrange),
                  const SizedBox(
                    width: 8,
                  ),
                  // display tags as chips and background color from the color of the tag
                  Wrap(
                    spacing: 8,
                    children: device.tags!
                        .map((e) => Chip(
                              label: Text(e.name),
                              backgroundColor:
                                  Color(int.parse("0xFF${e.color}")),
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),

        const Divider(),
        // expandable list
        Expanded(
          child: ListView(
            children: [
              ExpansionTile(
                expandedAlignment: Alignment.centerLeft,
                title: const Text("Device Details"),
                childrenPadding: EdgeInsets.fromLTRB(16, 0, 0, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("Device Type: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(device.deviceType?.name ?? "Undefined"),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("Asset Tag: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(device.assetTag ?? "Undefined"),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("Serial Number: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(device.serial ?? "Undefined"),
                    ],
                  ),
                ],
              ),
              ExpansionTile(
                expandedAlignment: Alignment.centerLeft,
                title: const Text("Model Details"),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 0, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder(
                    future: getDeviceTypeById(device.deviceType!.id),
                    builder: (context, snapshot) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              const Text("Manufacturer: ",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(device.deviceType!.manufacturer!.name),
                            ],
                          ),
                          Row(
                            children: [
                              const Text("Model: ",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(device.deviceType!.name),
                            ],
                          ),
                          Row(
                            children: [
                              const Text("Unit Height: ",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(snapshot.data?.unitHeight ?? "Undefined"),
                            ],
                          ),
                          Row(
                            children: [
                              const Text("Weight: ",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text("${snapshot.data?.weight ?? "Undefined"}"),
                              Text(snapshot.data?.weightUnit ?? ""),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              // expandable list
              ExpansionTile(
                expandedAlignment: Alignment.centerLeft,
                title: const Text("Tenancy"),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 0, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("Tenant: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(device.tenant?.name ?? "None"),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("Rack: ",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(device.rack?.name ?? "None"),
                    ],
                  ),
                ],
              ),
            ],
          ),
        )
      ]),
    );
  }

  errorDisplayingDevice() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Error displaying device",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(
            height: 16,
          ),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Go Back"))
        ],
      ),
    );
  }
}
