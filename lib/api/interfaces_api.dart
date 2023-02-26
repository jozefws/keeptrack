import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:keeptrack/models/cables.dart';
import 'package:keeptrack/models/interfaces.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class InterfacesAPI {
  final client = http.Client();

  final List typeRJ45 = [
    "100base-tx",
    "1000base-t",
    "2.5gbase-t",
    "5gbase-t",
    "10gbase-t",
    "10gbase-cx4"
  ];
  final List typeSFP = [
    "1000base-x-gbic",
    "1000base-x-sfp",
    "10gbase-x-sfpp",
    "10gbase-x-xfp",
    "10gbase-x-xenpak",
    "10gbase-x-x2",
    "25gbase-x-sfp28",
    "50gbase-x-sfp56",
    "40gbase-x-qsfpp",
    "50gbase-x-sfp28",
    "100gbase-x-cfp",
    "100gbase-x-cfp2",
    "200gbase-x-cfp2",
    "100gbase-x-cfp4",
    "100gbase-x-cpak",
    "100gbase-x-qsfp28",
    "200gbase-x-qsfp56",
    "400gbase-x-qsfpdd",
    "400gbase-x-osfp"
  ];

  Future<List<Interface>> getInterfaces(String token) async {
    await dotenv.load();

    var response = await client.get(
        Uri.parse('${dotenv.env['NETBOX_API_URL']}/api/dcim/interfaces/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });
    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => Interface.fromJson(e))
          .toList();
    } else {
      return [];
    }
  }

  Future<List<Interface>> getInterfacesByDevice(
      String token, String deviceID) async {
    await dotenv.load();
    var response = await client.get(
        Uri.parse(
            '${dotenv.env['NETBOX_API_URL']}/api/dcim/interfaces/?device_id=$deviceID'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        });
    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (responseBody['results'] as List)
          .map((e) => Interface.fromJson(e))
          .toList();
    } else {
      return [];
    }
  }

  Future<List<DropdownMenuItem<String>>> getCableTypeByInterfaceID(
      String token, String interfaceID) async {
    await dotenv.load();
    var response = await client.get(
        Uri.parse(
            '${dotenv.env['NETBOX_API_URL']}/api/dcim/interfaces/$interfaceID/'),
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
      String type = responseBody['type']['value'];
      // if type is in typeRJ45, return RJ45, if type is in typeSFP, return SFP, else return null
      for (var i in typeRJ45) {
        if (type == i) {
          return CableType.networkRJ45;
        }
      }
    } else {
      return [];
    }
    return [];
  }
}
