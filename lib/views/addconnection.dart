import 'package:flutter/material.dart';
import 'package:keeptrack/api/cables_api.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/interfaces_api.dart';
import 'package:keeptrack/api/poweroutlets_api.dart';
import 'package:keeptrack/api/powerport_api.dart';
import 'package:keeptrack/models/VLANColor.dart';
import 'package:keeptrack/models/cables.dart';
import 'package:keeptrack/models/devices.dart';
import 'package:keeptrack/models/interfaceComboModel.dart';
import 'package:keeptrack/models/interfaces.dart';
import 'package:keeptrack/models/poweroutlet.dart';
import 'package:keeptrack/models/powerport.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
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

  List<Device> devices = [];

  String deviceAName = "Device A", deviceBName = "Device B";

  Device? deviceA, deviceB;
  // Interface? interfaceA, interfaceB;
  // PowerPort? powerPortA, powerPortB;
  // PowerOutlet? powerOutletA, powerOutletB;
  ComboModel? comboA, comboB;

  ConnectionColour? connectionColours;
  // String? cableBarcodeScan, cableType;
  String? cableType;

  CablesAPI cablesAPI = CablesAPI();
  DevicesAPI devicesAPI = DevicesAPI();
  InterfacesAPI interfacesAPI = InterfacesAPI();
  PowerPortsAPI powerPortsAPI = PowerPortsAPI();
  PowerOutletsAPI powerOutletsAPI = PowerOutletsAPI();

  final TextEditingController _cableBarcodeScanController =
      TextEditingController();

  Future<List<Device>> _getDevices() async {
    var i = await devicesAPI.getDevices(await getToken());
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

  Future<List<ComboModel>?> _getMixedPortsByDeviceID(String deviceID) async {
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
      genSnack("No ports found on device");
      return [];
    }
    return comboList;
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
    // String? barcode, type;
    String? type;
    Interface? intA, intB;
    PowerPort? ppA, ppB;
    PowerOutlet? poA, poB;

    // if (cableBarcodeScan == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text('Please scan cable barcode')));
    // } else {
    //   barcode = cableBarcodeScan ?? "";
    // }

    if (cableType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pick a cable type')));
    } else {
      type = cableType ?? "";
    }

    if (comboA == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please pick an interface for device A')));
    } else {
      intA = comboA?.interface;
      ppA = comboA?.powerPort;
      poA = comboA?.powerOutlet;
    }
    if (comboB == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please pick an interface for device B')));
    } else {
      intB = comboB?.interface;
      ppB = comboB?.powerPort;
      poB = comboB?.powerOutlet;
    }

    // if (barcode != null &&
    if (type != null &&
        comboA != null &&
        comboB != null &&
        connectionColours != null) {
      String description =
          "$deviceAName:${comboA?.name} > $deviceBName:${comboB?.name}";
      String label = "${comboA?.name} > ${comboB?.name}";
      Cable newCable = Cable(
          id: -1,
          // label: barcode,
          label: label,
          type: type,
          color: connectionColours?.hexColor.toLowerCase(),
          terminationAType: comboA?.objectType,
          terminationAId: comboA?.id.toString(),
          terminationBType: comboB?.objectType,
          terminationBId: comboB?.id.toString(),
          status: "connected",
          description: description);

      print(newCable.color);

      String result = await cablesAPI.addConnection(await getToken(), newCable);

      if (result != "Error") {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connection added successfully')));
        setState(() {
          comboA = null;
          comboB = null;
          // cableBarcodeScan = null;
          _cableBarcodeScanController.clear();
        });
        showSuccessDialog(result, label);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error adding connection')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error adding connection, there was a null value')));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Form(
        key: _addConnectionKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
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
                                child: DropdownSearch<Device>(
                                  filterFn: (item, filter) => item.name
                                      .toLowerCase()
                                      .contains(filter.toLowerCase()),
                                  dropdownBuilder: (context, item) {
                                    return Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.all(10),
                                      child: Text(
                                        item?.name ?? deviceAName,
                                      ),
                                    );
                                  },
                                  popupProps: PopupProps.modalBottomSheet(
                                    itemBuilder: (context, item, isSelected) =>
                                        Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          Text(
                                            item.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          Text(
                                              " | ${item.location?.display} | ${item.rack?.name} | U${item.position}"),
                                        ],
                                      ),
                                    ),
                                    showSearchBox: true,
                                    searchDelay:
                                        const Duration(milliseconds: 100),
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        labelText: deviceAName,
                                      ),
                                    ),
                                    modalBottomSheetProps:
                                        ModalBottomSheetProps(
                                            isScrollControlled: true,
                                            backgroundColor:
                                                Theme.of(context).primaryColor,
                                            anchorPoint: const Offset(0.5, 5)),
                                    constraints: const BoxConstraints(
                                        maxHeight: 400,
                                        maxWidth: double.infinity),
                                  ),
                                  asyncItems: (device) => _getDevices(),
                                  onChanged: (value) {
                                    setState(() {
                                      deviceAName =
                                          value?.name ?? "Select a device";
                                      deviceA = value;
                                      comboA = null;
                                    });
                                  },
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                                child: FutureBuilder(
                                    future: _getMixedPortsByDeviceID(
                                        deviceA?.id.toString() ?? ""),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        if (snapshot.data == null) {
                                          return const Text("");
                                        }
                                        var data = snapshot.data!;
                                        return Column(
                                          children: [
                                            DropdownSearch<ComboModel>(
                                              enabled: deviceA != null &&
                                                  data.isNotEmpty,
                                              items: data,
                                              onChanged: (value) {
                                                setState(() {
                                                  comboA = value;
                                                });
                                              },
                                              itemAsString: (item) =>
                                                  "${item.name} | ${item.occupied == true ? "Occupied" : "Free"}",
                                              dropdownBuilder: (context, item) {
                                                return Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  margin:
                                                      const EdgeInsets.all(10),
                                                  child: Text(item?.name ??
                                                      comboA?.name ??
                                                      ""),
                                                );
                                              },
                                            )
                                          ],
                                        );
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
                                child: DropdownSearch<Device>(
                                  filterFn: (item, filter) => item.name
                                      .toLowerCase()
                                      .contains(filter.toLowerCase()),
                                  dropdownBuilder: (context, item) {
                                    return Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.all(10),
                                      child: Text(
                                        item?.name ?? deviceBName,
                                      ),
                                    );
                                  },
                                  popupProps: PopupProps.modalBottomSheet(
                                    itemBuilder: (context, item, isSelected) =>
                                        Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          Text(
                                            item.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          Text(
                                              " | ${item.location?.display} | ${item.rack?.name} | U${item.position}"),
                                        ],
                                      ),
                                    ),
                                    showSearchBox: true,
                                    searchDelay:
                                        const Duration(milliseconds: 100),
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        labelText: deviceBName,
                                      ),
                                    ),
                                    modalBottomSheetProps:
                                        ModalBottomSheetProps(
                                            isScrollControlled: true,
                                            backgroundColor:
                                                Theme.of(context).primaryColor,
                                            anchorPoint: const Offset(0.5, 5)),
                                    constraints: const BoxConstraints(
                                        maxHeight: 400,
                                        maxWidth: double.infinity),
                                  ),
                                  asyncItems: (device) => _getDevices(),
                                  onChanged: (value) {
                                    setState(() {
                                      deviceBName =
                                          value?.name ?? "Select a device";
                                      deviceB = value;
                                      comboB = null;
                                    });
                                  },
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                                child: FutureBuilder(
                                    future: _getMixedPortsByDeviceID(
                                        deviceB?.id.toString() ?? ""),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        if (snapshot.data == null) {
                                          return const Text("");
                                        }
                                        var data = snapshot.data!;
                                        return DropdownSearch<ComboModel>(
                                          enabled: deviceB != null &&
                                              data.isNotEmpty,
                                          items: data,
                                          onChanged: (value) {
                                            setState(() {
                                              comboB = value;
                                            });
                                          },
                                          itemAsString: (item) =>
                                              "${item.name} | ${item.occupied == true ? "Occupied" : "Free"}",
                                          dropdownBuilder: (context, item) {
                                            return Container(
                                              padding: const EdgeInsets.all(8),
                                              margin: const EdgeInsets.all(10),
                                              child: Text(
                                                item?.name ??
                                                    comboB?.name ??
                                                    "",
                                              ),
                                            );
                                          },
                                        );
                                      } else {
                                        return const CircularProgressIndicator();
                                      }
                                    }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
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
                        // "Scan cable QR and select Cable Type",
                        "Select Cable Type and Color (VLAN)",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        // child: FloatingActionButton.extended(
                        //   heroTag: "cableScan",
                        //   onPressed: () async {
                        //     _cableBarcodeScanController.text = "032042";
                        //     setState(() {
                        //       cableBarcodeScan = _cableBarcodeScanController.text;
                        //     });
                        //     return;
                        //     _cableBarcodeScanController.text =
                        //         (await openScanner(context))!;
                        //   },
                        //   //set size to fill the parent
                        //   shape: const RoundedRectangleBorder(
                        //     borderRadius: BorderRadius.all(Radius.circular(16.0)),
                        //   ),
                        //   label: const Text("Scan Cable QR"),
                        //   icon: const Icon(Icons.qr_code_scanner),
                        // ),

                        //dropdown menu for every colour in keeptrack VLANCOlor
                        child: DropdownButtonFormField<ConnectionColour>(
                          style: Theme.of(context).textTheme.bodyLarge,
                          value: connectionColours,
                          itemHeight: 60,
                          items: CONNECTION_COLOURS.map((colour) {
                            return DropdownMenuItem<ConnectionColour>(
                              value: colour,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Text(colour.description),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: colour.color,
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(5)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              connectionColours = value!;
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Cable Color (VLAN/Power)",
                          ),
                        )),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                      child: DropdownButtonFormField<String>(
                          style: Theme.of(context).textTheme.bodyLarge,
                          value: cableType,
                          items: const [
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
                            DropdownMenuItem(
                              value: "dac-active",
                              child: Text("Direct Attach Copper (SFP+)"),
                            ),
                            DropdownMenuItem(
                              value: "mmf",
                              child: Text("Fiber (MMF)"),
                            ),
                            DropdownMenuItem(
                              value: "smf",
                              child: Text("Fiber (SMF)"),
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
                child: FloatingActionButton.extended(
                    heroTag: "addConnection",
                    onPressed: () {
                      if (_addConnectionKey.currentState!.validate()) {
                        _addConnectionKey.currentState!.save();
                        _addNewConnection();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Please fill in all fields")));
                      }
                    },
                    label: const Text("Add Connection"),
                    icon: const Icon(Icons.add)),
              ),
            ],
          ),
        ));
  }

  // Future<String?> openScanner(BuildContext context) async {
  //   setState(() {
  //     cableBarcodeScan = null;
  //   });
  //   final String? code = await Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //           builder: (ctx) => Scaffold(
  //               appBar: AppBar(title: const Text("Scan Cable Barcode")),
  //               body: MobileScanner(
  //                 allowDuplicates: false,
  //                 onDetect: (barcode, args) {
  //                   if (cableBarcodeScan == null) {
  //                     Navigator.pop(context, barcode.rawValue);
  //                   }
  //                   setState(() {
  //                     cableBarcodeScan = barcode.rawValue;
  //                   });
  //                 },
  //               ))));
  //   if (code == null) {
  //     genSnack("No barcode detected");
  //     return "";
  //   }
  //   if (await cablesAPI.checkExistenceById(await getToken(), code)) {
  //     genSnack("Cable $code, already exists");
  //     return "";
  //   } else {
  //     print("Cable $code, does not exist");
  //     return code;
  //   }
  // }

  @override
  bool get wantKeepAlive => true;

  showSuccessDialog(String result, String cableDescription) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          //Dialog that covers half the screen showing the new cable id and the cable description
          return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)),
              child: Container(
                padding: const EdgeInsets.all(20),
                height: 300,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Cable Added Successfully",
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(
                      height: 20,
                    ),
                    Text("New Cable ID",
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(result),
                    const SizedBox(
                      height: 20,
                    ),
                    Text(
                      "Cable Description",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(cableDescription),
                    const SizedBox(
                      height: 20,
                    ),
                    Positioned(
                      bottom: 0,
                      child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("OK")),
                    )
                  ],
                ),
              ));
        });
  }
}
