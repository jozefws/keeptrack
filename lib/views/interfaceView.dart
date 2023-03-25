import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:keeptrack/api/cables_api.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/interfaces_api.dart';
import 'package:keeptrack/api/powerfeeds_api.dart';
import 'package:keeptrack/api/poweroutlets_api.dart';
import 'package:keeptrack/api/powerport_api.dart';
import 'package:keeptrack/models/cables.dart';
import 'package:keeptrack/models/devices.dart';
import 'package:keeptrack/models/interfaceComboModel.dart';
import 'package:keeptrack/models/interfaces.dart';
import 'package:keeptrack/models/powerfeed.dart';
import 'package:keeptrack/models/poweroutlet.dart';
import 'package:keeptrack/models/powerport.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';

class ComboView extends StatefulWidget {
  const ComboView(this.combo, {super.key});
  final ComboModel combo;

  @override
  State<ComboView> createState() => _ComboViewState();
}

class _ComboViewState extends State<ComboView> {
  CablesAPI cablesAPI = CablesAPI();
  DevicesAPI devicesAPI = DevicesAPI();
  InterfacesAPI interfacesAPI = InterfacesAPI();
  PowerOutletsAPI poweroutletAPI = PowerOutletsAPI();
  PowerPortsAPI powerportAPI = PowerPortsAPI();
  PowerFeedsAPI powerfeedsAPI = PowerFeedsAPI();

  getToken() async {
    return await NetboxAuthProvider().getToken();
  }

  Future<Cable?> _getCableByID(String cableID) async {
    if (cableID == '') {
      return null;
    }

    var i = await cablesAPI.getCableByID(await getToken(), cableID);
    if (i != null) {
      return i;
    } else {
      return null;
    }
  }

  Future<Device?> _getDeviceByID(String deviceID) async {
    if (deviceID == '') {
      return null;
    }
    var i = await DevicesAPI().getDeviceByID(await getToken(), deviceID);
    return i;
  }

  Future<Interface?> _getInterfaceByID(String interfaceID) async {
    if (interfaceID == '') {
      return null;
    }
    var i = await interfacesAPI.getInterfaceByID(await getToken(), interfaceID);
    if (i != null) {
      return i;
    } else {
      return null;
    }
  }

  Future<PowerOutlet?> _getPowerOutletByID(String powerOutletID) async {
    if (powerOutletID == '') {
      return null;
    }
    PowerOutlet? powerOutlet = await poweroutletAPI.getPowerOutletByID(
        await getToken(), powerOutletID);
    if (powerOutlet != null) {
      return powerOutlet;
    } else {
      return null;
    }
  }

  Future<PowerPort?> _getPowerPortByID(String powerPortID) async {
    if (powerPortID == '') {
      return null;
    }
    PowerPort? powerPort =
        await powerportAPI.getPowerPortByID(await getToken(), powerPortID);
    if (powerPort != null) {
      return powerPort;
    } else {
      return null;
    }
  }

  Future<PowerFeed?> _getPowerFeedByID(String powerFeedID) async {
    if (powerFeedID == '') {
      return null;
    }
    PowerFeed? powerFeed =
        await powerfeedsAPI.getPowerFeedByID(await getToken(), powerFeedID);
    if (powerFeed != null) {
      return powerFeed;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          title: Text(widget.combo.name),
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
        body: displayCombo(widget.combo));
  }

  displayCombo(ComboModel combo) {
    String cableID = combo.interface?.cableID.toString() ??
        combo.powerOutlet?.cable?.id.toString() ??
        combo.powerPort?.cable?.id.toString() ??
        "";

    if (cableID == "") {
      return const Center(child: Text("Error, no cable found"));
    }

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
                  cable.terminationAType != "dcim.powerfeed"
                      ? displayDeviceCard(
                          cable,
                          cable.terminationADeviceID,
                          cable.terminationAId,
                          Theme.of(context).colorScheme.tertiaryContainer)
                      : displayRootFeedCard(
                              cable.terminationAId,
                              Theme.of(context)
                                  .colorScheme
                                  .tertiaryContainer) ??
                          const SizedBox(height: 0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      filterPortType(
                          cable.terminationAType ?? "",
                          cable.terminationAId.toString(),
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
                        color: cable.color == ""
                            ? Colors.white
                            : Color(int.parse("0xFF${cable.color}")),
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
                      filterPortType(
                          cable.terminationBType ?? "",
                          cable.terminationBId.toString(),
                          Theme.of(context).colorScheme.primaryContainer),
                    ],
                  ),
                  cable.terminationBType != "dcim.powerfeed"
                      ? displayDeviceCard(
                          cable,
                          cable.terminationBDeviceID,
                          cable.terminationBId,
                          Theme.of(context).colorScheme.tertiaryContainer)
                      : displayRootFeedCard(
                              cable.terminationBId,
                              Theme.of(context)
                                  .colorScheme
                                  .tertiaryContainer) ??
                          const SizedBox(height: 0),
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
                          style: Theme.of(context).textTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis),
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
                          return SizedBox();
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

