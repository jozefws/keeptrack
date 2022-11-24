import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:keeptrack/models/interfaces.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class InterfacesAPI {
  static Future<List<Interface>> getInterfaces(String token) async {
    final client = http.Client();
    await dotenv.load();

    var response = await client.get(
        Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/dcim/interfaces/'),
        headers: {'Authorization': 'Token $token'});
    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => Interface.fromJson(e))
          .toList();
    } else {
      print('Failed to load racks');
      return [];
    }
  }

  static Future<List<Interface>> getInterfacesByDevice(
      String token, int deviceID) async {
    final client = http.Client();
    await dotenv.load();

    var response = await client.get(
        Uri.parse(
            '${dotenv.env['NETBOX_API_URL']}/api/dcim/interfaces/?device_id=$deviceID'),
        headers: {'Authorization': 'Token $token'});
    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => Interface.fromJson(e))
          .toList();
    } else {
      print('Failed to load racks');
      return [];
    }
  }
}
