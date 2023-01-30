import 'package:flutter/material.dart';


class SearchConnection extends StatefulWidget {
  const SearchConnection({super.key});

  @override
  State<SearchConnection> createState() => _SearchConnectionState();
}

class _SearchConnectionState extends State<SearchConnection>
    with
        AutomaticKeepAliveClientMixin<SearchConnection>,
        SingleTickerProviderStateMixin<SearchConnection> {
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
          child: Text("Search Connection"),
        )
    );
  }

  @override
  bool get wantKeepAlive => true;
}
