import 'package:flutter/material.dart';
import 'package:keeptrack/api/cables_api.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/interfaces_api.dart';
import 'package:keeptrack/api/racks_api.dart';
import 'package:keeptrack/models/cables.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dropdown_search/dropdown_search.dart';

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

  List<String> devices = [];

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

  Future<List<String>> _getDevices() async {
    var i = await DevicesAPI.getDevices(await getToken());
    return i
        .map((e) =>
            "${e.name} | ${(e.rack?.name)?.substring(4) ?? "Unracked"} | ID${e.id}")
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
    setDevices();
  }

  setDevices() async {
    devices = await _getDevices();
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
            const Text(
              "Add a new connection",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)
          ),
          const SizedBox(
            height: 40,
          ),
          SizedBox(
              height: (MediaQuery.of(context).size.height / 2) - 100,
              child: TabBarView(controller: _tabController, children: [
                Column(
                  children: [
                    Container(
                      color: Theme.of(context).colorScheme.background,
                      padding: const EdgeInsets.all(10),
                      child: Column(children: [
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
                        const SizedBox(height: 30),
                        DropdownSearch<String>(
                          dropdownButtonProps:
                          const DropdownButtonProps(color: Colors.white),
                          popupProps: const PopupProps.modalBottomSheet(
                            showSearchBox: true,
                            searchDelay: Duration(milliseconds: 5),
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Search for device A',
                              ),
                            ),
                            modalBottomSheetProps: ModalBottomSheetProps(
                                isScrollControlled: true,
                                backgroundColor:
                                Color.fromARGB(255, 126, 126, 126),
                                anchorPoint: Offset(0.5, 05)),
                            constraints:
                            BoxConstraints(maxHeight: 400, maxWidth: 1000),
                          ),
                          asyncItems: (_) => _getDevices(),
                          onChanged: (value) {
                            setState(() {
                              deviceA =
                                  value?.split("|")[2].trim().substring(2);
                              interfaceA = null;
                            });
                          },
                        ),
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
                                        labelText: 'Pick Interface A',
                                        hintText: 'Select an Interface'));
                              } else {
                                return const CircularProgressIndicator();
                              }
                            }),
                      ],)
                    )
                  ]
      )
              ]
              )
    )
    ])));
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
