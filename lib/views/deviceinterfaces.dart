import 'package:flutter/material.dart';


class DeviceInterfaces extends StatefulWidget {
  const DeviceInterfaces({super.key});

  @override
  State<DeviceInterfaces> createState() => _DeviceInterfaceState();
}

class _DeviceInterfaceState extends State<DeviceInterfaces>
    with
        AutomaticKeepAliveClientMixin<DeviceInterfaces>,
        SingleTickerProviderStateMixin<DeviceInterfaces> {
  final _modifyConnectionKey = GlobalKey<FormState>();


  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Form(
        key: _modifyConnectionKey,
        child: Container(
          padding: const EdgeInsets.all(32.0),
          child: Text("Device Interfaces"),
        )
    );
  }

  @override
  bool get wantKeepAlive => true;
}
