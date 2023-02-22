import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:keeptrack/models/cables.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../api/cables_api.dart';
import '../api/devices_api.dart';
import '../api/interfaces_api.dart';
import '../api/racks_api.dart';
import '../models/devices.dart';
import '../provider/netboxauth_provider.dart';

class ModifyConnection extends StatefulWidget {
  const ModifyConnection({super.key});

  @override
  State<ModifyConnection> createState() => _ModifyConnectionState();
}

class _ModifyConnectionState extends State<ModifyConnection>
    with
        AutomaticKeepAliveClientMixin<ModifyConnection>,
        SingleTickerProviderStateMixin<ModifyConnection> {
  final _modifyConnectionKey = GlobalKey<FormState>();
  TabController? _tabController;

  List<String> devices = [];

  String deviceAName = "Select Device A", deviceBName = "Select Device B";

  String? deviceA, deviceB, interfaceA, interfaceB, cableBarcodeScan, cableType;

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

  void setCurrentInformation(String code) async {
    print("Cable ID: $code");
    Future<List<Cable>> cableDevices =
        CablesAPI.getCableByID(await getToken(), code);
    var tempDeviceA =
        (await cableDevices).first.terminationADeviceID.toString();
    var tempDeviceB =
        (await cableDevices).first.terminationADeviceID.toString();

    var tempCableType = (await cableDevices).first.type;

    var tempInterfaceA = (await cableDevices).first.terminationAId;
    var tempInterfaceB = (await cableDevices).first.terminationBId;

    setState(() {
      deviceA = tempDeviceA;
      deviceB = tempDeviceB;

      cableType = tempCableType;

      interfaceA = tempInterfaceA;
      interfaceB = tempInterfaceB;
    });
    print(
        "Device A: $deviceA, Device B: $deviceB, Interface A: $interfaceA, Interface B: $interfaceB, Cable Type: $cableType");
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Form(
        key: _modifyConnectionKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Modify Connection",
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                color: Theme.of(context).colorScheme.onInverseSurface,
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
                    child: Text(
                      "Scan cable QR and select Cable Type",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    child: FloatingActionButton.extended(
                      heroTag: "cableScan",
                      onPressed: () async {
                        _cableBarcodeScanController.text =
                            (await openScanner(context))!;
                      },
                      //set size to fill the parent
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16.0)),
                      ),
                      label: const Text("Scan Cable QR"),
                      icon: const Icon(Icons.qr_code_scanner),
                    ),
                  ),
                  Text(
                    "Cable ID: $cableBarcodeScan",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                    child: DropdownButtonFormField<String>(
                        style: Theme.of(context).textTheme.bodyLarge,
                        value: cableType,
                        items: const [
                          DropdownMenuItem(
                            value: "mmf",
                            child: Text("Fiber (MMF)"),
                          ),
                          DropdownMenuItem(
                            value: "smf",
                            child: Text("Fiber (SMF)"),
                          ),
                          DropdownMenuItem(
                            value: "cat5e",
                            child: Text("cat5e"),
                          ),
                          DropdownMenuItem(
                            value: "cat6",
                            child: Text("cat6"),
                          ),
                          DropdownMenuItem(
                            value: "power",
                            child: Text("Power"),
                          ),
                        ],
                        onChanged: (String? value) {
                          if (value != cableType) {
                            setState(() {
                              cableType = value;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                            labelText: 'Select a Cable Type')),
                  ),
                ])),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              color: Theme.of(context).colorScheme.onInverseSurface,
              child: Column(
                children: [
                  TabBar(
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorWeight: 3,
                      labelColor: Theme.of(context).colorScheme.primary,
                      labelPadding: const EdgeInsets.all(8),
                      unselectedLabelColor:
                          Theme.of(context).textTheme.bodyLarge!.color,
                      controller: _tabController,
                      tabs: const [
                        Tab(
                          text: "Device A",
                        ),
                        Tab(
                          text: 'Device B',
                        ),
                      ]),
                  SizedBox(
                    height: 215,
                    width: double.infinity,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.all(24),
                              child: DropdownSearch<String>(
                                dropdownBuilder: (context, item) {
                                  return Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.all(10),
                                    child: Text(
                                      item ?? deviceAName,
                                    ),
                                  );
                                },
                                popupProps: PopupProps.modalBottomSheet(
                                  showSearchBox: true,
                                  searchDelay:
                                      const Duration(milliseconds: 100),
                                  searchFieldProps: TextFieldProps(
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      labelText: deviceAName,
                                    ),
                                  ),
                                  modalBottomSheetProps: ModalBottomSheetProps(
                                      isScrollControlled: true,
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      anchorPoint: const Offset(0.5, 5)),
                                  constraints: const BoxConstraints(
                                      maxHeight: 400,
                                      maxWidth: double.infinity),
                                ),
                                asyncItems: (_) => _getDevices(),
                                onChanged: (value) {
                                  setState(() {
                                    deviceAName =
                                        value?.split("|")[0].trim() ?? "";
                                    deviceA = value
                                        ?.split("|")[2]
                                        .trim()
                                        .substring(2);
                                    interfaceA = null;
                                  });
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                              child: FutureBuilder(
                                  future: _getInterfacesByDevice(deviceA ?? ""),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      var data = snapshot.data!;
                                      return DropdownButtonFormField(
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
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
                                              hintText: 'Select an Interface'));
                                    } else {
                                      return const CircularProgressIndicator();
                                    }
                                  }),
                            ),
                          ],
                        ),
                        /////////////////////////
                        // SIDE B
                        /////////////////////////

                        Column(children: [
                          Container(
                            margin: const EdgeInsets.all(24),
                            child: DropdownSearch<String>(
                              dropdownBuilder: (context, item) {
                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.all(10),
                                  child: Text(
                                    item ?? deviceBName,
                                  ),
                                );
                              },
                              popupProps: PopupProps.modalBottomSheet(
                                showSearchBox: true,
                                searchDelay: const Duration(milliseconds: 100),
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    labelText: deviceBName,
                                  ),
                                ),
                                modalBottomSheetProps: ModalBottomSheetProps(
                                    isScrollControlled: true,
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    anchorPoint: const Offset(0.5, 5)),
                                constraints: const BoxConstraints(
                                    maxHeight: 400, maxWidth: double.infinity),
                              ),
                              asyncItems: (_) => _getDevices(),
                              onChanged: (value) {
                                setState(() {
                                  deviceBName =
                                      value?.split("|")[0].trim() ?? "";
                                  deviceB =
                                      value?.split("|")[2].trim().substring(2);
                                  interfaceB = null;
                                });
                              },
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                            child: FutureBuilder(
                                future: _getInterfacesByDevice(deviceB ?? ""),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    var data = snapshot.data!;
                                    return DropdownButtonFormField(
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
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
                                            hintText: 'Select an Interface'));
                                  } else {
                                    return const CircularProgressIndicator();
                                  }
                                }),
                          ),
                        ])
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              child: FloatingActionButton.extended(
                  heroTag: "modifyConnection",
                  onPressed: null,
                  label: const Text("Modify Connection"),
                  icon: const Icon(Icons.add)),
            ),
          ],
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
      setCurrentInformation(code);
      return code;
    } else {
      genSnack("Cable $code, doesn't exist or couldn't be found.");
      return "";
    }
  }

  @override
  bool get wantKeepAlive => true;
}
