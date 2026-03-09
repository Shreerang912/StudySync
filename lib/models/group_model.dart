class GroupModel {
  final String id;
  final String name;
  final String description;
  final String adminUid;
  final List<String> memberUids;
  final String? photoUrl;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.adminUid,
    required this.memberUids,
    this.photoUrl,
    this.lastMessage,
    this.lastMessageTime,
    required this.createdAt,
  });
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      adminUid: map['admin_uid'] ?? '',
      memberUids: List<String>.from(map['member_uids'] ?? []),
      photoUrl: map['photo_url'],
      lastMessage: map['last_message'],
      lastMessageTime: map['last_message_time'] != null
        ? DateTime.tryParse(map['last_message_time'])
        : null,
      createdAt: _parseDate(map['created_at']),
     );
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }
}