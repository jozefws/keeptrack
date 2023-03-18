import 'package:flutter/material.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/racks_api.dart';
import 'package:keeptrack/models/devices.dart';
import 'package:keeptrack/models/racks.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/views/deviceview.dart';

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
  late Rack rack;
  late Device device;

  getToken() async {
    return await NetboxAuthProvider().getToken();
  }

  Future<List<Rack>> _getRacksByLocation() async {
    var i =
        await racksAPI.getRacksByLocation(await getToken(), widget.location);
    print(i);
    return i;
  }

  Future<List<Device>> _getDevicesByRack() async {
    var i = await devicesAPI.getDevicesByRack(
        await getToken(), widget.locationID.toString());
    print(i);
    return i;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text(
          widget.location,
          overflow: TextOverflow.ellipsis,
        ),
        titleTextStyle: const TextStyle(fontSize: 16),
      ),
      // display all racks in a vertical list
      body: widget.type == "LOCATION" ? rackList() : deviceList(),
    );
  }

  rackList() {
    return FutureBuilder(
        future: _getRacksByLocation(),
        builder: (context, AsyncSnapshot<List<Rack>> snapshot) {
          if (snapshot.hasData) {
            print("snapshot.data!.length: ${snapshot.data!.length}");
            return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                      title: Text(snapshot.data![index].name),
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
            print("snapshot.data!.length: ${snapshot.data!.length}");
            return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                      title: Text(snapshot.data![index].name),
                      minVerticalPadding: 10,
                      contentPadding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                      onTap: () {
                        device = snapshot.data![index];
                        // go to the next screen to display all devices in the rack
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DeviceView(
                                    "${widget.location} < ${device.name}",
                                    device.id)));
                      });
                });
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }
}
