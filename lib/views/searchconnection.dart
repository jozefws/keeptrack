import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:keeptrack/api/cables_api.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/organisation_api.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/views/hierarchysearch.dart';
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

  DevicesAPI devicesAPI = DevicesAPI();
  OrganisationAPI organisationAPI = OrganisationAPI();
  String location = "Select Location";
  int locationID = 1;
  final TextEditingController _cableBarcodeScanController =
      TextEditingController();

  String? cableBarcodeScan;

  CablesAPI cablesAPI = CablesAPI();

  Future<List<String>> _getDevices() async {
    var i = await devicesAPI.getDevices(await getToken());
    return i
        .map((e) =>
            "${e.name} | ${(e.rack?.name)?.substring(4) ?? "Unracked"} | ID${e.id}")
        .toList();
  }

  Future<List<String>> _getLocations() async {
    var i = await organisationAPI.getLocations(await getToken());

    return i
        .map((e) =>
            "${e.display} ${e.parent != null ? " < ${e.parent?.display}" : "" "${e.parent != null ? " < ${e.parent?.display}" : ""}"}")
        .toList();
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
                      child: DropdownSearch(
                        dropdownBuilder: (context, item) {
                          return Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.all(10),
                            child: Text(
                              location,
                            ),
                          );
                        },
                        popupProps: PopupProps.modalBottomSheet(
                          showSearchBox: true,
                          searchDelay: const Duration(milliseconds: 100),
                          searchFieldProps: TextFieldProps(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: location,
                            ),
                          ),
                          modalBottomSheetProps: ModalBottomSheetProps(
                              isScrollControlled: true,
                              backgroundColor: Theme.of(context).primaryColor,
                              anchorPoint: const Offset(0.5, 5)),
                          constraints: const BoxConstraints(
                              maxHeight: 400, maxWidth: double.infinity),
                        ),
                        asyncItems: (_) => _getLocations(),
                        onChanged: (value) {
                          setState(() {
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
                            //open material route to search by hierarchy
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => HierarchySearch(
                                      location, locationID, "LOCATION")),
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
                height: 370,
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
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(20),
                      child: FloatingActionButton.extended(
                          heroTag: "searchByLabel",
                          onPressed: () async => _cableBarcodeScanController
                              .text = (await openScanner(context))!,
                          label: const Text("Scan Cable QR"),
                          icon: const Icon(Icons.qr_code_scanner)),
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(20),
                      child: TextField(
                        controller: _cableBarcodeScanController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'or, enter Cable ID...',
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(20),
                      child: FloatingActionButton.extended(
                          heroTag: "searchByLabelManual",
                          onPressed: () {
                            Null;
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
      genSnack("No barcode detected");
      return "";
    }
    if (await cablesAPI.checkExistenceById(await getToken(), code)) {
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
