import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'dart:async';
import '../models/message_model.dart';
import '../models/note_model.dart';
import '../models/group_model.dart';
import '../models/friend_request_model.dart';

final _sb = Supabase.instance.client;

class FirestoreService {



  Future<UserModel?> getUserById(String uid) async {
    final data = await _sb.from('users').select().eq('id', uid).maybeSingle();
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final data = await _sb
        .from('users')
        .select()
        .ilike('username', '$query%')
        .limit(20);
    return (data as List).map((d) => UserModel.fromMap(d)).toList();
  }

 

  Future<void> sendFriendRequest({
    required String fromUid,
    required String fromUsername,
    required String toUid,
  }) async {
    await _sb.from('friend_requests').insert({
      'from_uid': fromUid,
      'from_username': fromUsername,
      'to_uid': toUid,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<FriendRequest>> incomingRequestsStream(String uid) {
    return _sb
        .from('friend_requests')
        .stream(primaryKey: ['id'])
        .eq('to_uid', uid)
        .map((rows) => rows
            .where((r) => r['status'] == 'pending')
            .map((r) => FriendRequest.fromMap(r))
            .toList());
  }

  Future<void> respondToFriendRequest({
    required String requestId,
    required String fromUid,
    required String toUid,
    required bool accept,
  }) async {
    await _sb
        .from('friend_requests')
        .update({'status': accept ? 'accepted' : 'rejected'})
        .eq('id', requestId);

    if (accept) {
      await _sb.from('friends').insert([
        {'user_id': fromUid, 'friend_id': toUid},
        {'user_id': toUid, 'friend_id': fromUid},
      ]);
    }
  }

  Stream<List<UserModel>> friendsStream(String uid) {
    return _sb
        .from('friends')
        .stream(primaryKey: ['user_id', 'friend_id'])
        .eq('user_id', uid)
        .asyncMap((rows) async {
          final ids = rows.map((r) => r['friend_id'] as String).toList();
          if (ids.isEmpty) return <UserModel>[];
          final users = await _sb
              .from('users')
              .select()
              .inFilter('id', ids);
          return (users as List).map((u) => UserModel.fromMap(u)).toList();
        });
  }


  Future<String> createGroup({
    required String name,
    required String description,
    required String adminUid,
    required List<String> memberUids,
  }) async {
    final allMembers = {...memberUids, adminUid}.toList();

    final result = await _sb.from('groups').insert({
      'name': name,
      'description': description,
      'admin_uid': adminUid,
      'member_uids': allMembers,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    return result['id'] as String;
  }

  Stream<List<GroupModel>> userGroupsStream(String uid) {
    return _sb
        .from('groups')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows
            .where((r) {
              final members = List<String>.from(r['member_uids'] ?? []);
              return members.contains(uid);
            })
            .map((r) => GroupModel.fromMap(r))
            .toList());
  }


  Future<String> sendMessage({
    required String groupId,
    required String senderId,
    required String senderName,
    required String text,
    MessageType type = MessageType.text,
    String? noteId,
    String? subject,
    String? topic,
  }) async {
    final result = await _sb.from('messages').insert({
      'group_id': groupId,
      'sender_id': senderId,
      'sender_name': senderName,
      'text': text,
      'type': type.name,
      'note_id': noteId,
      'subject': subject,
      'topic': topic,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    await _sb.from('groups').update({
      'last_message': text,
      'last_message_time': DateTime.now().toIso8601String(),
    }).eq('id', groupId);
    return result['id'] as String;
  }

Stream<List<MessageModel>> messagesStream(String groupId) {
  final controller = StreamController<List<MessageModel>>();
  List<MessageModel> _current = [];

  // Initial fetch
  _sb
      .from('messages')
      .select()
      .eq('group_id', groupId)
      .order('created_at', ascending: true)
      .then((data) {
    _current = (data as List).map((r) => MessageModel.fromMap(r)).toList();
    controller.add(_current);
  });

  // Listen for all changes
  final channel = _sb
      .channel('messages:$groupId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'group_id',
          value: groupId,
        ),
        callback: (payload) async {
          // Re-fetch everything on any change
          final data = await _sb
              .from('messages')
              .select()
              .eq('group_id', groupId)
              .order('created_at', ascending: true);
          _current =
              (data as List).map((r) => MessageModel.fromMap(r)).toList();
          controller.add(_current);
        },
      )
      .subscribe();

  controller.onCancel = () {
    _sb.removeChannel(channel);
    controller.close();
  };

  return controller.stream;
}


  Future<String> saveNote({
    required String senderId,
    required String senderName,
    required String groupId,
    required String subject,
    required String topic,
    required List<String> imageUrls,
    String? description,
  }) async {
    final result = await _sb.from('notes').insert({
      'sender_id': senderId,
      'sender_name': senderName,
      'group_id': groupId,
      'subject': subject,
      'topic': topic,
      'image_urls': imageUrls,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    return result['id'] as String;
  }

  Future<List<NoteModel>> fetchNotes({
    required List<String> groupIds,
    String? subject,
    String? topic,
  }) async {
    if (groupIds.isEmpty) return [];

    var query = _sb
        .from('notes')
        .select()
        .inFilter('group_id', groupIds)
        .order('created_at', ascending: false);

    final data = await query;
    var notes = (data as List).map((d) => NoteModel.fromMap(d)).toList();

    if (subject != null && subject.isNotEmpty) {
      notes = notes.where((n) => n.subject == subject).toList();
    }
    if (topic != null && topic.isNotEmpty) {
      notes = notes
          .where((n) =>
              n.topic.toLowerCase().contains(topic.toLowerCase()))
          .toList();
    }

    return notes;
  }

  Future<NoteModel?> getNoteById(String noteId) async {
    final data = await _sb
        .from('notes')
        .select()
        .eq('id', noteId)
        .maybeSingle();
    if (data == null) return null;
    return NoteModel.fromMap(data);
  }

  Future<List<String>> getSubjectsForGroups(List<String> groupIds) async {
    if (groupIds.isEmpty) return [];
    final data = await _sb
        .from('notes')
        .select('subject')
        .inFilter('group_id', groupIds);
    final subjects = (data as List)
        .map((d) => d['subject'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    subjects.sort();
    return subjects;
  }
  Future<void> updateMessage({
    required String messageId,
    required Map<String, dynamic> data,
  }) async {
    await _sb.from('messages').update(data).eq('id', messageId);
  }
}