// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:keeptrack/models/racks.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RacksAPI {
  final client = http.Client();
  Future<List<Rack>> getRacks(String? token) async {
    if (token == null) {
      return [];
    }
    await dotenv.load();

    var response = await client.get(
        Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/dcim/racks/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });
    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => Rack.fromJson(e))
          .toList();
    } else {
      print("Interface API Error: ${response.statusCode} ${response.body}");
      return [];
    }
  }

  Future<List<Rack>> getRacksByLocation(String? token, String location) async {
    if (token == null) {
      return [];
    }
    await dotenv.load();

    location = location.split(' ').first;

    var response = await client.get(
        Uri.parse(
            '${dotenv.env['NETBOX_API_URL']}/api/dcim/racks/?location=$location'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });
    var responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => Rack.fromJson(e))
          .toList();
    } else {
      print("Interface API Error: ${response.statusCode} ${response.body}");
      return [];
    }
  }
}
