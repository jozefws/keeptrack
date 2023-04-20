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
  const AddConnection(this.comboModel, this.deviceID, {super.key});
  final ComboModel? comboModel;
  final int? deviceID;

  @override
  State<AddConnection> createState() => _AddConnectionState();
}

class _AddConnectionState extends State<AddConnection>
    with
        AutomaticKeepAliveClientMixin<AddConnection>,
        SingleTickerProviderStateMixin<AddConnection> {
  final _addConnectionKey = GlobalKey<FormState>();
  TabController? _tabController;

  // Define local variables
  List<Device> devices = [];

  String deviceAName = "Device A", deviceBName = "Device B";

  Device? deviceA, deviceB;
  ComboModel? comboA, comboB;

  ConnectionColour? connectionColours;
  String? cableType;

  // Define API classes for use
  CablesAPI cablesAPI = CablesAPI();
  DevicesAPI devicesAPI = DevicesAPI();
  InterfacesAPI interfacesAPI = InterfacesAPI();
  PowerPortsAPI powerPortsAPI = PowerPortsAPI();
  PowerOutletsAPI powerOutletsAPI = PowerOutletsAPI();

  // Define controllers for text fields
  final TextEditingController _cableBarcodeScanController =
      TextEditingController();

  // Fetch all devices from Netbox
  Future<List<Device>> _getDevices() async {
    var i = await devicesAPI.getDevices(await getToken());
    return i;
  }

  // Fetch a single device from Netbox by ID
  Future<Device?> _getDevicesByID(int? deviceID) async {
    if (deviceID == null) {
      return null;
    }
    var i =
        await devicesAPI.getDeviceByID(await getToken(), deviceID.toString());
    if (i == null) {
      return null;
    }
    return i;
  }

  // Fetch all interfaces from Netbox by device ID
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
      for (var element in value) {
        for (var e in element) {
          if (e is Interface && e.occupied == false) {
            comboList.add(ComboModel(
                id: e.id,
                name: e.name,
                url: e.url,
                objectType: "interface",
                occupied: e.occupied,
                interface: e));
          } else if (e is PowerPort && e.occupied == false) {
            comboList.add(ComboModel(
                id: e.id,
                name: e.name,
                url: e.url,
                objectType: "powerport",
                occupied: e.occupied,
                powerPort: e));
          } else if (e is PowerOutlet && e.occupied == false) {
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
      genSnack("No free ports found on device");
      return [];
    }
    return comboList;
  }

  @override
  initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    checkRootInit();
  }

  // Check if the root widget has passed a device ID
  void checkRootInit() async {
    if (widget.comboModel != null) {
      comboA = widget.comboModel;
      deviceA = await _getDevicesByID(widget.deviceID);
      deviceAName = deviceA?.name ?? "Device A";
      setState(() {});
    }
  }

  // Show a snack bar with a message
  genSnack(String message) {
    hideSnack();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Hide the current snack bar
  hideSnack() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  // Get the token from the NetboxAuthProvider
  getToken() async {
    return await NetboxAuthProvider().getToken();
  }

  // Add a new connection to Netbox using the API
  _addNewConnection() async {
    // String? barcode, type;
    String? type;
    Interface? intA, intB;
    PowerPort? ppA, ppB;
    PowerOutlet? poA, poB;

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

    if (type != null &&
        comboA != null &&
        comboB != null &&
        connectionColours != null) {
      String description =
          "$deviceAName:${comboA?.name} > $deviceBName:${comboB?.name}";
      String label = "${comboA?.name} > ${comboB?.name}";

      // Create a new cable object with a fake ID
      Cable newCable = Cable(
          id: -1,
          label: label,
          type: type,
          color: connectionColours?.hexColor.toLowerCase(),
          terminationAType: "dcim.${comboA?.objectType}",
          terminationAId: comboA?.id.toString(),
          terminationBType: "dcim.${comboB?.objectType}",
          terminationBId: comboB?.id.toString(),
          status: "connected",
          description: description);

      String? result =
          await cablesAPI.addConnection(await getToken(), newCable);

      if (result != null) {
        genSnack('Connection added successfully');
        setState(() {
          comboA = null;
          comboB = null;
          _cableBarcodeScanController.clear();
        });
        showSuccessDialog(result, label);
      } else {
        genSnack('Error adding connection');
      }
    } else {
      genSnack('Error adding connection, there was a null value');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Device>>(
        future: _getDevices(),
        builder: (context, snapshot) {
          // Show a loading screen if the data is not ready
          if (snapshot.hasData == false) {
            return Container(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Center(child: CircularProgressIndicator()),
                  SizedBox(height: 10),
                  Center(child: Text("Loading devices...")),
                ],
              ),
            );
          }
          devices = snapshot.data!;
          return Form(
              key: _addConnectionKey,
              child: SingleChildScrollView(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
                              height: 205,
                              width: double.infinity,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(
                                            24, 20, 24, 20),
                                        child: DropdownSearch<Device>(
                                          filterFn: (item, filter) => item.name
                                              .toLowerCase()
                                              .contains(filter.toLowerCase()),
                                          dropdownDecoratorProps:
                                              const DropDownDecoratorProps(
                                            dropdownSearchDecoration:
                                                InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    label: Text("Device A")),
                                          ),
                                          dropdownBuilder: (context, item) {
                                            return Text(
                                                item?.name ?? deviceAName);
                                          },
                                          popupProps:
                                              PopupProps.modalBottomSheet(
                                            itemBuilder:
                                                (context, item, isSelected) =>
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
                                            searchDelay: const Duration(
                                                milliseconds: 100),
                                            searchFieldProps: TextFieldProps(
                                              autofocus: true,
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
                                                            .colorScheme
                                                            .primaryContainer,
                                                    anchorPoint:
                                                        const Offset(0.5, 5)),
                                            constraints: const BoxConstraints(
                                                maxHeight: 400,
                                                maxWidth: double.infinity),
                                          ),
                                          items: devices,
                                          onChanged: (value) {
                                            setState(() {
                                              deviceAName = value?.name ??
                                                  "Select a device";
                                              deviceA = value;
                                              comboA = null;
                                            });
                                          },
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(
                                            24, 10, 24, 0),
                                        child: FutureBuilder(
                                            future: _getMixedPortsByDeviceID(
                                                deviceA?.id.toString() ?? ""),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData &&
                                                  snapshot.connectionState !=
                                                      ConnectionState.waiting) {
                                                var data = snapshot.data!;
                                                return Column(
                                                  children: [
                                                    DropdownSearch<ComboModel>(
                                                      enabled:
                                                          deviceA != null &&
                                                              data.isNotEmpty,
                                                      items: data,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          comboA = value;
                                                        });
                                                      },
                                                      popupProps: PopupProps
                                                          .modalBottomSheet(
                                                        showSearchBox: true,
                                                        modalBottomSheetProps:
                                                            ModalBottomSheetProps(
                                                                isScrollControlled:
                                                                    true,
                                                                backgroundColor: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primaryContainer,
                                                                anchorPoint:
                                                                    const Offset(
                                                                        0.5,
                                                                        5)),
                                                        constraints:
                                                            const BoxConstraints(
                                                                maxHeight: 400,
                                                                maxWidth: double
                                                                    .infinity),
                                                        searchFieldProps:
                                                            const TextFieldProps(
                                                          autofocus: true,
                                                          decoration:
                                                              InputDecoration(
                                                            border:
                                                                OutlineInputBorder(),
                                                            label: Text(
                                                                "Interface A"),
                                                          ),
                                                        ),
                                                      ),
                                                      itemAsString: (item) =>
                                                          "${item.name} | ${item.occupied == true ? "Occupied" : "Free"}",
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
                                                        return Text(
                                                            item?.name ??
                                                                comboA?.name ??
                                                                "");
                                                      },
                                                    )
                                                  ],
                                                );
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
                                            24, 20, 24, 20),
                                        child: DropdownSearch<Device>(
                                          filterFn: (item, filter) => item.name
                                              .toLowerCase()
                                              .contains(filter.toLowerCase()),
                                          dropdownDecoratorProps:
                                              const DropDownDecoratorProps(
                                            dropdownSearchDecoration:
                                                InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                    label: Text("Device B")),
                                          ),
                                          dropdownBuilder: (context, item) {
                                            return Text(
                                                item?.name ?? deviceBName);
                                          },
                                          popupProps:
                                              PopupProps.modalBottomSheet(
                                            itemBuilder:
                                                (context, item, isSelected) =>
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
                                            searchDelay: const Duration(
                                                milliseconds: 100),
                                            searchFieldProps: TextFieldProps(
                                              autofocus: true,
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
                                                            .colorScheme
                                                            .primaryContainer,
                                                    anchorPoint:
                                                        const Offset(0.5, 5)),
                                            constraints: const BoxConstraints(
                                                maxHeight: 400,
                                                maxWidth: double.infinity),
                                          ),
                                          items: devices,
                                          onChanged: (value) {
                                            setState(() {
                                              deviceBName = value?.name ??
                                                  "Select a device";
                                              deviceB = value;
                                              comboB = null;
                                            });
                                          },
                                        ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.fromLTRB(
                                            24, 10, 24, 0),
                                        child: FutureBuilder(
                                            future: _getMixedPortsByDeviceID(
                                                deviceB?.id.toString() ?? ""),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData &&
                                                  snapshot.connectionState !=
                                                      ConnectionState.waiting) {
                                                if (snapshot.data == null) {
                                                  return const Text("");
                                                }
                                                var data = snapshot.data!;
                                                return Column(
                                                  children: [
                                                    DropdownSearch<ComboModel>(
                                                      enabled:
                                                          deviceB != null &&
                                                              data.isNotEmpty,
                                                      items: data,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          comboB = value;
                                                        });
                                                      },
                                                      popupProps: PopupProps
                                                          .modalBottomSheet(
                                                        showSearchBox: true,
                                                        modalBottomSheetProps:
                                                            ModalBottomSheetProps(
                                                                isScrollControlled:
                                                                    true,
                                                                backgroundColor: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primaryContainer,
                                                                anchorPoint:
                                                                    const Offset(
                                                                        0.5,
                                                                        5)),
                                                        constraints:
                                                            const BoxConstraints(
                                                                maxHeight: 400,
                                                                maxWidth: double
                                                                    .infinity),
                                                        searchFieldProps:
                                                            const TextFieldProps(
                                                          autofocus: true,
                                                          decoration:
                                                              InputDecoration(
                                                            border:
                                                                OutlineInputBorder(),
                                                            label: Text(
                                                                "Interface B"),
                                                          ),
                                                        ),
                                                      ),
                                                      itemAsString: (item) =>
                                                          "${item.name} | ${item.occupied == true ? "Occupied" : "Free"}",
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
                                                        return Text(
                                                            item?.name ??
                                                                comboB?.name ??
                                                                "");
                                                      },
                                                    )
                                                  ],
                                                );
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
                          margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          color: Theme.of(context).colorScheme.onInverseSurface,
                          child: Column(children: [
                            Container(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
                              child: Text(
                                // "Scan cable QR and select Cable Type",
                                "Select Cable Type and Color (VLAN)",
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            Container(
                                padding: const EdgeInsets.all(20),
                                width: double.infinity,
                                //dropdown menu for every colour in VLANColor
                                child:
                                    DropdownButtonFormField<ConnectionColour>(
                                  validator: (value) => value == null
                                      ? "Please select a cable color"
                                      : null,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  value: connectionColours,
                                  itemHeight: 60,
                                  items: nbConnectionColours.map((colour) {
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
                                                  borderRadius:
                                                      const BorderRadius.all(
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
                                  validator: (value) => value == null
                                      ? "Please select a cable type"
                                      : null,
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
                                      child:
                                          Text("Direct Attach Copper (SFP+)"),
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
                                      border: OutlineInputBorder(),
                                      labelText: 'Select a Cable Type')),
                            ),
                          ])),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                        child: FloatingActionButton.extended(
                            heroTag: "addConnection",
                            onPressed: () {
                              if (_addConnectionKey.currentState!.validate()) {
                                _addConnectionKey.currentState!.save();
                                _addNewConnection();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("Please fill in all fields")));
                              }
                            },
                            label: const Text("Add Connection"),
                            icon: const Icon(Icons.add)),
                      ),
                    ],
                  ),
                ),
              ));
        });
  }

  // Keep the state of the page when navigating from tab to tab
  @override
  bool get wantKeepAlive => true;

  // Show a dialog with the new cable id and the cable description
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
                    ElevatedButton(
                        onPressed: () {
                          clearFields();
                          Navigator.pop(context);
                        },
                        child: const Text("OK")),
                  ],
                ),
              ));
        });
  }

  //  Clear all the fields in the form
  void clearFields() {
    setState(() {
      comboA = null;
      comboB = null;
      cableType = null;
      connectionColours = null;
    });
  }
}
