import 'dart:convert';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:keeptrack/api/poweroutlets_api.dart';
import 'package:keeptrack/api/powerport_api.dart';
import 'package:keeptrack/models/cables.dart';
import 'package:keeptrack/models/devices.dart';
import 'package:keeptrack/models/interfaceComboModel.dart';
import 'package:keeptrack/models/interfaces.dart';
import 'package:keeptrack/models/poweroutlet.dart';
import 'package:keeptrack/models/powerport.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:keeptrack/api/cables_api.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/interfaces_api.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';

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

  List<Device> devices = [];

  String? cableBarcodeScan, cableType, cableStatus, cableDescription;
  Device? deviceA, deviceB;
  ComboModel? comboA, comboB;

  // Interface? interfaceA, interfaceB;

  CablesAPI cablesAPI = CablesAPI();
  DevicesAPI devicesAPI = DevicesAPI();
  InterfacesAPI interfacesAPI = InterfacesAPI();
  PowerPortsAPI powerPortsAPI = PowerPortsAPI();
  PowerOutletsAPI powerOutletsAPI = PowerOutletsAPI();

  final TextEditingController _cableBarcodeScanController =
      TextEditingController();

  @override
  initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  genSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<List<Device>> _getDevices() async {
    var i = await devicesAPI.getDevices(await getToken());
    if (i.isEmpty) {
      genSnack("No devices found");
      return [];
    }
    return i;
  }

  Future<Device?> getDevicesByID(String? id) async {
    if (id == null) {
      return null;
    }
    var i = await devicesAPI.getDeviceByID(await getToken(), id);
    return i;
  }

  Future<List<Interface>> _getInterfacesByDevice(String deviceID) async {
    if (deviceID == "") {
      return [];
    }
    var i =
        await interfacesAPI.getInterfacesByDevice(await getToken(), deviceID);
    if (i.isEmpty) {
      genSnack("No interfaces found");
      return [];
    }
    return i;
  }

  Future<List<PowerPort>> _getPowerPortsByDevice(String deviceID) async {
    if (deviceID == "") {
      return [];
    }
    var i =
        await powerPortsAPI.getPowerPortsByDevice(await getToken(), deviceID);
    if (i.isEmpty) {
      genSnack("No power ports found");
      return [];
    }
    return i;
  }

  Future<List<PowerOutlet>> _getPowerOutletsByDevice(String deviceID) async {
    if (deviceID == "") {
      return [];
    }
    var i = await powerOutletsAPI.getPowerOutletsByDevice(
        await getToken(), deviceID);
    if (i.isEmpty) {
      genSnack("No power outlets found");
      return [];
    }
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

  Cable? currentCable;

  void _setCurrentInformation(String code) async {
    Future<Cable?> cableDevices =
        cablesAPI.getCableByID(await getToken(), code);
    if (await cableDevices == null) {
      genSnack("No cable found");
      return;
    }
    cableDevices.then((value) async {
      Device? tempA = await getDevicesByID(value?.terminationADeviceID);
      Device? tempB = await getDevicesByID(value?.terminationBDeviceID);
      // Interface? tempAInterface = await interfacesAPI.getInterfaceByID(
      //     await getToken(), value?.terminationAId as String);
      // Interface? tempBInterface = await interfacesAPI.getInterfaceByID(
      //     await getToken(), value?.terminationBId as String);

      ComboModel? tempComboA =
          await getComboModel(value?.terminationAId, value?.terminationAType);
      ComboModel? tempComboB =
          await getComboModel(value?.terminationBId, value?.terminationBType);

      if (value == null) {
        genSnack("No cable found");
      } else {
        setState(() {
          currentCable = value;
          cableBarcodeScan = currentCable?.label;
          cableDescription = currentCable?.description;
          deviceA = tempA;
          deviceB = tempB;
          comboA = tempComboA;
          comboB = tempComboB;
        });
      }
    });
  }

  verifyModifications() {
    if (deviceA?.name != currentCable?.terminationADeviceName ||
        deviceB?.name != currentCable?.terminationBDeviceName ||
        comboA?.id.toString() != currentCable?.terminationAId ||
        comboB?.id.toString() != currentCable?.terminationAId ||
        cableType != currentCable?.type) {
      if (deviceA == null ||
          deviceB == null ||
          comboA == null ||
          comboB == null) {
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
      currentCable?.terminationADeviceID = deviceA?.id.toString();
      currentCable?.terminationAType = comboA?.objectType;
      currentCable?.terminationBDeviceID = deviceB?.id.toString();
      currentCable?.terminationBType = comboB?.objectType;
      currentCable?.terminationAId = comboB?.id.toString();
      currentCable?.terminationBId = comboB?.id.toString();
      currentCable?.description = cableDescription;
      currentCable?.status = "connected";

      if (currentCable != null) {
        String result = await cablesAPI.updateConnectionBAD(
            await getToken(), currentCable as Cable);
        if (result != "false") {
          genSnack("Cable modified successfully");
          AlertDialog(
            title: const Text("Cable Modified"),
            content: Column(
              children: [
                Text("Cable modified successfully"),
                Text("Cable ID: ${result}"),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("OK"))
            ],
          );
          return;
        } else {
          genSnack("Cable modification failed");
          return;
        }
      } else {
        genSnack("Cable modification failed, cable was null");
        return;
      }
    } else {
      genSnack("Modification cancelled");
      return;
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
                        margin: const EdgeInsets.only(top: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text("Device A",
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(currentCable?.terminationADeviceName !=
                                    deviceA?.name
                                ? "${currentCable?.terminationADeviceName}  >  ${deviceA?.name}"
                                : "No changes"),
                            const SizedBox(height: 20),
                            Text(
                              "Device B",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(currentCable?.terminationBDeviceName !=
                                    deviceB?.name
                                ? "${currentCable?.terminationBDeviceName}  >  ${deviceB?.name}"
                                : "No changes"),
                            const SizedBox(height: 20),
                            Text(
                              "Interface A",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(currentCable?.terminationAId !=
                                    comboA?.id.toString()
                                ? "${currentCable?.terminationAName}  >  ${comboA?.name}"
                                : "No changes"),
                            const SizedBox(height: 20),
                            Text(
                              "Interface B",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(currentCable?.terminationBId !=
                                    comboB?.id.toString()
                                ? "${currentCable?.terminationBName} > ${comboB?.name}"
                                : "No changes"),
                            const SizedBox(height: 20),
                            Text(
                              "New description",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(currentCable?.description != cableDescription
                                ? "${currentCable?.description ?? "None"}  >  $cableDescription"
                                : "No changes"),
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
                  padding: const EdgeInsets.all(20),
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            FloatingActionButton.extended(
                              heroTag: "cableScan",
                              onPressed: () async {
                                _cableBarcodeScanController.text =
                                    (await openScanner(context))!;
                              },
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text("Scan"),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            // icon with a keyboard suggesting to type it manually
                            Expanded(
                              child: TextFormField(
                                //set the keyboard type to number only
                                keyboardType: TextInputType.number,
                                controller: _cableBarcodeScanController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Cable ID',
                                ),
                                //when the user is done typing, set the current information
                                onFieldSubmitted: (value) {
                                  _setCurrentInformation(value);
                                },
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          utf8.decode(currentCable?.label.runes.toList() ??
                              "".runes.toList()),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        //show color of cbale
                        Text(currentCable?.color == null ? "" : "Color:"),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                          child: Divider(
                            color: Color(int.parse(
                                "0Xff${currentCable?.color ?? "000000"}")),
                            thickness: currentCable?.color == null ? 0 : 10,
                          ),
                        ),
                      ])),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                                        devices = snapshot.data as List<Device>;
                                      } else {
                                        return const Center(
                                            child: CircularProgressIndicator(
                                          semanticsLabel: "Loading",
                                        ));
                                      }
                                      return DropdownSearch<Device>(
                                        enabled: cableBarcodeScan != null,
                                        dropdownBuilder: (context, item) {
                                          return Container(
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.all(10),
                                            child: Text(item?.name ??
                                                deviceA?.name ??
                                                ""),
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
                                              labelText: deviceA?.name ??
                                                  "Scan QR Code",
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
                                        items: devices,
                                        itemAsString: (item) =>
                                            "${item.name} | ${item.location?.display} | ${item.rack?.name}",
                                        onChanged: (value) {
                                          setState(() {
                                            deviceA = value;
                                            comboA = null;
                                            cableDescription =
                                                "${value?.name}:? > ${comboB?.name}";
                                          });
                                        },
                                      );
                                    }),
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
                                        return DropdownSearch<ComboModel>(
                                          enabled: deviceA != null,
                                          items: data,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value != comboA) {
                                                comboA = value;
                                                cableDescription =
                                                    "${value?.name} > ${comboB?.name}";
                                              }
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
                                                    comboA?.name ??
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
                                        devices = snapshot.data as List<Device>;
                                      } else {
                                        return const Center(
                                            child: CircularProgressIndicator(
                                          semanticsLabel: "Loading",
                                        ));
                                      }
                                      return DropdownSearch<Device>(
                                        enabled: cableBarcodeScan != null,
                                        dropdownBuilder: (context, item) {
                                          return Container(
                                            padding: const EdgeInsets.all(8),
                                            margin: const EdgeInsets.all(10),
                                            child: Text(item?.name ??
                                                deviceB?.name ??
                                                ""),
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
                                              labelText: deviceB?.name ??
                                                  "Scan QR Code",
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
                                        items: devices,
                                        itemAsString: (item) =>
                                            "${item.name} | ${item.location?.display} | ${item.rack?.name}",
                                        onChanged: (value) {
                                          setState(() {
                                            deviceB = value;
                                            comboB = null;
                                            cableDescription =
                                                "${comboA?.name} > ${value?.name}:?";
                                          });
                                        },
                                      );
                                    }),
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
                                          enabled: deviceB != null,
                                          items: data,
                                          onChanged: (value) {
                                            setState(() {
                                              if (value != comboB) {
                                                comboB = value;
                                                cableDescription =
                                                    "${comboA?.name} > ${value?.name}";
                                              }
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
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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

    if (await cablesAPI.checkExistenceByLabel(await getToken(), code)) {
      _setCurrentInformation(code);
      return code;
    } else {
      genSnack("Cable $code, doesn't exist or couldn't be found.");
      return "";
    }
  }

  @override
  bool get wantKeepAlive => true;

  Future<ComboModel?> getComboModel(
      String? terminationId, String? terminationType) async {
    if (terminationId == null || terminationType == null) {
      return null;
    }

    if (terminationType == "interface") {
      Interface? i =
          await interfacesAPI.getInterfaceByID(await getToken(), terminationId);
      return ComboModel(
          id: i?.id ?? 0,
          name: i?.name ?? "Unknown",
          url: i?.url ?? "Unknown",
          occupied: i?.occupied ?? false,
          objectType: terminationType,
          interface: i);
    } else if (terminationType == "poweroutlet") {
      PowerOutlet? i = await powerOutletsAPI.getPowerOutletByID(
          await getToken(), terminationId);
      return ComboModel(
          id: i?.id ?? 0,
          name: i?.name ?? "Unknown",
          url: i?.url ?? "Unknown",
          occupied: i?.occupied ?? false,
          objectType: terminationType,
          powerOutlet: i);
    } else if (terminationType == "powerport") {
      PowerPort? i =
          await powerPortsAPI.getPowerPortByID(await getToken(), terminationId);
      return ComboModel(
          id: i?.id ?? 0,
          name: i?.name ?? "Unknown",
          url: i?.url ?? "Unknown",
          occupied: i?.occupied ?? false,
          objectType: terminationType,
          powerPort: i);
    } else {
      return null;
    }
  }
}
