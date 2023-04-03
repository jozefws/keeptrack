// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:keeptrack/models/poweroutlet.dart';

class PowerOutletsAPI {
  final client = http.Client();

  Future<List<PowerOutlet>> getPowerOutlets(String token) async {
    await dotenv.load();

    var response = await client.get(
        Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/dcim/power-outlets/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });
    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => PowerOutlet.fromJson(e))
          .toList();
    } else {
      print(
          "Poweroutlet getPowerOutlets API: Error, response code: ${response.statusCode}");

      return [];
    }
  }

  Future<List<PowerOutlet>> getPowerOutletsByDevice(
      String token, String deviceID) async {
    await dotenv.load();
    // try {
    var response = await client.get(
        Uri.parse(
            '${dotenv.env['NETBOX_API_URL']}/api/dcim/power-outlets/?device_id=$deviceID'),
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
          .map((e) => PowerOutlet.fromJson(e))
          .toList();
    } else {
      print(
          "Poweroutlet getPowerOutletByDevice API: Error, response code: ${response.statusCode}");
      return [];
    }
  }

  Future<PowerOutlet?> getPowerOutletByID(String token, String outletID) async {
    await dotenv.load();
    var response = await client.get(
        Uri.parse(
            '${dotenv.env['NETBOX_API_URL']}/api/dcim/power-outlets/$outletID'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      return (PowerOutlet.fromJson(responseBody));
    } else {
      print(
          "Poweroutlet getPowerOutletsByID API: Error, response code: ${response.statusCode}");
      return null;
    }
  }
}
