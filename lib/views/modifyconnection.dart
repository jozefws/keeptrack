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
  const ModifyConnection(this.cableID, {super.key});
  final String? cableID;

  @override
  State<ModifyConnection> createState() => _ModifyConnectionState();
}

class _ModifyConnectionState extends State<ModifyConnection>
    with
        AutomaticKeepAliveClientMixin<ModifyConnection>,
        SingleTickerProviderStateMixin<ModifyConnection> {
  // Keys for the form
  final _modifyConnectionKey = GlobalKey<FormState>();

  // Controllers for the barcode scan
  final TextEditingController _cableBarcodeScanController =
      TextEditingController();

  // Tab controller for the two tabs
  TabController? _tabController;

  // List of devices and interfaces for the dropdowns
  List<Device> devices = [];
  List<ComboModel> interfaces = [];

  String? cableBarcodeScan, cableType, cableStatus, cableDescription;

  // Device and interface and cable declarations for the dropdowns
  Device? deviceA, deviceB, originalDeviceA, originalDeviceB;
  ComboModel? comboA, comboB, originalComboA, originalComboB;
  Cable? currentCable;

  // API calls for the different models
  CablesAPI cablesAPI = CablesAPI();
  DevicesAPI devicesAPI = DevicesAPI();
  InterfacesAPI interfacesAPI = InterfacesAPI();
  PowerPortsAPI powerPortsAPI = PowerPortsAPI();
  PowerOutletsAPI powerOutletsAPI = PowerOutletsAPI();

  @override
  initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();

    // If the class is called with a cableID, set the current information
    if (widget.cableID != "") {
      cableBarcodeScan = widget.cableID;
      _setCurrentInformation(cableBarcodeScan ?? "");
    }
  }

  // Generate a snack bar with the given message
  genSnack(String message) {
    if (message == "") return;
    hideSnack();
    try {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {}
  }

  // Hide the current snack bar
  hideSnack() {
    try {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {}
  }

  // Get the list of devices from the API
  Future<List<Device>> _getDevices() async {
    var i = await devicesAPI.getDevices(await getToken());
    if (i.isEmpty) {
      genSnack("No devices found");
      return [];
    }
    return i;
  }

  // Get the device with the given ID from the API
  Future<Device?> getDeviceByID(String? id) async {
    if (id == null || id == "") {
      return null;
    }
    var i = await devicesAPI.getDeviceByID(await getToken(), id);
    return i;
  }

  // Get all interfaces, power ports and poweroutlets from the API based on the given device ID
  Future<List<ComboModel>?> _getMixedPortsByDeviceID(
      String deviceID, int? interfaceID) async {
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

    // map all interfaces, power ports and poweroutlets to a single list
    await Future.wait([interfaces, powerPorts, powerOutlets]).then((value) {
      for (var element in value) {
        for (var e in element) {
          if (e is Interface && (e.occupied == false || e.id == interfaceID)) {
            comboList.add(ComboModel(
                id: e.id,
                name: e.name,
                url: e.url,
                objectType: "interface",
                occupied: e.occupied,
                interface: e));
          } else if (e is PowerPort &&
              (e.occupied == false || e.id == interfaceID)) {
            comboList.add(ComboModel(
                id: e.id,
                name: e.name,
                url: e.url,
                objectType: "powerport",
                occupied: e.occupied,
                powerPort: e));
          } else if (e is PowerOutlet &&
              (e.occupied == false || e.id == interfaceID)) {
            comboList.add(ComboModel(
                id: e.id,
                name: e.name,
                url: e.url,
                objectType: "poweroutlet",
                occupied: e.occupied,
                powerOutlet: e));
          }
        }
      }
    });
    if (comboList.isEmpty) {
      genSnack("No ports found on device");
      return [];
    }
    return comboList;
  }

  Future<ComboModel?> getComboModel(
      String? terminationId, String? terminationType) async {
    if (terminationId == null || terminationType == null) {
      genSnack("Termination ID or Type is null");
      return null;
    }

    if (terminationType == "dcim.interface") {
      Interface? i =
          await interfacesAPI.getInterfaceByID(await getToken(), terminationId);
      return ComboModel(
          id: i?.id ?? 0,
          name: i?.name ?? "Unknown",
          url: i?.url ?? "Unknown",
          occupied: i?.occupied ?? false,
          objectType: terminationType,
          interface: i);
    } else if (terminationType == "dcim.poweroutlet") {
      PowerOutlet? i = await powerOutletsAPI.getPowerOutletByID(
          await getToken(), terminationId);
      return ComboModel(
          id: i?.id ?? 0,
          name: i?.name ?? "Unknown",
          url: i?.url ?? "Unknown",
          occupied: i?.occupied ?? false,
          objectType: terminationType,
          powerOutlet: i);
    } else if (terminationType == "dcim.powerport") {
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

  void _clearCurrentInformation() {
    setState(() {
      _cableBarcodeScanController.text = "";
      cableBarcodeScan = null;
      cableDescription = "";
      deviceA = null;
      deviceB = null;
      comboA = null;
      comboB = null;
    });
  }

  // Set the current information based on the given cable ID
  void _setCurrentInformation(String code) async {
    _clearCurrentInformation();
    _cableBarcodeScanController.text = code;
    genSnack("Loading cable information");
    Future<Cable?> cableDevices =
        cablesAPI.getCableByID(await getToken(), code);
    if (await cableDevices == null) {
      genSnack("No cable found");
      return;
    }
    cableDevices.then((value) async {
      originalDeviceA = await getDeviceByID(value?.terminationADeviceID);
      originalDeviceB = await getDeviceByID(value?.terminationBDeviceID);

      originalComboA =
          await getComboModel(value?.terminationAId, value?.terminationAType);
      originalComboB =
          await getComboModel(value?.terminationBId, value?.terminationBType);

      if (originalDeviceA == null ||
          originalDeviceB == null ||
          originalComboA == null ||
          originalComboB == null) {
        genSnack("Error setting cable information, please try on web app.");
        return;
      }

      if (value == null) {
        genSnack("No cable found");
      } else {
        setState(() {
          currentCable = value;
          cableBarcodeScan = currentCable?.label;
          cableDescription = currentCable?.description;
          deviceA = originalDeviceA;
          deviceB = originalDeviceB;
          comboA = originalComboA;
          comboB = originalComboB;
        });
      }
    });
  }

  // Verify if the cable has been modified and if so, call the modifyCable function
  verifyModifications() {
    if (deviceA?.name != currentCable?.terminationADeviceName ||
        deviceB?.name != currentCable?.terminationBDeviceName ||
        comboA?.name != currentCable?.terminationAName ||
        comboB?.name != currentCable?.terminationBName) {
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

  // Show an alert dialog to confirm the user wants to modify the cable
  // If the user confirms, then modify the cable.
  void modifyCable() async {
    if (await showAlert()) {
      currentCable?.terminationADeviceID = deviceA?.id.toString();
      currentCable?.terminationAType = comboA?.objectType;
      currentCable?.terminationBDeviceID = deviceB?.id.toString();
      currentCable?.terminationBType = comboB?.objectType;
      currentCable?.terminationAId = comboA?.id.toString();
      currentCable?.terminationBId = comboB?.id.toString();
      currentCable?.description = cableDescription;
      currentCable?.status = "connected";

      if (currentCable != null) {
        // Call the API to modify the cable, uses the updateConnectionBAD function
        // because the updateConnection function does not work due to a bug in the API,
        // github issue: https://github.com/netbox-community/netbox/issues/11901
        String result = await cablesAPI.updateConnectionBAD(
            await getToken(), currentCable as Cable);
        if (result != "false") {
          _setCurrentInformation(result);
          genSnack("Cable modified successfully, updating view...");
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

  // Show an alert dialog to confirm the user wants to modify the cable
  // If the user confirms, then modify the cable.
  // Shows a summary of the changes to be made
  Future showAlert() {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text("Confirm Modification"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Confirm the following changes:"),
                    Container(
                        margin: const EdgeInsets.only(top: 40),
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
                            Center(
                              child: Text(
                                currentCable?.description != cableDescription
                                    ? "${currentCable?.description ?? "None"}\nV\n$cableDescription"
                                    : "No changes",
                                textAlign: TextAlign.center,
                              ),
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
                        hideSnack();
                        Navigator.of(context).pop(true);
                      },
                      child: const Text("Confirm"))
                ]));
  }

  // Get the token from the NetboxAuthProvider
  getToken() async {
    return await NetboxAuthProvider().getToken();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Form(
          key: _modifyConnectionKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    color: Theme.of(context).colorScheme.onInverseSurface,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                                  validator: (value) => value!.isEmpty
                                      ? "Please enter a cable ID"
                                      : null,
                                  //set the keyboard type to number only
                                  keyboardType: TextInputType.number,
                                  controller: _cableBarcodeScanController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    label: Text("Cable ID"),
                                  ),
                                  //when the user is done typing, set the current information
                                  onFieldSubmitted: (value) {
                                    if (_modifyConnectionKey.currentState!
                                        .validate()) {
                                      _cableBarcodeScanController.text = value;
                                      _modifyConnectionKey.currentState!.save();
                                      _setCurrentInformation(value);
                                    }
                                  },
                                ),
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Center(
                            child: Text(
                              utf8.decode(currentCable?.label.runes.toList() ??
                                  "Scan or type a cable code to start"
                                      .runes
                                      .toList()),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          //show color of cable
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
                FutureBuilder<List<Device>>(
                    future: _getDevices(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData == false) {
                        return Container(
                            height: 270,
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            color:
                                Theme.of(context).colorScheme.onInverseSurface,
                            child: Column(
                              children: [
                                const SizedBox(
                                  height: 20,
                                ),
                                const CircularProgressIndicator(),
                                const SizedBox(
                                  height: 20,
                                ),
                                Text(
                                  "Loading devices...",
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ],
                            ));
                      }
                      devices = snapshot.data!;
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        color: Theme.of(context).colorScheme.onInverseSurface,
                        child: Column(
                          children: [
                            TabBar(
                                indicatorColor:
                                    Theme.of(context).colorScheme.primary,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicatorWeight: 3,
                                labelColor:
                                    Theme.of(context).colorScheme.primary,
                                labelPadding: const EdgeInsets.all(8),
                                unselectedLabelColor: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .color,
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
                                          margin: const EdgeInsets.fromLTRB(
                                              24, 30, 24, 24),
                                          child: DropdownSearch<Device>(
                                            enabled: cableBarcodeScan != null,
                                            dropdownDecoratorProps:
                                                const DropDownDecoratorProps(
                                              dropdownSearchDecoration:
                                                  InputDecoration(
                                                      border:
                                                          OutlineInputBorder(),
                                                      label: Text("Device A")),
                                            ),
                                            dropdownBuilder: (context, item) {
                                              return Text(item?.name ??
                                                  deviceA?.name ??
                                                  "");
                                            },
                                            popupProps:
                                                PopupProps.modalBottomSheet(
                                              showSearchBox: true,
                                              searchDelay: const Duration(
                                                  milliseconds: 100),
                                              searchFieldProps:
                                                  const TextFieldProps(
                                                //open the keyboard automatically,
                                                autofocus: true,
                                                decoration: InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    label: Text("Device A")),
                                              ),
                                              modalBottomSheetProps:
                                                  ModalBottomSheetProps(
                                                      isScrollControlled: true,
                                                      backgroundColor:
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primaryContainer,
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
                                          )),
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(
                                            24, 8, 24, 8),
                                        child: FutureBuilder(
                                            future: _getMixedPortsByDeviceID(
                                                deviceA?.id.toString() ?? "",
                                                originalComboA?.id),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData &&
                                                  snapshot.connectionState !=
                                                      ConnectionState.waiting) {
                                                interfaces = snapshot.data
                                                    as List<ComboModel>;
                                              } else {
                                                return Row(
                                                  children: const [
                                                    Text("Loading ports..."),
                                                    SizedBox(
                                                      width: 24,
                                                    ),
                                                    CircularProgressIndicator(),
                                                  ],
                                                );
                                              }
                                              return DropdownSearch<ComboModel>(
                                                selectedItem: comboA,
                                                enabled: deviceA != null,
                                                dropdownDecoratorProps:
                                                    const DropDownDecoratorProps(
                                                  dropdownSearchDecoration:
                                                      InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          label: Text(
                                                              "Interface A")),
                                                ),
                                                dropdownBuilder:
                                                    (context, item) {
                                                  return Text(item?.name ??
                                                      comboA?.name ??
                                                      "");
                                                },
                                                popupProps:
                                                    PopupProps.modalBottomSheet(
                                                  showSearchBox: true,
                                                  searchDelay: const Duration(
                                                      milliseconds: 100),
                                                  searchFieldProps:
                                                      TextFieldProps(
                                                    autofocus: true,
                                                    decoration: InputDecoration(
                                                      border:
                                                          const OutlineInputBorder(),
                                                      labelText: comboA?.name ??
                                                          "Scan QR Code",
                                                    ),
                                                  ),
                                                  modalBottomSheetProps:
                                                      ModalBottomSheetProps(
                                                          isScrollControlled:
                                                              true,
                                                          backgroundColor: Theme
                                                                  .of(context)
                                                              .colorScheme
                                                              .primaryContainer,
                                                          anchorPoint:
                                                              const Offset(
                                                                  0.5, 5)),
                                                  constraints:
                                                      const BoxConstraints(
                                                          maxHeight: 400,
                                                          maxWidth:
                                                              double.infinity),
                                                ),
                                                items: interfaces,
                                                itemAsString: (item) =>
                                                    "${item.name} | ${item.occupied == true ? "Current Port" : "Free"}",
                                                onChanged: (value) {
                                                  if (value != comboA) {
                                                    comboA = value;
                                                    cableDescription =
                                                        "${value?.name} > ${comboB?.name}";
                                                  }
                                                },
                                              );
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
                                          margin: const EdgeInsets.fromLTRB(
                                              24, 30, 24, 24),
                                          child: DropdownSearch<Device>(
                                            enabled: cableBarcodeScan != null,
                                            dropdownDecoratorProps:
                                                const DropDownDecoratorProps(
                                              dropdownSearchDecoration:
                                                  InputDecoration(
                                                      border:
                                                          OutlineInputBorder(),
                                                      label: Text("Device B")),
                                            ),
                                            dropdownBuilder: (context, item) {
                                              return Text(item?.name ??
                                                  deviceB?.name ??
                                                  "");
                                            },
                                            popupProps:
                                                PopupProps.modalBottomSheet(
                                              showSearchBox: true,
                                              searchDelay: const Duration(
                                                  milliseconds: 100),
                                              searchFieldProps: TextFieldProps(
                                                autofocus: true,
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
                                                              .colorScheme
                                                              .primaryContainer,
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
                                          )),
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(
                                            24, 8, 24, 8),
                                        child: FutureBuilder(
                                            future: _getMixedPortsByDeviceID(
                                                deviceB?.id.toString() ?? "",
                                                originalComboB?.id),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData &&
                                                  snapshot.connectionState !=
                                                      ConnectionState.waiting) {
                                                interfaces = snapshot.data
                                                    as List<ComboModel>;
                                              } else {
                                                return Row(
                                                  children: const [
                                                    Text("Loading ports..."),
                                                    SizedBox(
                                                      width: 24,
                                                    ),
                                                    CircularProgressIndicator(),
                                                  ],
                                                );
                                              }
                                              return DropdownSearch<ComboModel>(
                                                selectedItem: comboB,
                                                enabled: deviceB != null,
                                                dropdownDecoratorProps:
                                                    const DropDownDecoratorProps(
                                                  dropdownSearchDecoration:
                                                      InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          label: Text(
                                                              "Interface B")),
                                                ),
                                                dropdownBuilder:
                                                    (context, item) {
                                                  return Text(item?.name ??
                                                      comboB?.name ??
                                                      "");
                                                },
                                                popupProps:
                                                    PopupProps.modalBottomSheet(
                                                  showSearchBox: true,
                                                  searchDelay: const Duration(
                                                      milliseconds: 100),
                                                  searchFieldProps:
                                                      TextFieldProps(
                                                    autofocus: true,
                                                    decoration: InputDecoration(
                                                      border:
                                                          const OutlineInputBorder(),
                                                      labelText: comboB?.name ??
                                                          "Scan QR Code",
                                                    ),
                                                  ),
                                                  modalBottomSheetProps:
                                                      ModalBottomSheetProps(
                                                          isScrollControlled:
                                                              true,
                                                          backgroundColor: Theme
                                                                  .of(context)
                                                              .colorScheme
                                                              .primaryContainer,
                                                          anchorPoint:
                                                              const Offset(
                                                                  0.5, 5)),
                                                  constraints:
                                                      const BoxConstraints(
                                                          maxHeight: 400,
                                                          maxWidth:
                                                              double.infinity),
                                                ),
                                                items: interfaces,
                                                itemAsString: (item) =>
                                                    "${item.name} | ${item.occupied == true ? "Current Port" : "Free"}",
                                                onChanged: (value) {
                                                  if (value != comboB) {
                                                    comboB = value;
                                                    cableDescription =
                                                        "${comboA?.name} > ${value?.name}";
                                                  }
                                                },
                                              );
                                            }),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: FloatingActionButton.extended(
                      heroTag: "modifyConnection",
                      // if (cableBarcodeScan == null) then disable button
                      onPressed: () {
                        //validate form
                        if (_modifyConnectionKey.currentState!.validate()) {
                          cableBarcodeScan == null
                              ? genSnack("Scan a cable first")
                              : verifyModifications();
                        }
                      },
                      label: const Text("Modify Connection"),
                      icon: const Icon(Icons.add)),
                ),
              ],
            ),
          )),
    );
  }

  // Open Scanner and return barcode
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

  // Keep the state of the tab when switching between tabs
  @override
  bool get wantKeepAlive => true;
}
