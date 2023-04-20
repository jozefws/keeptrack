// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:keeptrack/models/devices.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DevicesAPI {
  final client = http.Client();
  Future<List<Device>> getDevices(String token) async {
    await dotenv.load();

    var response = await client.get(
        Uri.parse(
            '${dotenv.env['NETBOX_API_URL']}/api/dcim/devices/?limit=250'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });
    var responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => Device.fromJson(e))
          .toList();
    } else {
      print("Get Devices API: Error ${response.statusCode}");
      return [];
    }
  }

  Future<Device?> getDeviceByID(String token, String ID) async {
    await dotenv.load();

    var response = await client.get(
        Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/dcim/devices/$ID'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });
    var responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (Device.fromJson(responseBody));
    } else {
      print("API: Error, response code: ${response.statusCode}");
      return null;
    }
  }

  Future<List<Device>> getDevicesByRack(String token, String rackID) async {
    await dotenv.load();
    var uri = Uri.parse(
        '${dotenv.env['NETBOX_API_URL']}/api/dcim/devices/?rack_id=$rackID');
    var response = await client.get(uri, headers: {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => Device.fromJson(e))
          .toList();
    } else {
      print("Get Devices API: Error ${response.statusCode}");
      return [];
    }
  }
}
