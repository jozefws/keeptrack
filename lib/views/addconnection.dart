import 'package:flutter/material.dart';
import 'package:keeptrack/api/cables_api.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/interfaces_api.dart';
import 'package:keeptrack/api/racks_api.dart';
import 'package:keeptrack/models/cables.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

  String? rackA,
      rackB,
      deviceA,
      deviceB,
      interfaceA,
      interfaceB,
      cableBarcodeScan,
      cableType;

  final TextEditingController _cableBarcodeScanController =
      TextEditingController();

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

  _addNewConnection() async {
    String? barcode, type, intA, intB;
    if (cableBarcodeScan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please scan cable barcode')));
    } else {
      barcode = cableBarcodeScan ?? "";
    }

    if (cableType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pick a cable type')));
    } else {
      type = cableType ?? "";
    }

    if (interfaceA == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please pick an interface for device A')));
    } else {
      intA = interfaceA ?? "";
    }
    if (interfaceB == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please pick an interface for device B')));
    } else {
      intB = interfaceB ?? "";
    }

    if (barcode != null && type != null && intA != null && intB != null) {
      Cable newCable = Cable(
        label: barcode,
        type: type,
        terminationAId: intA,
        terminationBId: intB,
        status: "connected",
      );

      if (await CablesAPI.addConnection(await getToken(), newCable)) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connection added successfully')));
        setState(() {
          interfaceA = null;
          interfaceB = null;
          cableBarcodeScan = null;
          cableType = null;
          _cableBarcodeScanController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error adding connection')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Form(
        key: _addConnectionKey,
        child: Container(
          padding: const EdgeInsets.all(32.0),
          child: Column(children: [
            Container(
                height: (MediaQuery.of(context).size.height / 2.5),
                child: TabBarView(controller: _tabController, children: [
                  Container(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text('Choose Rack',
                            style: TextStyle(fontSize: 18)),
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
                        const Text('Choose Device',
                            style: TextStyle(fontSize: 18)),
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
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text('Choose Rack',
                            style: TextStyle(fontSize: 18)),
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
                        const Text('Choose Device',
                            style: TextStyle(fontSize: 18)),
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
                ])),
            TabBar(
                labelColor: Theme.of(context).textTheme.bodyLarge!.color,
                controller: _tabController,
                tabs: const [
                  Tab(
                    text: "Device A",
                  ),
                  Tab(
                    text: 'Device B',
                  ),
                ]),
            const SizedBox(height: 50),
            //scan cable
            ElevatedButton(
              onPressed: () async => _cableBarcodeScanController.text =
                  (await openScanner(context))!,
              style: ElevatedButton.styleFrom(
                elevation: 4,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5))),
                //material theme
                foregroundColor:
                    Theme.of(context).buttonTheme.colorScheme!.onPrimary,
                backgroundColor: Theme.of(context).backgroundColor,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Text("Open Barcode Scanner"),
              ),
            ),
            const SizedBox(height: 20),
            // selected cable
            Text(
              cableBarcodeScan ?? "",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField(
                items: CableType.networkRJ45,
                onChanged: (value) {
                  setState(() {
                    cableType = value;
                  });
                },
                decoration: const InputDecoration(
                    labelText: 'Cable Type', hintText: 'Select Cable Type')),
            const SizedBox(height: 30),

            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 4,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  //material theme
                  foregroundColor:
                      Theme.of(context).buttonTheme.colorScheme!.onPrimary,
                  backgroundColor: Theme.of(context).backgroundColor,
                ),
                onPressed: () {
                  if (_addConnectionKey.currentState!.validate()) {
                    _addConnectionKey.currentState!.save();
                    _addNewConnection();
                  }
                },
                child: const Text('Add Connection'))
          ]),
        ));
  }

  Future<String?> openScanner(BuildContext context) async {
    setState(() {
      cableBarcodeScan = null;
    });
    final String? code = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (ctx) => Scaffold(
                appBar: AppBar(title: const Text("Scan Cable Barcode")),
                body: MobileScanner(
                  allowDuplicates: false,
                  onDetect: (barcode, args) {
                    if (cableBarcodeScan == null) {
                      Navigator.pop(context, barcode.rawValue);
                    }
                    setState(() {
                      cableBarcodeScan = barcode.rawValue;
                    });
                  },
                ))));
    if (code == null) {
      genSnack("No barcode detected");
      return "";
    }
    if (await CablesAPI.checkExistenceById(await getToken(), code)) {
      genSnack("Cable $code, already exists");
      return "";
    } else {
      print("Cable $code, does not exist");
      return code;
    }
  }

  @override
  bool get wantKeepAlive => true;
}
