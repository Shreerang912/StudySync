class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photo_url'],
      createdAt: _parseDate(map['created_at']),
    );
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }
}
