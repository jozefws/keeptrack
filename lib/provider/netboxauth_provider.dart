import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tuple/tuple.dart';

class NetboxAuthProvider extends ChangeNotifier {
  FlutterSecureStorage? secureStorage;
  final client = http.Client();

  initSecureStorage() async {
    secureStorage = const FlutterSecureStorage();
  }

  Future setUsername(String username) async {
    await initSecureStorage();
    await secureStorage!.write(key: 'nb:username', value: username);
  }

  Future setToken(String token) async {
    await initSecureStorage();
    await secureStorage!.write(key: 'nb:token', value: token);
  }

  Future setTokenURL(String tokenURL) async {
    await initSecureStorage();
    await secureStorage!.write(key: 'nb:tokenurl', value: tokenURL.toString());
  }

  Future<String?> getUsername() async {
    await initSecureStorage();
    return await secureStorage!.read(key: 'nb:username');
  }

  Future<String?> getTokenURL() async {
    await initSecureStorage();
    return await secureStorage!.read(key: 'nb:tokenurl');
  }

  Future<String?> getToken() async {
    await initSecureStorage();
    return await secureStorage!.read(key: 'nb:token');
  }

  Future<bool> isAuthenticated() async {
    await initSecureStorage();
    return await secureStorage!.read(key: 'nb:token') != null;
  }

  Future<dynamic> login(String username, String password) async {
    await dotenv.load();
    final expiry =
        DateTime.now().add(const Duration(days: 3)).toIso8601String();
    final response = await client.post(
      Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/users/tokens/provision/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'expiry': expiry,
      },
      body: '{"username": "$username", "password": "$password"}',
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> res = jsonDecode(response.body);
      await setToken(res['key']);
      await setTokenURL(res['url']);
      await setUsername(username);
      notifyListeners();
      return const Tuple2<bool, String>(true, "Login successful");
    } else {
      var message = "";

      if (response.statusCode == 400) {
        message = "Backend error, HTTP400";
      } else if (response.statusCode == 403) {
        message = "Incorrect username or password";
      } else if (response.statusCode == 404) {
        message = "User does not exist";
      } else {
        message = "Unknown error, HTTP${response.statusCode}";
      }

      notifyListeners();
      return Tuple2<bool, String>(false, message);
    }
  }

  Future<bool> logout() async {
    await initSecureStorage();
    if (await deleteToken()) {
      notifyListeners();
      await secureStorage!.delete(key: 'nb:token');
      await secureStorage!.delete(key: 'nb:username');
      await secureStorage!.delete(key: 'nb:tokenurl');
      return true;
    } else {
      await secureStorage!.delete(key: 'nb:token');
      await secureStorage!.delete(key: 'nb:username');
      await secureStorage!.delete(key: 'nb:tokenurl');
      notifyListeners();
      return false;
    }
  }

  //delete token from netbox
  Future<bool> deleteToken() async {
    final tokenURL = await getTokenURL();
    if (tokenURL == null) {
      return false;
    }
    final url = Uri.parse(tokenURL);
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Token $token',
    };
    final response = await client.delete(url, headers: headers);
    if (response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  }
}