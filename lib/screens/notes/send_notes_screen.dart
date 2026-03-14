import 'package:flutter/material.dart';
import '../../models/group_model.dart';

class SendNotesScreen extends StatelessWidget {
  final GroupModel group;
  final String currentUid;
  final String senderName;
  final String? prefillSubject;
  final String? prefillTopic;

  const SendNotesScreen({
    super.key,
    required this.group,
    required this.currentUid,
    required this.senderName,
    this.prefillSubject,
    this.prefillTopic,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Notes')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}