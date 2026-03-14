import 'package:flutter/material.dart';
import '../../models/group_model.dart';

class RequestNotesScreen extends StatelessWidget {
  final GroupModel group;
  final String currentUid;
  final String senderName;

  const RequestNotesScreen({
    super.key,
    required this.group,
    required this.currentUid,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Notes')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}