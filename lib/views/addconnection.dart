import 'package:flutter/material.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/interfaces_api.dart';
import 'package:keeptrack/api/racks_api.dart';
import 'package:keeptrack/models/interfaces.dart';
import 'package:keeptrack/models/racks.dart';
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

  List<DropdownMenuItem<Rack>>? racksA, racksB = [];
  List<DropdownMenuItem<Device>>? devicesA, devicesB = [];
  List<DropdownMenuItem<Interface>>? interfacesA, interfacesB = [];

  final _rackAController = TextEditingController();
  final _deviceAController = TextEditingController();
  final _interfaceAController = TextEditingController();
  final _rackBController = TextEditingController();
  final _deviceBController = TextEditingController();
  final _interfaceBController = TextEditingController();

  Future<List<DropdownMenuItem<Rack>>?> _getRacks() async {
    var racks = await RacksAPI.getRacks(await getToken());
    return racks
        .map((e) => DropdownMenuItem(
              value: e,
              child: Text(e.name),
            ))
        .toList();
  }

  Future<List<DropdownMenuItem<String>>> _getDevicesByRack(int rackID) async {
    final i = await DevicesAPI.getDevicesByRack(await getToken(), rackID);
    if (i == []) {
      const SnackBar(content: Text('Error: No devices found'));
    }
    return i
        .map((e) => DropdownMenuItem(
              value: e.id.toString(),
              child: Text(e.name),
            ))
        .toList();
  }

  Future<List<DropdownMenuItem<Interface>>?> _getInterfacesByDevice(
      int deviceID) async {
    final i =
        await InterfacesAPI.getInterfacesByDevice(await getToken(), deviceID);
    if (i == []) {
      const SnackBar(content: Text('Error: No interfaces found'));
    }
    return i
        .map((e) => DropdownMenuItem(
              value: e,
              child: Text(e.name),
            ))
        .toList();
  }

  @override
  initState() {
    _tabController = TabController(length: 2, vsync: this);
    print(racksA);
    setRacks();
    super.initState();
  }

  void setRacks() async {
    var tempA = await _getRacks();
    var tempB = await _getRacks();
    if (mounted) {
      setState(() {
        racksA = tempA;
        racksB = tempB;
      });
      return;
    }
    setState(() {
      racksA = tempA;
      racksB = tempB;
    });
  }

  setDevices(List<DropdownMenuItem<Device>>? devices, String rackID) async {
    var temp = await _getDevicesByRack(int.parse(rackID));
    setState(() {
      devices = temp.cast<DropdownMenuItem<Device>>();
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
                  DropdownButtonFormField(
                    items: racksA,
                    onChanged: (value) {
                      setState(() {
                        _rackAController.text = value.toString();
                        setDevices(devicesA, value.toString());
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Choose Device', style: TextStyle(fontSize: 18)),
                  DropdownButtonFormField(
                    items: devicesA,
                    onChanged: (value) {
                      setState(() {
                        _deviceAController.text = value.toString();
                        _getInterfacesByDevice(int.parse(value.toString()));
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Choose Interface',
                      style: TextStyle(fontSize: 18)),
                  DropdownButtonFormField(
                    //if interfaces is empty, show default item
                    items: interfacesA,
                    onChanged: (value) {
                      setState(() {
                        _interfaceAController.text = value.toString();
                      });
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text('Choose Rack', style: TextStyle(fontSize: 18)),
                  DropdownButtonFormField(
                    items: racksB,
                    onChanged: (value) {
                      setState(() {
                        _rackBController.text = value.toString();
                        setDevices(devicesB, value.toString());
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Choose Device', style: TextStyle(fontSize: 18)),
                  DropdownButtonFormField(
                    items: devicesB,
                    onChanged: (value) {
                      setState(() {
                        _deviceBController.text = value.toString();
                        _getInterfacesByDevice(int.parse(value.toString()));
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Choose Interface',
                      style: TextStyle(fontSize: 18)),
                  DropdownButtonFormField(
                    //if interfaces is empty, show default item
                    items: interfacesB,
                    onChanged: (value) {
                      setState(() {
                        _interfaceBController.text = value.toString();
                      });
                    },
                  ),
                ],
              ),
            )
          ]))
        ]));
  }

  @override
  bool get wantKeepAlive => true;
}
