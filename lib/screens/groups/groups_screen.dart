import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'create_group_screen.dart';
import '../chat/chat_screen.dart';
import 'package:intl/intl.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final uid = auth.currentUser?.id ?? '';
    final db = FirestoreService();

    return Scaffold(
      body: StreamBuilder<List<GroupModel>>(
        stream: db.userGroupsStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_add, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No groups yet',
                    style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a group to start sharing notes!',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final group = groups[i];
              return _GroupTile(group: group, currentUid: uid);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
        ),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final GroupModel group;
  final String currentUid;

  const _GroupTile({required this.group, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final lastTime = group.lastMessageTime;
    final timeStr = lastTime != null
    ? DateFormat('h:mm a').format(lastTime)
    : '';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFF5C6BC0),
        child: Text(
          group.name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        group.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        group.lastMessage ?? group.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey.shade600),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
         Text(timeStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${group.memberUids.length} members',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(group: group, currentUid: currentUid),
        ),
      ),
    );
  }
}