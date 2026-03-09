enum RequestStatus { pending, accepted, rejected }

class FriendRequest {
  final String id;
  final String fromUid;
  final String fromUsername;
  final String toUid;
  final RequestStatus status;
  final DateTime createdAt;
  
  FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromUsername,
    required this.toUid,
    required this.status,
    required this.createdAt,
  });

   factory FriendRequest.fromMap(Map<String, dynamic> map) {
    return FriendRequest(
      id: map['id'] ?? '',
      fromUid: map['from_uid'] ?? '',
      fromUsername: map['from_username'] ?? '',
      toUid: map['to_uid'] ?? '',
      status: RequestStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => RequestStatus.pending,
      ),
      createdAt: _parseDate(map['created_at']),
    );
  }
  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }
}