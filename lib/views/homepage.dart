import 'package:flutter/material.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/views/loginpage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  final NetboxAuthProvider authProvider;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final SharedPreferences prefs;
  bool _isDark = false;
  @override
  void initState() {
    super.initState();
    getPrefs();
  }

  void getPrefs() async {
    prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('settings/dark-mode') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KeepTrack'),
      ),
      body: Center(
        child: Column(
          children: [
            const Text('Welcome to KeepTrack, ${prefs.getString('username')}'),
            ElevatedButton(
                onPressed: () async {
                  if (await Provider.of<NetboxAuthProvider>(context,
                          listen: false)
                      .logout()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logout successful')));
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Unable to delete netbox token')));
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()));
                  }
                },
                child: const Text('Logout'))
          ],
        ),
      ),
    );
  }
}
