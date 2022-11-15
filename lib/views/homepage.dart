import 'package:flutter/material.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/views/addconnection.dart';
import 'package:keeptrack/views/loginpage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.authProvider});
  final NetboxAuthProvider authProvider;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final SharedPreferences prefs;
  bool _isDark = false;
  @override
  //get username from auth provider
  void initState() {
    super.initState();
    getPrefs();
  }

  Future<String> getUsername() async {
    final provider = Provider.of<NetboxAuthProvider>(context, listen: false);
    return (await provider.getUsername() ?? "loading username...");
  }

  void getPrefs() async {
    prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('settings/dark-mode') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    //set theme to dark
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final sideAFormKey = GlobalKey<FormState>();

    return MaterialApp(
        theme: ThemeData(
          brightness: _isDark ? Brightness.dark : Brightness.light,
        ),
        home: Scaffold(
            key: scaffoldKey,
            endDrawer: Drawer(
              child: settingsDrawer(),
            ),
            appBar: AppBar(title: const Text('KeepTrack'),
                //show burger icon that opens drawer
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
                  )
                ]),
            body: Center(
                //form that has two dropbown buttons and a submit button
                child: Form(
                    key: sideAFormKey,
                    child: const SingleChildScrollView(
                      child: AddConnection(),
                    )))));
  }

  settingsDrawer() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 60.0, left: 20.0, right: 20.0),
        ),
        const Text("Settings", style: TextStyle(fontSize: 20)),
        FutureBuilder<String>(
            future: getUsername(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text("Welcome to keeptrack, ${snapshot.data!}!");
              }
              return const Text("Welcome to keeptrack!");
            }),
        const Padding(
          padding: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
        ),
        ListTile(
          title: const Text('Dark Mode'),
          trailing: Switch(
            value: _isDark,
            onChanged: (value) {
              setState(() {
                _isDark = value;
                prefs.setBool('settings/dark-mode', value);
              });
            },
          ),
        ),
        ElevatedButton(
            onPressed: () async {
              if (await Provider.of<NetboxAuthProvider>(context, listen: false)
                  .logout()) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logout successful')));
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const LoginPage()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Unable to delete netbox token')));
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const LoginPage()));
              }
            },
            child: const Text('Logout'))
      ],
    );
  }
}
