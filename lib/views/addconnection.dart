import 'package:flutter/material.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/interfaces_api.dart';
import 'package:keeptrack/api/racks_api.dart';
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

  String? rackA, rackB, deviceA, deviceB, interfaceA, interfaceB;

  // var _rackAController = TextEditingController();
  // var _deviceAController = TextEditingController();
  // var _interfaceAController = TextEditingController();
  // var _rackBController = TextEditingController();
  // var _deviceBController = TextEditingController();
  // var _interfaceBController = TextEditingController();

  Future<List<DropdownMenuItem<String>>> _getRacks() async {
    var i = await RacksAPI.getRacks(await getToken());
    return i
        .map((e) => DropdownMenuItem(
              value: e.id.toString(),
              child: Text(e.name),
            ))
        .toList();
  }

  Future<List<DropdownMenuItem<String>>> _getDevicesByRack(
      String rackID) async {
    if (rackID == "") {
      return [];
    }
    final i = await DevicesAPI.getDevicesByRack(await getToken(), rackID);
    if (i.isEmpty) {
      genSnack("No devices found");
    }
    return i
        .map((e) => DropdownMenuItem(
              value: e.id.toString(),
              child: Text(e.name),
            ))
        .toList();
  }

  Future<List<DropdownMenuItem<String>>?> _getInterfacesByDevice(
      String deviceID) async {
    if (deviceID == "") {
      return [];
    }
    final i =
        await InterfacesAPI.getInterfacesByDevice(await getToken(), deviceID);
    if (i.isEmpty) {
      genSnack("No interfaces found");
    }
    return i
        .map((e) => DropdownMenuItem(
              value: e.id.toString(),
              child: Text(e.name),
            ))
        .toList();
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

  genSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Error: $message")));
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
                                if (value != rackA) {
                                  setState(() {
                                    rackA = value;
                                    deviceA = null;
                                    interfaceA = null;
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                  labelText: 'Rack A',
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
                                if (value != deviceA) {
                                  setState(() {
                                    deviceA = value;
                                    interfaceA = null;
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                  labelText: 'Device A',
                                  hintText: 'Select a device'));
                        } else {
                          return const CircularProgressIndicator();
                        }
                      }),
                  const SizedBox(height: 20),
                  const Text('Choose Interface',
                      style: TextStyle(fontSize: 18)),
                  FutureBuilder(
                      future: _getInterfacesByDevice(deviceA ?? ""),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          var data = snapshot.data!;
                          return DropdownButtonFormField(
                              value: interfaceA,
                              items: data,
                              onChanged: (String? value) {
                                if (value != interfaceA) {
                                  setState(() {
                                    interfaceA = value;
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                  labelText: 'Interface A',
                                  hintText: 'Select a Interface'));
                        } else {
                          return const CircularProgressIndicator();
                        }
                      }),
                ],
              ),
            ),
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
                              value: rackB,
                              items: data,
                              onChanged: (value) {
                                if (value != rackB) {
                                  setState(() {
                                    rackB = value;
                                    deviceB = null;
                                    interfaceB = null;
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                  labelText: 'Rack B',
                                  hintText: 'Select a rack'));
                        } else {
                          return const CircularProgressIndicator();
                        }
                      }),
                  const SizedBox(height: 20),
                  const Text('Choose Device', style: TextStyle(fontSize: 18)),
                  FutureBuilder(
                      future: _getDevicesByRack(rackB ?? ""),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          var data = snapshot.data!;
                          return DropdownButtonFormField(
                              value: deviceB,
                              items: data,
                              onChanged: (String? value) {
                                if (value != deviceB) {
                                  setState(() {
                                    deviceB = value;
                                    interfaceB = null;
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                  labelText: 'Device B',
                                  hintText: 'Select a device'));
                        } else {
                          return const CircularProgressIndicator();
                        }
                      }),
                  const SizedBox(height: 20),
                  const Text('Choose Interface',
                      style: TextStyle(fontSize: 18)),
                  FutureBuilder(
                      future: _getInterfacesByDevice(deviceB ?? ""),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          var data = snapshot.data!;
                          return DropdownButtonFormField(
                              value: interfaceB,
                              items: data,
                              onChanged: (String? value) {
                                if (value != interfaceB) {
                                  setState(() {
                                    interfaceB = value;
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                  labelText: 'Interface B',
                                  hintText: 'Select a Interface'));
                        } else {
                          return const CircularProgressIndicator();
                        }
                      }),
                ],
              ),
            ),
          ]))
        ]));
  }

  @override
  bool get wantKeepAlive => true;
}
