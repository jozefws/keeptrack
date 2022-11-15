import 'package:flutter/material.dart';
import 'package:keeptrack/api/devices_api.dart';
import 'package:keeptrack/api/racks_api.dart';
import 'package:keeptrack/models/racks.dart';
import 'package:keeptrack/models/devices.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';

class AddConnection extends StatefulWidget {
  const AddConnection({super.key});

  @override
  State<AddConnection> createState() => _AddConnectionState();
}

class _AddConnectionState extends State<AddConnection> {
  List<Rack> racks = [];

  @override
  initState() {
    _getRacks();
    super.initState();
  }

  getToken() async {
    return await NetboxAuthProvider().getToken();
  }

  Future<void> _getRacks() async {
    final i = await RacksAPI.getRacks(await getToken());
    setState(() {
      racks = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(children: [
        DropdownButtonFormField(
          items: racks
              .map((e) => DropdownMenuItem(
                    value: e.id,
                    child: Text(e.name),
                  ))
              .toList(),
          onChanged: (value) {
            // do something with value
          },
        ),
      ]),
    );
  }
}
