import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:keeptrack/models/locations.dart';

class OrganisationAPI {
  final client = http.Client();

  Future<List<Location>> getLocations(String token) async {
    await dotenv.load();

    var response = await client.get(
        Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/dcim/locations/'),
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
          .map((e) => Location.fromJson(e))
          .toList();
    } else {
      return [];
    }
  }
}
