import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:keeptrack/api/cables_api.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/interfaces_api.dart';
import 'package:keeptrack/models/cables.dart';
import 'package:keeptrack/models/devices.dart';
import 'package:keeptrack/models/interfaces.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';

class InterfaceView extends StatefulWidget {
  const InterfaceView(this.interface, {super.key});
  final Interface interface;

  @override
  State<InterfaceView> createState() => _InterfaceViewState();
}

class _InterfaceViewState extends State<InterfaceView> {
  CablesAPI cablesAPI = CablesAPI();
  DevicesAPI devicesAPI = DevicesAPI();
  InterfacesAPI interfacesAPI = InterfacesAPI();

  getToken() async {
    return await NetboxAuthProvider().getToken();
  }

  Future<Cable?> _getCableByID(String cableID) async {
    var i = await cablesAPI.getCableByID(await getToken(), cableID);
    if (i != null) {
      return i;
    } else {
      print("API: Error");
      return null;
    }
  }

  Future<Device?> _getDeviceByID(String deviceID) async {
    var i = await DevicesAPI().getDeviceByID(await getToken(), deviceID);
    return i;
  }

  Future<Interface?> _getInterfaceByID(String interfaceID) async {
    var i = await interfacesAPI.getInterfaceByID(await getToken(), interfaceID);
    if (i != null) {
      return i;
    } else {
      print("API: Error");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          title: Text(widget.interface.name),
          titleTextStyle: const TextStyle(fontSize: 16),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
        body: displayInterface(widget.interface.cableID.toString()));
  }

  displayInterface(cableID) {
    return FutureBuilder(
        future: _getCableByID(cableID),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var cable = snapshot.data as Cable;
            return Padding(
                padding: const EdgeInsets.fromLTRB(32.0, 16.0, 32.0, 4.0),
                child: ListView(children: [
                  //decode cable label in utf8
                  Center(
                    child: Text(
                      utf8.decode(cable.label.runes.toList()),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Device A",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  displayDeviceCard(
                      cable,
                      cable.terminationADeviceID,
                      cable.terminationAId,
                      Theme.of(context).colorScheme.secondaryContainer),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      displayInterfaceCard(cable.terminationAId.toString(),
                          Theme.of(context).colorScheme.primaryContainer),
                    ],
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(utf8.decode(cable.label.runes.toList()),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(cable.type ?? "",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w300)),
                      ],
                    ),
                    SizedBox(
                      width: 20,
                      height: 200,
                      child: VerticalDivider(
                        color: Color(int.parse("0xFF${cable.color}")),
                        thickness: 8,
                      ),
                    )
                  ]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Device B",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      displayInterfaceCard(cable.terminationBId.toString(),
                          Theme.of(context).colorScheme.primaryContainer),
                    ],
                  ),

                  displayDeviceCard(
                      cable,
                      cable.terminationBDeviceID,
                      cable.terminationBId,
                      Theme.of(context).colorScheme.tertiaryContainer),
                ]));
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }

  displayDeviceCard(cable, deviceID, interfaceID, color) {
    return FutureBuilder(
      future: _getDeviceByID(deviceID),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var device = snapshot.data as Device;
          return Card(
            color: color,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      //device A name
                      Text(device.name,
                          style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      //device A type
                      Text(device.deviceType?.manufacturer?.name ?? " ",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text(" | "),
                      Text(device.deviceType!.name,
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                  Row(
                    children: [
                      Text(device.location?.slug ?? " ",
                          style: Theme.of(context).textTheme.bodyLarge),
                      const Text(" | "),
                      Text(device.rack?.name ?? " ",
                          style: Theme.of(context).textTheme.bodyLarge),
                      const Text(" | "),
                      Text("U${device.position.toString()}",
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                  const Divider(
                    height: 20,
                    thickness: 2,
                    color: Colors.white,
                  ),
                  FutureBuilder(
                      future: _getInterfaceByID(interfaceID),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          var interface = snapshot.data as Interface;
                          return Row(
                            children: [
                              Text(device.primaryIP?.name ?? "",
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              const Spacer(),
                              Text(interface.macAddress ?? "",
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          );
                        } else {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                      })
                ],
              ),
            ),
          );
        } else {
          return Center(
              child: Column(
            children: const [
              Text("Trying to load device..."),
              SizedBox(height: 10),
              CircularProgressIndicator(),
            ],
          ));
        }
      },
    );
  }

  displayInterfaceCard(String interface, Color primaryContainer) {
    return FutureBuilder(
        future: _getInterfaceByID(interface),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var interface = snapshot.data as Interface;
            return Card(
              color: primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    //device A name
                    Text(interface.name,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const Text(" | "),
                    //show the text after the first (
                    Text(interface.typeLabel,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            );
          } else {
            return Center(
                child: Column(
              children: const [
                Text("Trying to load interface..."),
                SizedBox(height: 10),
                CircularProgressIndicator(),
              ],
            ));
          }
        });
  }
}
