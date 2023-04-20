// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:keeptrack/models/device_types.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DeviceTypesAPI {
  final client = http.Client();
  Future<List<DeviceType>> getDeviceTypes(String token) async {
    await dotenv.load();

    var response = await client.get(
        Uri.parse(
            '${dotenv.env['NETBOX_API_URL']}/api/dcim/device=types/?limit=250'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });
    var responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => DeviceType.fromJson(e))
          .toList();
    } else {
      print("Get Device Types API: Error ${response.statusCode}");
      return [];
    }
  }

  Future<DeviceType?> getDeviceTypeById(String token, String ID) async {
    await dotenv.load();

    var response = await client.get(
        Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/dcim/device-types/$ID'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });
    var responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return DeviceType.fromJson(responseBody);
    } else {
      print("Get Device Type API: Error ${response.statusCode}");
      return null;
    }
  }
}
