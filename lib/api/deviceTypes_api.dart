import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:keeptrack/models/device_types.dart';
import 'package:keeptrack/models/devices.dart';
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
    var list = responseBody['results'] as List;
    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => DeviceType.fromJson(e))
          .toList();
    } else {
      return [];
    }
  }

  Future<DeviceType> getDeviceTypeById(String token, String ID) async {
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
      return DeviceType(id: -1, name: 'Error', url: 'error');
    }
  }
}
