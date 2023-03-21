import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:keeptrack/models/cables.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../api/cables_api.dart';
import '../api/devices_api.dart';
import '../api/interfaces_api.dart';
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

  String deviceAName = "Scan Cable QR",
      deviceBName = "Scan Cable QR",
      interfaceAName = "Scan Cable QR",
      interfaceBName = "Scan Cable QR";

  String? deviceA,
      deviceB,
      interfaceA,
      interfaceB,
      cableBarcodeScan,
      cableType,
      cableStatus;

  CablesAPI cablesAPI = CablesAPI();
  DevicesAPI devicesAPI = DevicesAPI();
  InterfacesAPI interfacesAPI = InterfacesAPI();

  final TextEditingController _cableBarcodeScanController =
      TextEditingController();

  @override
  initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  genSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Error: $message")));
  }

  Future<List<String>> _getDevices() async {
    var i = await devicesAPI.getDevices(await getToken());
    return i
        .map((e) =>
            "${e.name} | Rack: ${(e.rack?.name)?.substring(4) ?? "Unracked"} | ID${e.id}")
        .toList();
  }

  Future<List<DropdownMenuItem<String>>?> _getInterfacesByDevice(
      String deviceID) async {
    if (deviceID == "") {
      return [];
    }
    final i =
        await interfacesAPI.getInterfacesByDevice(await getToken(), deviceID);
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

  Cable currentCable = Cable(
    terminationADeviceID: "",
    terminationBDeviceID: "",
    terminationAId: "",
    terminationBId: "",
    type: "",
    status: "",
    label: "",
    id: -1,
  );

  void _setCurrentInformation(String code) async {
    Future<Cable?> cableDevices =
        cablesAPI.getCableByID(await getToken(), code);
    cableDevices.then((value) {
      if (value == null) {
        genSnack("No cable found");
      } else {
        setState(() {
          currentCable = value;
          cableBarcodeScan = code;
          deviceA = currentCable.terminationADeviceID;
          deviceAName = currentCable.terminationADeviceName ?? "Name not found";
          deviceB = currentCable.terminationBDeviceID;
          deviceBName = currentCable.terminationBDeviceName ?? "Name not found";
          interfaceA = currentCable.terminationAId;
          interfaceB = currentCable.terminationBId;
          cableType = currentCable.type;
        });
      }
    });
  }

  verifyModifications() {
    if (deviceAName != currentCable.terminationADeviceName ||
        deviceBName != currentCable.terminationBDeviceName ||
        interfaceA != currentCable.terminationAId ||
        interfaceB != currentCable.terminationBId ||
        cableType != currentCable.type) {
      if (deviceAName == "Scan Cable QR" || deviceBName == "Scan Cable QR") {
        return;
      } else {
        modifyCable();
      }
    } else {
      genSnack("No changes made");
    }
  }

  void modifyCable() async {
    if (await showAlert()) {
      currentCable.terminationADeviceID = deviceA;
      currentCable.terminationBDeviceID = deviceB;
      currentCable.terminationAId = interfaceA;
      currentCable.terminationBId = interfaceB;
      currentCable.type = cableType;

      if (await cablesAPI.updateConnection(await getToken(), currentCable)) {
        genSnack("Cable modified successfully");
      } else {
        genSnack("Cable modification failed");
      }
      genSnack("Cable modified successfully");
    } else {
      genSnack("Modification cancelled");
    }
  }

  Future showAlert() {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text("Confirm Cable Modification"),
                content: Column(
                  children: [
                    const Text("Are you sure you want to modify this cable?"),
                    Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(top: 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text("Device A: ",
                                    style:
                                        Theme.of(context).textTheme.bodyLarge),
                                Text(currentCable.terminationADeviceName !=
                                        deviceAName
                                    ? "${currentCable.terminationADeviceName} -> $deviceAName"
                                    : "No changes"),
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  "Device B: ",
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(currentCable.terminationBDeviceName !=
                                        deviceBName
                                    ? "${currentCable.terminationBDeviceName} -> $deviceBName"
                                    : "No changes"),
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  "Interface A: ",
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(currentCable.terminationAId != interfaceA
                                    ? "${currentCable.terminationAId} -> $interfaceA"
                                    : "No changes"),
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  "Interface B: ",
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(currentCable.terminationBId != interfaceB
                                    ? "${currentCable.terminationBId} -> $interfaceB"
                                    : "No changes"),
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  "Cable Type: ",
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(currentCable.type != cableType
                                    ? "${currentCable.type} -> $cableType"
                                    : "No changes"),
                              ],
                            ),
                          ],
                        ))
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: const Text("Cancel")),
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: const Text("Confirm"))
                ]));
  }

  getToken() async {
    return await NetboxAuthProvider().getToken();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Form(
        key: _modifyConnectionKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
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
                              value: "cat3",
                              child: Text("cat3"),
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
                                child: FutureBuilder(
                                    future: _getDevices(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        devices = snapshot.data as List<String>;
                                      } else {
                                        return const Center(
                                            child: CircularProgressIndicator(
                                          semanticsLabel: "Loading",
                                        ));
                                      }
                                      return DropdownSearch<String>(
                                        enabled: cableBarcodeScan != null,
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
                                              border:
                                                  const OutlineInputBorder(),
                                              labelText: deviceAName,
                                            ),
                                          ),
                                          modalBottomSheetProps:
                                              ModalBottomSheetProps(
                                                  isScrollControlled: true,
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .primaryColor,
                                                  anchorPoint:
                                                      const Offset(0.5, 5)),
                                          constraints: const BoxConstraints(
                                              maxHeight: 400,
                                              maxWidth: double.infinity),
                                        ),
                                        items: [
                                          for (var device in devices)
                                            "${device.split("|")[0].trim()} | ${device.split("|")[1].trim()} | ${device.split("|")[2].trim()}"
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            deviceAName =
                                                value?.split("|")[0].trim() ??
                                                    "";
                                            deviceA = value
                                                ?.split("|")[2]
                                                .trim()
                                                .substring(2);
                                            interfaceA = null;
                                          });
                                        },
                                      );
                                    }),
                              ),
                              Container(
                                margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                                child: FutureBuilder(
                                    future:
                                        _getInterfacesByDevice(deviceA ?? ""),
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
                                                hintText:
                                                    'Select an Interface'));
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

                          Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.all(24),
                                child: FutureBuilder(
                                    future: _getDevices(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        devices = snapshot.data as List<String>;
                                      } else {
                                        return const Center(
                                            child: CircularProgressIndicator(
                                          semanticsLabel: "Loading",
                                        ));
                                      }
                                      return DropdownSearch<String>(
                                        enabled: cableBarcodeScan != null,
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
                                          searchDelay:
                                              const Duration(milliseconds: 100),
                                          searchFieldProps: TextFieldProps(
                                            decoration: InputDecoration(
                                              border:
                                                  const OutlineInputBorder(),
                                              labelText: deviceBName,
                                            ),
                                          ),
                                          modalBottomSheetProps:
                                              ModalBottomSheetProps(
                                                  isScrollControlled: true,
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .primaryColor,
                                                  anchorPoint:
                                                      const Offset(0.5, 5)),
                                          constraints: const BoxConstraints(
                                              maxHeight: 400,
                                              maxWidth: double.infinity),
                                        ),
                                        items: [
                                          for (var device in devices)
                                            "${device.split("|")[0].trim()} | ${device.split("|")[1].trim()} | ${device.split("|")[2].trim()}"
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            deviceBName =
                                                value?.split("|")[0].trim() ??
                                                    "";
                                            deviceB = value
                                                ?.split("|")[2]
                                                .trim()
                                                .substring(2);
                                            interfaceB = null;
                                          });
                                        },
                                      );
                                    }),
                              ),
                              Container(
                                margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                                child: FutureBuilder(
                                    future:
                                        _getInterfacesByDevice(deviceB ?? ""),
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
                                                hintText:
                                                    'Select an Interface'));
                                      } else {
                                        return const CircularProgressIndicator();
                                      }
                                    }),
                              ),
                            ],
                          )
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
                    // if (cableBarcodeScan == null) then disable button
                    onPressed: () => cableBarcodeScan == null
                        ? genSnack("Scan a cable first")
                        : verifyModifications(),
                    label: const Text("Modify Connection"),
                    icon: const Icon(Icons.add)),
              ),
            ],
          ),
        ));
  }

  Future<String?> openScanner(BuildContext context) async {
    setState(() {
      cableBarcodeScan = null;
    });
    String? code = await Navigator.push(
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

    if (await cablesAPI.checkExistenceById(await getToken(), code)) {
      _setCurrentInformation(code);
      return code;
    } else {
      genSnack("Cable $code, doesn't exist or couldn't be found.");
      return "";
    }
  }

  @override
  bool get wantKeepAlive => true;
}
