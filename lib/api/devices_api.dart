import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:keeptrack/models/devices.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DevicesAPI {
  static Future<List<Device>> getDevices(String token) async {
    final client = http.Client();
    await dotenv.load();

    var response = await client.get(
        Uri.parse(
            '${dotenv.env['NETBOX_API_URL']}/api/dcim/devices/?limit=250'),
        headers: {'Authorization': 'Token $token'});
    var responseBody = jsonDecode(response.body);
    var list = responseBody['results'] as List;
    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => Device.fromJson(e))
          .toList();
    } else {
      return [];
    }
  }

  static Future<List<Device>> getDevicesByRack(
      String token, String rackID) async {
    var client = http.Client();
    await dotenv.load();
    var uri = Uri.parse(
        '${dotenv.env['NETBOX_API_URL']}/api/dcim/devices/?rack_id=$rackID');
    var response =
        await client.get(uri, headers: {'Authorization': 'Token $token'});
    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => Device.fromJson(e))
          .toList();
    } else {
      return [];
    }
  }
}
