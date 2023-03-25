import 'package:flutter/material.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/interfaces_api.dart';
import 'package:keeptrack/api/poweroutlets_api.dart';
import 'package:keeptrack/api/powerport_api.dart';
import 'package:keeptrack/api/racks_api.dart';
import 'package:keeptrack/models/devices.dart';
import 'package:keeptrack/models/interfaceComboModel.dart';
import 'package:keeptrack/models/interfaces.dart';
import 'package:keeptrack/models/poweroutlet.dart';
import 'package:keeptrack/models/powerport.dart';
import 'package:keeptrack/models/racks.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/views/interfaceView.dart';

class HierarchySearch extends StatefulWidget {
  const HierarchySearch(this.location, this.locationID, this.type, {super.key});
  final String location;
  final String type;
  final int locationID;
  @override
  State<HierarchySearch> createState() => _HierarchySearchState();
}

class _HierarchySearchState extends State<HierarchySearch> {
  RacksAPI racksAPI = RacksAPI();
  DevicesAPI devicesAPI = DevicesAPI();
  InterfacesAPI interfacesAPI = InterfacesAPI();
  PowerPortsAPI powerPortsAPI = PowerPortsAPI();
  PowerOutletsAPI powerOutletsAPI = PowerOutletsAPI();

  late Rack rack;
  late Device device;
  late ComboModel combo;

  getToken() async {
    return await NetboxAuthProvider().getToken();
  }

  Future<List<Rack>> _getRacksByLocation() async {
    var i =
        await racksAPI.getRacksByLocation(await getToken(), widget.location);
    return i;
  }

  Future<List<Device>> _getDevicesByRack() async {
    var i = await devicesAPI.getDevicesByRack(
        await getToken(), widget.locationID.toString());
    //sort by i.position descending
    i.sort((a, b) => b.position?.compareTo(a.position!) ?? 0);

    return i;
  }

  Future<List<Interface>?> _getInterfacesByDevice(String deviceID) async {
    if (deviceID == "") {
      return [];
    }
    final i =
        await interfacesAPI.getInterfacesByDevice(await getToken(), deviceID);
    return i;
  }

  Future<List<PowerPort>?> _getPowerPortsByDevice(String deviceID) async {
    if (deviceID == "") {
      return [];
    }
    final i =
        await powerPortsAPI.getPowerPortsByDevice(await getToken(), deviceID);
    return i;
  }

  Future<List<PowerOutlet>?> _getPowerOutletsByDevice(String deviceID) async {
    if (deviceID == "") {
      return [];
    }
    final i = await powerOutletsAPI.getPowerOutletsByDevice(
        await getToken(), deviceID);
    return i;
  }

