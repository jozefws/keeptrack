// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/api/badcert_override.dart';
import 'package:keeptrack/views/addconnection.dart';
import 'package:keeptrack/views/devicesearch.dart';
import 'package:keeptrack/views/modifyconnection.dart';
import 'package:keeptrack/views/searchconnection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'provider/config_provider.dart';
import 'views/loginpage.dart';

void main() async {
  // Load environment variables from .env file in root directory.
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  // Forces status bar to be transparent
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  HttpOverrides.global = DevHttpOverrides();
  runApp(const KeepTrack());
}

//stateless widget
class KeepTrack extends StatelessWidget {
  const KeepTrack({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeLight = ThemeData(
      colorSchemeSeed: const Color(0xFF003739),
      brightness: Brightness.light,
      useMaterial3: true,
    );
    final themeDark = ThemeData(
      colorSchemeSeed: const Color(0xFF003739),
      brightness: Brightness.dark,
      useMaterial3: true,
    );

    return FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return MultiProvider(
                providers: [
                  ChangeNotifierProvider(
                      create: (_) => ThemeConfigProvider.initial(
                          (snapshot.data!.getBool('settings/dark-mode') ??
                                  false)
                              ? ThemeMode.dark
                              : ThemeMode.light)),
                  ChangeNotifierProvider(create: (_) => NetboxAuthProvider())
                ],
                child: Consumer<ThemeConfigProvider>(child:
                    Consumer<NetboxAuthProvider>(
                        builder: ((context, themeProvider, child) {
                  return KeepTrackHome(authProvider: themeProvider);
                })), builder: (c, themeProvider, child) {
                  return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      title: 'Keeptrack',
                      theme: themeLight,
                      darkTheme: themeDark,
                      themeMode: themeProvider.themeMode,
                      home: child);
                }));
          }
          return MaterialApp(
            title: 'Keeptrack',
            home: Builder(builder: (context) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 10),
                      Text("Loading...",
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              );
            }),
          );
        });
  }
}

class KeepTrackHome extends StatefulWidget {
  const KeepTrackHome({Key? key, required this.authProvider}) : super(key: key);
  final NetboxAuthProvider authProvider;

  @override
  State<KeepTrackHome> createState() => _KeepTrackHomeState();
}

class _KeepTrackHomeState extends State<KeepTrackHome> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late final SharedPreferences prefs;
  static int selectedIndex = 2;
  static String selectedTitle = "Welcome to KeepTrack";

  static List<Widget> navPages = <Widget>[
    const ModifyConnection(""),
    const AddConnection(null, null),
    const SearchConnection(),
    const DeviceSearch(),
  ];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
      if (index == 0) {
        selectedTitle = "Modify Connection";
      } else if (index == 1) {
        selectedTitle = "Add Connection";
      } else if (index == 2) {
        selectedTitle = "Search Connection";
      } else if (index == 3) {
        selectedTitle = "Device Information";
      }
    });
  }

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

  Future<String> getDomain() async {
    await dotenv.load();
    return dotenv.env['NETBOX_API_URL'] ?? '';
  }

  void getPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NetboxAuthProvider>(builder: (context, provider, child) {
      return FutureBuilder<bool>(
          future: provider.isConnected(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              var connectivityResult = Connectivity().checkConnectivity();

              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 10),
                      Text("Checking Connection State...",
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Text("Connectivity Result: $connectivityResult",
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              );
            } else {
              if (snapshot.data == false) {
                return const Scaffold(
                  body: Center(
                    child: Text("No internet connection"),
                  ),
                );
              }
              return FutureBuilder<bool>(
                  future: provider.isAuthenticated(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data!) {
                        return Scaffold(
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          key: scaffoldKey,
                          endDrawer: Drawer(
                            child: settingsDrawer(scaffoldKey),
                          ),
                          appBar: AppBar(
                              title: Text(selectedTitle),
                              //show burger icon that opens drawer
                              actions: <Widget>[
                                IconButton(
                                  icon: const Icon(Icons.settings),
                                  onPressed: () =>
                                      scaffoldKey.currentState?.openEndDrawer(),
                                )
                              ]),
                          body: SafeArea(
                            child: navPages.elementAt(selectedIndex),
                          ),
                          bottomNavigationBar: BottomNavigationBar(
                            backgroundColor:
                                Theme.of(context).colorScheme.onBackground,
                            selectedItemColor:
                                Theme.of(context).colorScheme.primary,
                            unselectedItemColor:
                                Theme.of(context).colorScheme.onBackground,
                            items: const [
                              BottomNavigationBarItem(
                                  icon: Icon(Icons.auto_fix_high),
                                  label: 'Modify'),
                              BottomNavigationBarItem(
                                  icon: Icon(Icons.add_link), label: 'Add'),
                              BottomNavigationBarItem(
                                  icon: Icon(Icons.cable_outlined),
                                  label: 'Search Connection'),
                              BottomNavigationBarItem(
                                  icon: Icon(
                                      Icons.screen_search_desktop_outlined),
                                  label: 'Devices'),
                            ],
                            currentIndex: selectedIndex,
                            onTap: onItemTapped,
                            //show label
                            showUnselectedLabels: true,
                          ),
                        );
                      } else {
                        return const LoginPage();
                      }
                    } else {
                      //if after 1 minute we still don't have a response, show error
                      while (
                          snapshot.connectionState == ConnectionState.waiting) {
                        return Scaffold(
                          body: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 10),
                                Text("Checking Netbox Authentication...",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ],
                            ),
                          ),
                        );
                      }
                      return const LoginPage();
                    }
                  });
            }
          });
    });
  }

  settingsDrawer(Key scaffoldKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
            trailing: Consumer<ThemeConfigProvider>(
                builder: (c, themeProvider, child) {
              return Switch(
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) => themeProvider.setSharedPreferencesTheme(
                      value ? ThemeMode.dark : ThemeMode.light));
            })),
        const Padding(
          padding: EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
        ),
        Column(
          children: [
            Text(
              "Currently logged into:",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        FutureBuilder<String>(
            future: getDomain(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data!);
              }
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  Text("Loading domain...",
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              );
            }),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              child: FloatingActionButton.extended(
                  onPressed: () async {
                    if (await Provider.of<NetboxAuthProvider>(context,
                            listen: false)
                        .logout()) {
                      ScaffoldMessenger(
                          key: scaffoldKey,
                          child: const SnackBar(
                              content: Text('Logout successful')));
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()));
                    } else {
                      ScaffoldMessenger(
                          key: scaffoldKey,
                          child: const SnackBar(
                              content: Text('Unable to delete token')));
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()));
                    }
                  },
                  label: const Text('Logout')),
            ),
          ),
        ),
      ],
    );
  }
}
