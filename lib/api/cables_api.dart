import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:keeptrack/models/devices.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/cables.dart';

class CablesAPI {
  final client = http.Client();

  Future<Cable> getCableByID(String token, String cableID) async {
    await dotenv.load();
    var uri =
        Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/dcim/cables/$cableID');
    print(uri);
    var response = await client.get(uri, headers: {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
    print(response.body);
    var responseBody = jsonDecode(response.body);
    if (response.statusCode == 403) {
      print("Invalid token");
      throw Exception('Invalid token');
    }
    if (response.statusCode == 200) {
      return Cable.fromJson(responseBody);
    } else {
      print("API: Error");
      return Cable(
        id: -1,
        url: '',
        label: '',
        type: '',
        status: '',
      );
    }
  }

  Future<Cable?> getCableByLabel(String token, String cableLabel) async {
    await dotenv.load();
    var uri = Uri.parse(
        '${dotenv.env['NETBOX_API_URL']}/api/dcim/cables/?label=$cableLabel');
    print(uri);
    var response = await client.get(uri, headers: {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
    var responseBody = jsonDecode(response.body);
    if (response.statusCode == 403) {
      print("Invalid token");
      throw Exception('Invalid token');
    }
    if (response.statusCode == 200) {
      if (responseBody['count'] == 0) {
        print("API: Cable does not exit");
        return null;
      }
      return Cable.fromResultRootJson(responseBody);
    } else {
      print("API: Error. ${response.statusCode}, ${response.body}");
      return null;
    }
  }

  Future<bool> checkExistenceById(String token, String cableID) async {
    await dotenv.load();
    var uri = Uri.parse(
        '${dotenv.env['NETBOX_API_URL']}/api/dcim/cables/?label=$cableID');
    print(uri);
    var response = await client.get(uri, headers: {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 403) {
      throw Exception('Invalid token');
    }

    if (response.statusCode == 200) {
      if (responseBody['count'] == 0) {
        print("API: Cable does not exit");
        return false;
      } else {
        print("API: Cable Exists");

        return true;
      }
    } else {
      print("API: Error");
      return false;
    }
  }

  // add cable
  Future<bool> addConnection(String token, Cable cable) async {
    await dotenv.load();
    var uri = Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/dcim/cables/');
    var response = await client.post(
      uri,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'a_terminations': [
          {
            'object_type': 'dcim.interface',
            'object_id': cable.terminationAId,
          }
        ],
        'b_terminations': [
          {
            'object_type': 'dcim.interface',
            'object_id': cable.terminationBId,
          }
        ],
        'type': cable.type,
        'status': cable.status,
        'label': cable.label,
      }),
    );
    var responseBody = jsonDecode(response.body);
    if (response.statusCode == 403) {
      throw Exception('Invalid token');
    }
    if (response.statusCode == 201) {
      return true;
    } else {
      print("API: Error");
      print(response.statusCode);
      print(response.body);
      return false;
    }
  }

  //update cable
  Future<bool> updateConnection(String token, Cable cable) async {
    var body = jsonEncode({
      'a_terminations': [
        {
          'object_type': 'dcim.interface',
          'object_id': cable.terminationAId,
        }
      ],
      'b_terminations': [
        {
          'object_type': 'dcim.interface',
          'object_id': cable.terminationBId,
        }
      ],
      'type': cable.type,
      'status': "connected",
      'label': cable.label,
    });

    print(body);

    await dotenv.load();
    var uri = Uri.parse(
        '${dotenv.env['NETBOX_API_URL']}/api/dcim/cables/${cable.id}/');

    var response = await client.patch(
      uri,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: body,
    );
    try {
      var responseBody = jsonDecode(response.body);
    } catch (e) {
      print(e);
    }
    if (response.statusCode == 403) {
      throw Exception('Invalid token');
    }
    if (response.statusCode == 200) {
      return true;
    } else {
      print("API: Error");
      print(response.statusCode);
      print(response.body);
      return false;
    }
  }
}
