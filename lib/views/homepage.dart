import 'package:flutter/material.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/views/addconnectionNew.dart';
import 'package:keeptrack/views/deviceinterfaces.dart';
import 'package:keeptrack/views/loginpage.dart';
import 'package:keeptrack/views/searchconnection.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'modifyconnection.dart';

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

  static int selectedIndex = 2;

  static const List<Widget> navPages = <Widget>[
    ModifyConnection(),
    AddConnection(),
    SearchConnection(),
    DeviceInterfaces()
  ];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    //set theme to dark
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return MaterialApp(
        theme: ThemeData(
          brightness: _isDark ? Brightness.dark : Brightness.light,
        ),
        home: Scaffold(
            key: scaffoldKey,
            endDrawer: Drawer(
              child: settingsDrawer(scaffoldKey),
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
              child: navPages.elementAt(selectedIndex),
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_fix_high),
                  label: 'Modify',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add_link),
                  label: 'Add',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.screen_search_desktop_outlined),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_ethernet),
                  label: 'Interfaces',
                ),
              ],
              currentIndex: selectedIndex,
              selectedItemColor: Theme.of(context).colorScheme.secondary,
              onTap: onItemTapped,
            ),
        )
    );
  }

  settingsDrawer(Key scaffoldKey) {
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
        const Padding(
          padding: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
        ),
        ElevatedButton(
            onPressed: () async {
              if (await Provider.of<NetboxAuthProvider>(context, listen: false)
                  .logout()) {
                ScaffoldMessenger(
                    key: scaffoldKey,
                    child: const SnackBar(content: Text('Logout successful')));
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const LoginPage()));
              } else {
                ScaffoldMessenger(
                    key: scaffoldKey,
                    child: const SnackBar(
                        content: Text('Unable to delete token')));
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => const LoginPage()));
              }
            },
            child: const Text('Logout'))
      ],
    );
  }
}
