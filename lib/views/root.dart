import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/views/addconnection.dart';
import 'package:keeptrack/views/devicesearch.dart';
import 'package:keeptrack/views/modifyconnection.dart';
import 'package:keeptrack/views/searchconnection.dart';
import 'package:keeptrack/views/loginpage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:keeptrack/provider/config_provider.dart';

class KeepTrackHome extends StatefulWidget {
  const KeepTrackHome({Key? key, required this.authProvider}) : super(key: key);
  final NetboxAuthProvider authProvider;

  @override
  State<KeepTrackHome> createState() => _KeepTrackHomeState();
}

class _KeepTrackHomeState extends State<KeepTrackHome> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late final SharedPreferences prefs;

  // Define the initial page to be displayed
  static int selectedIndex = 2;

  // Define the title of the page to be displayed
  static String selectedTitle = "Welcome to KeepTrack";

  // Define the pages to be displayed in the bottom navigation bar
  static List<Widget> navPages = <Widget>[
    const ModifyConnection(""),
    const AddConnection(null, null),
    const SearchConnection(),
    const DeviceSearch(),
  ];

  // Define the top bar title to be displayed
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

  // get the username from the auth provider
  Future<String> getUsername() async {
    final provider = Provider.of<NetboxAuthProvider>(context, listen: false);
    return (await provider.getUsername() ?? "loading username...");
  }

  // get the domain from the .env file
  Future<String> getDomain() async {
    await dotenv.load();
    return dotenv.env['NETBOX_API_URL'] ?? '';
  }

  // get the shared preferences
  void getPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NetboxAuthProvider>(builder: (context, provider, child) {
      return FutureBuilder<bool>(
          // check if the user is connected to the internet
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
              // if the user is connected to the internet, check if they are authenticated
              return FutureBuilder<bool>(
                  future: provider.isAuthenticated(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data!) {
                        return Scaffold(
                          backgroundColor:
                              Theme.of(context).colorScheme.background,
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

                          // Define the bottom navigation bar
                          bottomNavigationBar: BottomNavigationBar(
                            type: BottomNavigationBarType.shifting,
                            selectedItemColor:
                                Theme.of(context).colorScheme.primary,
                            unselectedItemColor:
                                Theme.of(context).colorScheme.onBackground,
                            items: [
                              BottomNavigationBarItem(
                                  icon: const Icon(Icons.auto_fix_high),
                                  label: 'Modify',
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer),
                              BottomNavigationBarItem(
                                  icon: const Icon(Icons.add_link),
                                  label: 'Add',
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer),
                              BottomNavigationBarItem(
                                  icon: const Icon(Icons.cable_outlined),
                                  label: 'Search Connection',
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer),
                              BottomNavigationBarItem(
                                  icon: const Icon(
                                      Icons.screen_search_desktop_outlined),
                                  label: 'Devices',
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer),
                            ],
                            currentIndex: selectedIndex,
                            onTap: onItemTapped,
                            //show label
                            showUnselectedLabels: true,
                          ),
                        );
                        //if not authenticated, show login page
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
                      //if we still don't have a response, show error
                      return const LoginPage();
                    }
                  });
            }
          });
    });
  }

  // settings drawer widget
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
        // color mode switch
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
                      navToLogin();
                    } else {
                      ScaffoldMessenger(
                          key: scaffoldKey,
                          child: const SnackBar(
                              content: Text('Unable to delete token')));
                      navToLogin();
                    }
                  },
                  label: const Text('Logout')),
            ),
          ),
        ),
      ],
    );
  }

  // On logout navigate to login page
  Future<dynamic> navToLogin() {
    return Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }
}
