import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/api/badcert_override.dart';
import 'package:keeptrack/views/homepage.dart';
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
      colorSchemeSeed: const Color(0xFF133769),
      brightness: Brightness.light,
      useMaterial3: true,
    );
    final themeDark = ThemeData(
      colorSchemeSeed: const Color(0xFF133769),
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
                        builder: ((context, provider, child) {
                  return KeepTrackHome(authProvider: provider);
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
            theme: themeDark,
            title: 'Keeptrack',
            home: Builder(builder: (context) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
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
  @override
  Widget build(BuildContext context) {
    return Consumer<NetboxAuthProvider>(builder: (context, provider, child) {
      return FutureBuilder<bool>(
          future: provider.isAuthenticated(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (snapshot.data!) {
                return HomePage(
                  authProvider: provider,
                );
              } else {
                return const LoginPage();
              }
            }
            return const Center(child: CircularProgressIndicator());
          });
    });
  }
}
