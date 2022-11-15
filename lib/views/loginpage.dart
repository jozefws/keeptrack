import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keeptrack/provider/netboxauth_provider.dart';
import 'package:keeptrack/views/homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginForm = GlobalKey<FormState>();
  final textUsername = TextEditingController();
  final textPassword = TextEditingController();

  @override
  void dispose() {
    textPassword.dispose();
    textUsername.dispose();
    super.dispose();
  }

  void moveToHome() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage(
                  authProvider: NetboxAuthProvider(),
                )));
  }

  void showLoginError(message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Unable to login, $message')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: SingleChildScrollView(
      child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Image(
                image: AssetImage('assets/netbox_logo.png'),
                height: 200,
              ),
              const Text(
                "Login to Netbox",
                style: TextStyle(fontSize: 30),
              ),
              const SizedBox(height: 60),
              Form(
                key: _loginForm,
                child: Column(
                  children: [
                    TextFormField(
                      controller: textUsername,
                      validator: ((value) =>
                          value!.isEmpty ? 'Please enter a username' : null),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Netbox Username, e.g. psajs4',
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: textPassword,
                      obscureText: true,
                      validator: ((value) =>
                          value!.isEmpty ? 'Please enter a password' : null),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Netbox Password',
                      ),
                    ),
                    const SizedBox(height: 100),
                    ElevatedButton(
                      onPressed: () async {
                        if (_loginForm.currentState!.validate()) {
                          final provider = Provider.of<NetboxAuthProvider>(
                              context,
                              listen: false);
                          final result = await provider.login(
                              textUsername.text, textPassword.text);
                          if (result.item1) {
                            moveToHome();
                          } else {
                            showLoginError(result.item2);
                          }
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                            Theme.of(context).buttonTheme.colorScheme!.primary),
                        minimumSize:
                            MaterialStateProperty.all(const Size(200, 50)),
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    )));
  }
}
