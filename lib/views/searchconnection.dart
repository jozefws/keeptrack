import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:keeptrack/api/cables_api.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/interfaces_api.dart';
import 'package:keeptrack/api/organisation_api.dart';
import 'package:keeptrack/models/cables.dart';
import 'package:keeptrack/models/interfaces.dart';
import 'package:keeptrack/models/locations.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/views/hierarchysearch.dart';
import 'package:keeptrack/views/interfaceView.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SearchConnection extends StatefulWidget {
  const SearchConnection({super.key});

  @override
  State<SearchConnection> createState() => _SearchConnectionState();
}

class _SearchConnectionState extends State<SearchConnection>
    with
        AutomaticKeepAliveClientMixin<SearchConnection>,
        SingleTickerProviderStateMixin<SearchConnection> {
  final _searchConnectionKey = GlobalKey<FormState>();
  final _searchByLabelKey = GlobalKey<FormState>();

  DevicesAPI devicesAPI = DevicesAPI();
  OrganisationAPI organisationAPI = OrganisationAPI();
  InterfacesAPI interfacesAPI = InterfacesAPI();
  CablesAPI cablesAPI = CablesAPI();

  late Location location;
  String locationName = "Select a location";
  int locationID = 1;
  final TextEditingController _cableBarcodeScanController =
      TextEditingController();

  String? cableBarcodeScan;

  Future<List<String>> _getDevices() async {
    var i = await devicesAPI.getDevices(await getToken());
    return i
        .map((e) =>
            "${e.name} | ${(e.rack?.name)?.substring(4) ?? "Unracked"} | ID${e.id}")
        .toList();
  }

  Future<List<Location>> _getLocations() async {
    var i = await organisationAPI.getLocations(await getToken());
    return i;
  }

  genSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  getToken() async {
    return await NetboxAuthProvider().getToken();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Form(
        key: _searchConnectionKey,
        child: SingleChildScrollView(
          child: Column(children: [
            Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                height: 280,
                color: Theme.of(context).colorScheme.onInverseSurface,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
                      child: Text(
                        "Search by Hierarchy",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(20),
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      //drop down search where the label is that items display name
                      //and the value is the items id
                      child: DropdownSearch<Location>(
                        dropdownBuilder: (context, item) {
                          return Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.all(10),
                            child: Text(locationName),
                          );
                        },
                        popupProps: PopupProps.modalBottomSheet(
                          loadingBuilder: (context, searchEntry) =>
                              const Center(
                            child: CircularProgressIndicator(),
                          ),
                          itemBuilder: (context, item, isSelected) => Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.all(10),
                            // if item has a parent then show name < parent name
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.display +
                                      (item.parent != null
                                          ? " < ${item.parent!.display}"
                                          : ""),
                                  style: TextStyle(
                                      fontWeight: item.parent == null
                                          ? FontWeight.bold
                                          : FontWeight.normal),
                                ),
                                if (item.parent == null)
                                  const Divider(
                                    color: Colors.grey,
                                    thickness: 1,
                                  ),
                              ],
                            ),
                          ),
                          showSearchBox: true,
                          searchDelay: const Duration(milliseconds: 100),
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: locationName,
                            ),
                          ),
                          modalBottomSheetProps: ModalBottomSheetProps(
                              isScrollControlled: true,
                              backgroundColor: Theme.of(context).primaryColor,
                              anchorPoint: const Offset(0.5, 5)),
                          constraints: const BoxConstraints(
                              maxHeight: 400, maxWidth: double.infinity),
                        ),
                        asyncItems: (items) async {
                          return await _getLocations();
                        },
                        onChanged: (value) {
                          setState(() {
                            locationName = value!.display;
                            location = value;
                          });
                        },
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(20),
                      child: FloatingActionButton.extended(
                          heroTag: "searchByHierarchy",
                          onPressed: () {
                            if (locationName == "Select a location") {
                              genSnack("Please select a location");
                              return;
                            }
                            //open material route to search by hierarchy
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HierarchySearch(
                                      location.slug, locationID, "LOCATION")),
                            );
                          },
                          label: const Text("Start Search"),
                          icon: const Icon(Icons.search)),
                    ),
                  ],
                )),
            Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                height: 380,
                color: Theme.of(context).colorScheme.onInverseSurface,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
                      child: Text(
                        "Search by Label",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(20),
                        child: FloatingActionButton.extended(
                            heroTag: "searchByLabel",
                            onPressed: () async {
                              _cableBarcodeScanController.text =
                                  (await openScanner(context))!;
                              if (_cableBarcodeScanController.text.isNotEmpty) {
                                //get a instance of the cable by the barcode as well as the interface it is connected to

                                Cable? cable = await cablesAPI.getCableByLabel(
                                    await getToken(),
                                    _cableBarcodeScanController.text);
                                if (cable == null) {
                                  genSnack("Cable not found");
                                  return;
                                }
                                Interface? interface =
                                    await interfacesAPI.getInterfaceByID(
                                        await getToken(),
                                        cable.terminationAId!);
                                //get the device that the interface is connected to
                                if (interface == null) {
                                  genSnack("Cable not found");
                                  return;
                                }
                                moveToInterface(interface);
                              }
                            },
                            label: const Text("Scan Cable QR"),
                            icon: const Icon(Icons.qr_code_scanner)),
                      ),
                    ),
                    Form(
                      key: _searchByLabelKey,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(20),
                        child: TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a cable ID';
                            }
                            return null;
                          },
                          controller: _cableBarcodeScanController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'or, enter Cable ID...',
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(20),
                      child: FloatingActionButton.extended(
                          heroTag: "searchByLabelManual",
                          onPressed: () async {
                            if (_searchByLabelKey.currentState!.validate()) {
                              genSnack("Searching for cable...");
                              Cable? cable = await cablesAPI.getCableByLabel(
                                  await getToken(),
                                  _cableBarcodeScanController.text);
                              if (cable == null) {
                                genSnack("Cable not found");
                                return;
                              }
                              Interface? interface =
                                  await interfacesAPI.getInterfaceByID(
                                      await getToken(), cable.terminationAId!);
                              //get the device that the interface is connected to
                              if (interface == null) {
                                genSnack("Cable not found");
                                return;
                              }
                              moveToInterface(interface);
                            }
                          },
                          label: const Text("Start Search"),
                          icon: const Icon(Icons.search)),
                    ),
                  ],
                )),
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
      return "032042";

      genSnack("No barcode detected");
      return "";
    }
    if (await cablesAPI.checkExistenceById(await getToken(), code)) {
      return "032042";
      // return code;
    } else {
      print("Cable $code, does not exist");
      return code;
    }
  }

  @override
  bool get wantKeepAlive => true;

  moveToInterface(Interface interface) {
    print("Moving to interface ${interface.id}");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InterfaceView(interface)),
    );
  }
}