  displayInterfaceCard(String interfaceID, Color primaryContainer) {
    return FutureBuilder(
        future: _getInterfaceByID(interfaceID),
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
                        style: Theme.of(context).textTheme.titleSmall),
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

  displayPowerCard(String powerportID, Color primaryContainer) {
    return FutureBuilder(
        future: _getPowerPortByID(powerportID),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var powerport = snapshot.data as PowerPort;
            return Card(
              color: primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    //device A name
                    Text(powerport.name,
                        style: Theme.of(context).textTheme.titleSmall),
                    const Text(" | "),
                    //show the text after the first (
                    Text(
                        "${powerport.allocatedDraw}W/${powerport.maximumDraw}W",
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            );
          } else {
            return Center(
                child: Column(
              children: const [
                Text("Trying to load power port..."),
                SizedBox(height: 10),
                CircularProgressIndicator(),
              ],
            ));
          }
        });
  }

  displayOutletCard(String outletID, Color primaryContainer) {
    return FutureBuilder(
        future: _getPowerOutletByID(outletID),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var poweroutlet = snapshot.data as PowerOutlet;
            return Card(
              color: primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    //device A name
                    Text(poweroutlet.name,
                        style: Theme.of(context).textTheme.titleSmall),
                    const Text(" | "),
                    //show the text after the first (
                    Text(poweroutlet.typeLabel,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            );
          } else {
            return Center(
                child: Column(
              children: const [
                Text("Trying to load power outlet..."),
                SizedBox(height: 10),
                CircularProgressIndicator(),
              ],
            ));
          }
        });
  }

  displayRootFeedCard(feedID, color) {
    return FutureBuilder(
      future: _getPowerFeedByID(feedID),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var feed = snapshot.data as PowerFeed;
          return Card(
            color: color,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      //device A name
                      Text(feed.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      //device A type
                      Text(feed.powerPanel.display,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      //device A type
                      Text(feed.phaseLabel ?? "",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text(" | "),
                      Text("${feed.voltage ?? ""} V",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text(" | "),
                      Text("${feed.amperage ?? ""} A",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else {
          return Center(
              child: Column(
            children: const [
              Text("Trying to load circuit feed..."),
              SizedBox(height: 10),
              CircularProgressIndicator(),
            ],
          ));
        }
      },
    );
  }

  displayFeedCard(String feedID, Color primaryContainer) {
    return FutureBuilder(
        future: _getPowerFeedByID(feedID),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var powerfeed = snapshot.data as PowerFeed;
            return Card(
              color: primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    //device A name
                    Text(powerfeed.name,
                        style: Theme.of(context).textTheme.titleSmall),
                    const Text(" | "),
                    //show the text after the first (
                    Text("${powerfeed.amperage}A",
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            );
          } else {
            return Center(
                child: Column(
              children: const [
                Text("Trying to load powerfeed..."),
                SizedBox(height: 10),
                CircularProgressIndicator(),
              ],
            ));
          }
        });
  }

  filterPortType(String type, String string, Color primaryContainer) {
    print(type);
    if (type == "dcim.interface") {
      return displayInterfaceCard(string, primaryContainer);
    } else if (type == "dcim.powerport") {
      return displayPowerCard(string, primaryContainer);
    } else if (type == "dcim.poweroutlet") {
      return displayOutletCard(string, primaryContainer);
    } else if (type == "dcim.powerfeed") {
      return displayFeedCard(string, primaryContainer);
    } else {
      print(type);
      return const Text("Error");
    }
  }
}
