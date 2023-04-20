// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/cables.dart';

class CablesAPI {
  final client = http.Client();

  Future<Cable?> getCableByID(String token, String cableID) async {
    await dotenv.load();
    var uri =
        Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/dcim/cables/$cableID');
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
      return Cable.fromJson(responseBody);
    } else {
      print(response.request);
      print("Get Cable By ID API: Error ${response.statusCode}");
      return null;
    }
  }

  Future<Cable?> getCableByLabel(String token, String cableLabel) async {
    await dotenv.load();
    var uri = Uri.parse(
        '${dotenv.env['NETBOX_API_URL']}/api/dcim/cables/?label=$cableLabel');
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
      print(
          "GET Cable by Label API : Error. ${response.statusCode}, ${response.body}");
      return null;
    }
  }

  Future<bool> checkExistenceByLabel(String token, String cableID) async {
    await dotenv.load();
    var uri = Uri.parse(
        '${dotenv.env['NETBOX_API_URL']}/api/dcim/cables/?label=$cableID');
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
      print("Check Cable Existence by ID API: Error");
      return false;
    }
  }

  // add cable
  Future<String?> addConnection(String token, Cable cable) async {
    await dotenv.load();
    var uri = Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/dcim/cables/');

    String? terminationAType = checkTerminationType(cable.terminationAType);
    String? terminationBType = checkTerminationType(cable.terminationBType);

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
            'object_type': '$terminationAType',
            'object_id': cable.terminationAId,
          }
        ],
        'b_terminations': [
          {
            'object_type': '$terminationBType',
            'object_id': cable.terminationBId,
          }
        ],
        'type': cable.type,
        'status': cable.status,
        'label': cable.label,
        'description': cable.description,
        'color': cable.color ?? "111111",
      }),
    );
    if (response.statusCode == 403) {
      return null;
    }
    if (response.statusCode == 201) {
      var responseBody = jsonDecode(response.body);
      return responseBody['id'].toString();
    } else {
      print(
          "Add Cable API: Error ${response.statusCode}, ${response.body}, ${response.request}");
      return null;
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
      jsonDecode(response.body);
    } catch (e) {
      print("Update connection API: Error $e");
      return false;
    }
    if (response.statusCode == 403) {
      throw Exception('Invalid token');
    }
    if (response.statusCode == 200) {
      return true;
    } else {
      print("Update Cable API: Error ${response.statusCode}, ${response.body}");
      return false;
    }
  }

  // update cable via delete and create new one due to bug in netbox, issue #
  Future<String> updateConnectionBAD(String token, Cable cable) async {
    if (await deleteConnection(token, cable)) {
      String? newLabel = await addConnection(token, cable);
      if (newLabel != null) {
        return newLabel;
      } else {
        return "false";
      }
    } else {
      return "false";
    }
  }

  Future<bool> deleteConnection(String token, Cable cable) async {
    await dotenv.load();
    var uri = Uri.parse(
        '${dotenv.env['NETBOX_API_URL']}/api/dcim/cables/${cable.id}/');
    var response = await client.delete(
      uri,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 403) {
      throw Exception('Invalid token');
    }
    if (response.statusCode == 204) {
      return true;
    } else {
      print("Delete Cable API: Error ${response.statusCode}, ${response.body}");
      return false;
    }
  }

  String? checkTerminationType(String? terminationType) {
    // does it contain dcim. at the start
    if (terminationType!.contains("dcim.")) {
      // does it container only one dcim.
      if (terminationType.contains("dcim.dcim.")) {
        return terminationType.replaceAll("dcim.dcim.", "dcim.");
      }
      return terminationType;
    } else {
      return "dcim.$terminationType";
    }
  }
}
