import 'package:flutter/material.dart';


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
          child: Text("Modify Connection"),
        )
    );
  }

  @override
  bool get wantKeepAlive => true;
}
