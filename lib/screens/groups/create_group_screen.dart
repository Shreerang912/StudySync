import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _db = FirestoreService();
  bool _isLoading = false;
  List<UserModel> _friends = [];
  final Set<String> _selectedFriends = {};

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.id ?? '';
    _db.friendsStream(uid).listen((friends) {
      if (mounted) setState(() => _friends = friends);
    });
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.id ?? '';

    try {
      await _db.createGroup(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        adminUid: uid,
        memberUids: _selectedFriends.toList(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createGroup,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Create',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group icon placeholder
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(253, 59, 118, 228).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group,
                    size: 40, color: Color.fromARGB(253, 59, 118, 228)),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g. Physics Study Group',
                prefixIcon:
                    const Icon(Icons.group, color: Color.fromARGB(253, 59, 118, 228)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF3F51B5), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon:
                    const Icon(Icons.description, color: Color.fromARGB(253, 59, 118, 228)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF3F51B5), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                const Text(
                  'Add Friends',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(253, 59, 118, 228),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedFriends.length}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_friends.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No friends yet. Add friends first!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _friends.length,
                itemBuilder: (context, i) {
                  final friend = _friends[i];
                  final selected = _selectedFriends.contains(friend.uid);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedFriends.add(friend.uid);
                        } else {
                          _selectedFriends.remove(friend.uid);
                        }
                      });
                    },
                    title: Text(friend.username),
                    subtitle: Text(friend.email),
                    secondary: CircleAvatar(
                      backgroundColor: const Color.fromARGB(253, 59, 118, 228),
                      child: Text(
                        friend.username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    activeColor: const Color(0xFF3F51B5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}