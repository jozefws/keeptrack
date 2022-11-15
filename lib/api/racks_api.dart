import 'dart:convert';
import 'dart:io';
import 'package:keeptrack/models/racks.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RacksAPI {
  HttpOverrides.global = MyHttpOverrides();
  static Future<List<Rack>> getRacks(String token) async {
    await dotenv.load();
    var client = HttpClient();
    client.badCertificateCallback = (_, __, ___) => true;
    var request = await client.get(
        '${dotenv.env['NETBOX_HOST']}', 80, '/netbox/api/dcim/racks/');
    request.headers.set('Authorization', 'Token $token');
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200) {
      print(responseBody);
      return (jsonDecode(responseBody) as List)
          .map((e) => Rack.fromJson(e))
          .toList();
    } else {
      print('Failed to load racks');
      return [];
    }
  }
}
