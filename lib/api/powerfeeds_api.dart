// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:keeptrack/models/powerfeed.dart';

class PowerFeedsAPI {
  final client = http.Client();

  Future<List<PowerFeed>> getPowerFeeds(String token) async {
    await dotenv.load();

    var response = await client.get(
        Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/dcim/power-feeds/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });
    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => PowerFeed.fromJson(e))
          .toList();
    } else {
      print(
          "PowerFeed getPowerFeed API: Error, response code: ${response.statusCode}");
      return [];
    }
  }

  Future<PowerFeed?> getPowerFeedByID(String token, String feedID) async {
    await dotenv.load();
    var response = await client.get(
        Uri.parse(
            '${dotenv.env['NETBOX_API_URL']}/api/dcim/power-feeds/$feedID'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      return (PowerFeed.fromJson(responseBody));
    } else {
      print(response.request);
      print(
          "PowerFeed getPowerFeedByID API: Error, response code: ${response.statusCode}");
      return null;
    }
  }
}
