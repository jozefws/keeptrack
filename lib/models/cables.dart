import 'package:flutter/material.dart';

class Cable {
  final int? id;
  final String label;
  final String? url;
  final String? terminationAId;
  final String? terminationBId;
  final String status;
  final String type;
  final String? color;

  Cable({
    this.id,
    required this.label,
    this.url,
    this.terminationAId,
    this.terminationBId,
    required this.status,
    required this.type,
    this.color,
  });

  factory Cable.fromJson(Map<String, dynamic> json) {
    return Cable(
      id: json['id'],
      label: json['label'],
      url: json['url'],
      terminationAId: json['termination_a']['id'],
      terminationBId: json['termination_b']['id'],
      status: json['status']['label'],
      type: json['type']['label'],
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
