import 'package:flutter/material.dart';

class Cable {
  final int? id;
  String label;
  final String? url;
  String? terminationAId;
  String? terminationAName;
  String? terminationADeviceID;
  String? terminationADeviceName;
  String? terminationBId;
  String? terminationBName;
  String? terminationBDeviceID;
  String? terminationBDeviceName;
  String? status;
  String? type;
  String? color;

  Cable({
    this.id,
    required this.label,
    this.url,
    this.terminationAId,
    this.terminationAName,
    this.terminationADeviceID,
    this.terminationADeviceName,
    this.terminationBId,
    this.terminationBName,
    this.terminationBDeviceID,
    this.terminationBDeviceName,
    required this.status,
    required this.type,
    this.color,
  });

  factory Cable.fromJson(Map<String, dynamic> json) {
    return Cable(
      id: json['id'],
      label: json['label'],
      url: json['url'],
      terminationAId: json['a_terminations'][0]['object_id'].toString(),
      terminationAName: json['a_terminations'][0]['object']['name'],
      terminationADeviceID:
          json['a_terminations'][0]['object']['device']['id'].toString(),
      terminationADeviceName: json['a_terminations'][0]['object']['device']
          ['name'],
      terminationBId: json['b_terminations'][0]['object_id'].toString(),
      terminationBDeviceID:
          json['b_terminations'][0]['object']['device']['id'].toString(),
      terminationBDeviceName: json['b_terminations'][0]['object']['device']
          ['name'],
      status: json['status'][0],
      type: json['type'],
      color: json['color'],
    );
  }
}

class CableType {
  static final List<DropdownMenuItem<String>> networkRJ45 = [
    const DropdownMenuItem(
      value: 'cat5',
      child: Text('Cat 5'),
    ),
    const DropdownMenuItem(
      value: 'cat5e',
      child: Text('Cat 5e'),
    ),
    const DropdownMenuItem(
      value: 'cat6',
      child: Text('Cat 6'),
    ),
    const DropdownMenuItem(
      value: 'cat6a',
      child: Text('Cat 6a'),
    ),
    const DropdownMenuItem(
      value: 'cat7',
      child: Text('Cat 7'),
    ),
    const DropdownMenuItem(
      value: 'power',
      child: Text('power'),
    ),
  ];
  static final List power = ["power"];
}
