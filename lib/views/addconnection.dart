import 'package:flutter/material.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/interfaces_api.dart';
import 'package:keeptrack/api/racks_api.dart';
import 'package:keeptrack/models/devices.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';

class AddConnection extends StatefulWidget {
  const AddConnection({super.key});

  @override
  State<AddConnection> createState() => _AddConnectionState();
}

class _AddConnectionState extends State<AddConnection>
    with
        AutomaticKeepAliveClientMixin<AddConnection>,
        SingleTickerProviderStateMixin<AddConnection> {
  final _addConnectionKey = GlobalKey<FormState>();
  TabController? _tabController;

  List<DropdownMenuItem<String>>? racksA,
      racksB,
      devicesA,
      devicesB,
      interfacesA,
      interfacesB;

  String? rackA, rackB, deviceA, deviceB, interfaceA, interfaceB;

  // var _rackAController = TextEditingController();
  // var _deviceAController = TextEditingController();
  // var _interfaceAController = TextEditingController();
  // var _rackBController = TextEditingController();
  // var _deviceBController = TextEditingController();
  // var _interfaceBController = TextEditingController();

  Future<List<DropdownMenuItem<String>>> _getRacks() async {
    var i = await RacksAPI.getRacks(await getToken());
    var mapped = i
        .map((e) => DropdownMenuItem(
              value: e.id.toString(),
              child: Text(e.name),
            ))
        .toList();
    return mapped;
  }

  Future<List<DropdownMenuItem<String>>> _getDevicesByRack(
      String rackID) async {
    final i = await DevicesAPI.getDevicesByRack(await getToken(), rackID);
    if (i == []) {
      const SnackBar(content: Text('Error: No devices found'));
    }
    var mapped = i
        .map((e) => DropdownMenuItem(
              value: e.id.toString(),
              child: Text(e.name),
            ))
        .toList();
    //list mapped to dropdown menu items

    return mapped;
  }

  Future<List<DropdownMenuItem<String>>?> _getInterfacesByDevice(
      int deviceID) async {
    final i =
        await InterfacesAPI.getInterfacesByDevice(await getToken(), deviceID);
    if (i == []) {
      const SnackBar(content: Text('Error: No interfaces found'));
    }
    var mapped = i
        .map((e) => DropdownMenuItem(
              value: e.id.toString(),
              child: Text(e.name),
            ))
        .toList();
    var prev = "";
    for (var item in mapped) {
      if (prev == item.value) {
        print("FUCKFUCKFUCK int ${item.value}");
      }
    }
    return mapped;
  }

  @override
  initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  setDevices(List<DropdownMenuItem<String>>? items, String rackID) async {
    var temp = await _getDevicesByRack(rackID);
    setState(() {
      items = temp;
    });
  }

  getToken() async {
    return await NetboxAuthProvider().getToken();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Form(
        key: _addConnectionKey,
        child: Column(children: [
          TabBar(controller: _tabController, tabs: const [
            Tab(
              text: 'Device A',
            ),
            Tab(
              text: 'Device B',
            ),
          ]),
          Expanded(
              child: TabBarView(controller: _tabController, children: [
            Container(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text('Choose Rack', style: TextStyle(fontSize: 18)),
                  FutureBuilder(
                      future: _getRacks(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          var data = snapshot.data!;
                          return DropdownButtonFormField(
                              value: rackA,
                              items: data,
                              onChanged: (value) {
                                setState(() {
                                  rackA = value ?? "1";
                                  devicesA = null;
                                  deviceA = null;
                                });
                              },
                              decoration: const InputDecoration(
                                  labelText: 'Rack',
                                  hintText: 'Select a rack'));
                        } else {
                          return const CircularProgressIndicator();
                        }
                      }),
                  const SizedBox(height: 20),
                  const Text('Choose Device', style: TextStyle(fontSize: 18)),
                  FutureBuilder(
                      future: _getDevicesByRack(rackA ?? ""),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          var data = snapshot.data!;
                          return DropdownButtonFormField(
                              value: deviceA,
                              items: data,
                              onChanged: (String? value) {
                                setState(() {
                                  deviceA = value;
                                  interfaceA = "";
                                });
                              },
                              decoration: const InputDecoration(
                                  labelText: 'Device',
                                  hintText: 'Select a device'));
                        } else {
                          return const CircularProgressIndicator();
                        }
                      }),
                  const SizedBox(height: 20),
                  const Text('Choose Interface',
                      style: TextStyle(fontSize: 18)),
                  DropdownButtonFormField(
                    //if interfaces is empty, show default item
                    items: interfacesA,
                    onChanged: (value) {
                      setState(() {
                        interfaceA = value ?? "0";
                      });
                    },
                  ),
                ],
              ),
            ),
            Container(
              child: Text('Device B'),
            )
          ]))
        ]));
  }

  @override
  bool get wantKeepAlive => true;
}