  Future<List<ComboModel>> _getMixedPortsByDeviceID(String deviceID) async {
    if (deviceID == "") {
      return [];
    }
    final interfaces =
        interfacesAPI.getInterfacesByDevice(await getToken(), deviceID);
    final powerPorts =
        powerPortsAPI.getPowerPortsByDevice(await getToken(), deviceID);
    final powerOutlets =
        powerOutletsAPI.getPowerOutletsByDevice(await getToken(), deviceID);

    List<ComboModel> comboList = [];

    // map all interfaces, powerports and poweroutlets to a single list
    await Future.wait([interfaces, powerPorts, powerOutlets]).then((value) {
      value.forEach((element) {
        if (element != null) {
          element.forEach((e) {
            if (e is Interface) {
              comboList.add(ComboModel(
                  id: e.id,
                  name: e.name,
                  url: e.url,
                  objectType: "interface",
                  occupied: e.occupied,
                  interface: e));
            } else if (e is PowerPort) {
              comboList.add(ComboModel(
                  id: e.id,
                  name: e.name,
                  url: e.url,
                  objectType: "powerport",
                  occupied: e.occupied,
                  powerPort: e));
            } else if (e is PowerOutlet) {
              comboList.add(ComboModel(
                  id: e.id,
                  name: e.name,
                  url: e.url,
                  objectType: "poweroutlet",
                  occupied: e.occupied,
                  powerOutlet: e));
            }
          });
        }
      });
    });
    if (comboList.isEmpty) {
      return [];
    }
    return comboList;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // go to the next screen to display all devices in the rack
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          icon: const Icon(Icons.search),
          label: const Text("New Search"),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          title: Text(
            widget.location,
            overflow: TextOverflow.ellipsis,
          ),
          titleTextStyle: const TextStyle(fontSize: 16),
        ),
        // display all racks in a vertical list
        body: Column(
          children: [
            Expanded(
              child: filterDisplay(),
            ),
            // fab in the bottom right corner
          ],
        ));
  }

  filterDisplay() {
    if (widget.type == "LOCATION") {
      return rackList();
    } else if (widget.type == "RACK") {
      return deviceList();
    } else if (widget.type == "DEVICE") {
      return interfaceList();
    } else {
      return const Center(child: Text("No data"));
    }
  }

  rackList() {
    return FutureBuilder(
        future: _getRacksByLocation(),
        builder: (context, AsyncSnapshot<List<Rack>> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, color: Colors.deepOrange, size: 40),
                  Text("No racks/desks found",
                      style: Theme.of(context).textTheme.headlineLarge),
                ],
              ));
            }
            return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                      title: Row(
                        children: [
                          Text(snapshot.data![index].name),
                          const Spacer(),
                          Chip(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            label: Text(
                                "${snapshot.data![index].deviceCount} devices"),
                            side: BorderSide.none,
                          ),
                        ],
                      ),
                      minVerticalPadding: 10,
                      contentPadding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                      onTap: () {
                        rack = snapshot.data![index];
                        // go to the next screen to display all devices in the rack
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HierarchySearch(
                                    "${widget.location} < ${rack.name}",
                                    rack.id,
                                    "RACK")));
                      });
                });
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  deviceList() {
    return FutureBuilder(
        future: _getDevicesByRack(),
        builder: (context, AsyncSnapshot<List<Device>> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, color: Colors.deepOrange, size: 40),
                  Text("No devices found",
                      style: Theme.of(context).textTheme.headlineLarge),
                ],
              ));
            }
            return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                      title: Row(
                        children: [
                          Text(snapshot.data![index].name),
                          const SizedBox(width: 10),
                          const Spacer(),
                          Chip(
                              side: BorderSide.none,
                              label: Text(
                                  "U${snapshot.data![index].position == 0 ? "?" : snapshot.data![index].position}"),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer),
                          const Padding(padding: EdgeInsets.all(5)),
                        ],
                      ),
                      minVerticalPadding: 10,
                      contentPadding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                      onTap: () {
                        device = snapshot.data![index];
                        // go to search screen
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HierarchySearch(
                                    "${widget.location} < ${device.name}",
                                    device.id,
                                    "DEVICE")));
                      });
                });
          } else {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Loading devices...",
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
            ));
          }
        });
  }

  interfaceList() {
    return FutureBuilder(
        future: _getMixedPortsByDeviceID(widget.locationID.toString()),
        builder: (context, AsyncSnapshot<List<ComboModel>> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, color: Colors.deepOrange, size: 40),
                  Text("No interfaces found",
                      style: Theme.of(context).textTheme.headlineLarge),
                ],
              ));
            }
            return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                      title: Row(
                        children: [
                          Text(
                            snapshot.data![index].name,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          // if null only show the text in the (), e.g. (1GE)
                          Text(
                            snapshot.data![index].objectType == "interface"
                                ? " | (${snapshot.data![index].interface?.typeLabel})"
                                : "",
                            style: const TextStyle(fontWeight: FontWeight.w300),
                          ),
                        ],
                      ),
                      trailing: Chip(
                          side: BorderSide.none,
                          backgroundColor: snapshot.data![index].occupied
                              ? Colors.green
                              : Colors.deepOrange,
                          label: Icon(
                            snapshot.data![index].occupied
                                ? Icons.settings_ethernet
                                : Icons.close,
                            color: Colors.white,
                          )),
                      minVerticalPadding: 10,
                      contentPadding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                      onTap: () {
                        combo = snapshot.data![index];
                        // go to the next screen to display all devices in the rack
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ComboView(combo)));
                      });
                });
          } else {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Loading ports...",
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
            ));
          }
        });
  }
}
