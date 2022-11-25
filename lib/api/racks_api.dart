import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:keeptrack/models/racks.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RacksAPI {
  static Future<List<Rack>> getRacks(String? token) async {
    if (token == null) {
      return [];
    }
    final client = http.Client();
    await dotenv.load();

    var response = await client.get(
        Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/dcim/racks/'),
        headers: {'Authorization': 'Token $token'});
    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      for (var i = 0; i < responseBody['results'].length; i++) {
        if (responseBody['results'][i]['device_count'] == 0) {
          responseBody['results'].removeAt(i);
        }
      }

      return (responseBody['results'] as List)
          .map((e) => Rack.fromJson(e))
          .toList();
    } else {
      return [];
    }
  }
}
