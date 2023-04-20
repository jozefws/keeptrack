import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/api/badcert_override.dart';
import 'package:keeptrack/views/root.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'provider/config_provider.dart';

void main() async {
  // Load environment variables from .env file in root directory.
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  // Forces status bar to be transparent
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // Enables http requests to be made to self-signed certificates
  HttpOverrides.global = DevHttpOverrides();
  runApp(const KeepTrack());
}

class KeepTrack extends StatelessWidget {
  const KeepTrack({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define the light and dark themes
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

    //Wrap the app in a MultiProvider to provide the theme and auth providers
    return FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return MultiProvider(
                providers: [
                  // If the user has previously selected a theme, use that. Otherwise, use the system default.
                  // Further listen to changes to the theme and update the theme accordingly.
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
                  // Return the main app as a child to the MultiProvider
                  return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      title: 'Keeptrack',
                      theme: themeLight,
                      darkTheme: themeDark,
                      themeMode: themeProvider.themeMode,
                      home: child);
                }));
          }

          // If the app is still loading, show a loading screen.
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
