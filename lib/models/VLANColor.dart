import 'package:flutter/material.dart';

class ConnectionColour {
  final String description;
  final String hexColor;
  final Color color;

  ConnectionColour({
    required this.description,
    required this.hexColor,
    required this.color,
  });
}

// data class for 3 VLANs, 21, 22, 23 where 21 is red, 22 is green, 23 is blue

List<ConnectionColour> CONNECTION_COLOURS = [
  ConnectionColour(
      description: "VLAN 20",
      hexColor: "F44336",
      color: const Color(0XffF44336)),
  ConnectionColour(
      description: "VAN 21",
      hexColor: "2196F3",
      color: const Color(0Xff2196F3)),
  ConnectionColour(
      description: "VLAN 23",
      hexColor: "4CAF50",
      color: const Color(0Xff4CAF50)),
  ConnectionColour(
      description: "TRUNK", hexColor: "9E9E9E", color: Colors.grey),
  ConnectionColour(
      description: "Local", hexColor: "000000", color: Colors.black),
  ConnectionColour(
      description: "Power", hexColor: "000000", color: Colors.black),
  ConnectionColour(
      description: "Power(backup)",
      hexColor: "03A9F4",
      color: const Color(0xFF03A9F4)),
];
