import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:keeptrack/models/cables.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:keeptrack/models/powerport.dart';

class PowerPortsAPI {
  final client = http.Client();

  Future<List<PowerPort>> getPowerPorts(String token) async {
    await dotenv.load();

    var response = await client.get(
        Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/dcim/power-ports/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });
    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => PowerPort.fromJson(e))
          .toList();
    } else {
      print(
          "Powerport getPowerPorts API: Error, response code: ${response.statusCode}");
      return [];
    }
  }

  Future<List<PowerPort>> getPowerPortsByDevice(
      String token, String deviceID) async {
    await dotenv.load();
    // try {
    var response = await client.get(
        Uri.parse(
            '${dotenv.env['NETBOX_API_URL']}/api/dcim/power-ports/?device_id=$deviceID'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });
    var responseBody = jsonDecode(response.body);
    if (response.statusCode == 403) {
      throw Exception('Invalid token');
    }
    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => PowerPort.fromJson(e))
          .toList();
    } else {
      print(
          "Powerport getPowerPortsByDevice API: Error, response code: ${response.statusCode}");
      return [];
    }
  }

  Future<PowerPort?> getPowerPortByID(String token, String outletID) async {
    await dotenv.load();
    var response = await client.get(
        Uri.parse(
            '${dotenv.env['NETBOX_API_URL']}/api/dcim/power-ports/$outletID'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      return (PowerPort.fromJson(responseBody));
    } else {
      print("API: Error, response code: ${response.statusCode}");
      return null;
    }
  }
}
