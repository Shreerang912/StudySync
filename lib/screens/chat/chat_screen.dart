import 'package:flutter/material.dart';
import '../../models/group_model.dart';

class ChatScreen extends StatelessWidget {
  final GroupModel group;
  final String currentUid;

  const ChatScreen({
    super.key,
    required this.group,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: const Center(child: Text('Chat coming soon')),
    );
  }
}