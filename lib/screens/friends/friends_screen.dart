import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/friend_request_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _db = FirestoreService();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await _db.searchUsers(query.trim());
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.id ?? '';
    if (mounted) {
      setState(() {
        _searchResults = results.where((u) => u.uid != uid).toList();
        _isSearching = false;
      });
    }
  }

  Future<void> _sendRequest(UserModel targetUser) async {
    final auth = context.read<AuthService>();
    final me = auth.currentUserModel;
    if (me == null) return;

    try {
      await _db.sendFriendRequest(
        fromUid: me.uid,
        fromUsername: me.username,
        toUid: targetUser.uid,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Friend request sent to ${targetUser.username}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final uid = auth.currentUser?.id ?? '';

    return Scaffold(
      body: Column(
        children: [
          // Tab bar
          Container(
            color: const Color(0xFF5C6BC0),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'My Friends'),
                Tab(text: 'Requests'),
                Tab(text: 'Add Friends'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ── My Friends ──
                _FriendsList(uid: uid, db: _db),

                // ── Incoming Requests ──
                _RequestsList(uid: uid, db: _db),

                // ── Search & Add ──
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _searchUsers,
                        decoration: InputDecoration(
                          hintText: 'Search by username...',
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF5C6BC0)),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : null,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF3F51B5), width: 2),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (ctx, i) {
                          final user = _searchResults[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF5C6BC0),
                              child: Text(
                                user.username[0].toUpperCase(),
                                style:
                                    const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(user.username),
                            subtitle: Text(user.email),
                            trailing: ElevatedButton(
                              onPressed: () => _sendRequest(user),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3F51B5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                              child: const Text('Add'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  final String uid;
  final FirestoreService db;
  const _FriendsList({required this.uid, required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: db.friendsStream(uid),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final friends = snap.data ?? [];
        if (friends.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No friends yet',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 17)),
                Text('Search for people in the "Add" tab',
                    style: TextStyle(color: Colors.grey.shade400)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (ctx, i) {
            final f = friends[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF5C6BC0),
                child: Text(f.username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white)),
              ),
              title: Text(f.username,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(f.email),
              trailing: const Icon(Icons.check_circle,
                  color: Colors.green, size: 20),
            );
          },
        );
      },
    );
  }
}

class _RequestsList extends StatelessWidget {
  final String uid;
  final FirestoreService db;
  const _RequestsList({required this.uid, required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FriendRequest>>(
      stream: db.incomingRequestsStream(uid),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('No pending requestss',
                    style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 17)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (ctx, i) {
            final req = requests[i];
            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF5C6BC0),
                    child: Text(req.fromUsername[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(req.fromUsername,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('want to be your friend'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle,
                            color: Colors.green),
                        onPressed: () => db.respondToFriendRequest(
                          requestId: req.id,
                          fromUid:req.fromUid,
                          toUid: uid,
                          accept: true,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => db.respondToFriendRequest(
                          requestId: req.id,
                          fromUid: req.fromUid,
                          toUid: uid,
                          accept: false,
                        ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
