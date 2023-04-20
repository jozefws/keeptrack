import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tuple/tuple.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetboxAuthProvider extends ChangeNotifier {
  FlutterSecureStorage? secureStorage;
  final client = http.Client();

  // Initialize the secure storage
  initSecureStorage() async {
    secureStorage = const FlutterSecureStorage();
  }

  // Set the username in secure storage
  Future setUsername(String username) async {
    await initSecureStorage();
    await secureStorage!.write(key: 'nb:username', value: username);
  }

  // Set the token in secure storage
  Future setToken(String token) async {
    await initSecureStorage();
    await secureStorage!.write(key: 'nb:token', value: token);
  }

  // Set the token ID in secure storage
  Future setTokenID(int id) async {
    await initSecureStorage();
    await secureStorage!.write(key: 'nb:tokenid', value: id.toString());
  }

  // Set the token URL in secure storage
  Future setTokenURL(String tokenURL) async {
    await initSecureStorage();
    await secureStorage!.write(key: 'nb:tokenurl', value: tokenURL.toString());
  }

  // Get the username from secure storage
  Future<String?> getUsername() async {
    await initSecureStorage();
    return await secureStorage!.read(key: 'nb:username');
  }

  // Get the token URL from secure storage
  Future<String?> getTokenURL() async {
    await initSecureStorage();
    return await secureStorage!.read(key: 'nb:tokenurl');
  }

  // Get the token from secure storage
  Future<String?> getToken() async {
    await initSecureStorage();
    return await secureStorage!.read(key: 'nb:token');
  }

  // Get the token ID from secure storage
  Future<String?> getTokenID() async {
    await initSecureStorage();
    return await secureStorage!.read(key: 'nb:tokenid');
  }

  // Check if the token is valid
  Future<bool> isAuthenticated() async {
    await initSecureStorage();
    String? token = await getToken();
    String? tokenID = await getTokenID();

    if (token == null || tokenID == null) {
      return false;
    } else {
      return await checkToken(token, tokenID);
    }
  }

  // Login the user and set the token in secure storage if successful
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
      await setTokenID(res['id']);
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

  // Logout the user and delete the token from secure storage
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

  // Check if the token is valid by requesting the token from netbox
  Future<bool> checkToken(String token, String tokenID) async {
    final client = http.Client();
    final url =
        Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/users/tokens/$tokenID');

    var response = await client.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      return true;
    }

    return false;
  }

  // Check if the user is connected to the internet
  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    } else {
      return true;
    }
  }
}
