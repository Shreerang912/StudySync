class NoteModel {
  final String id;
  final String senderId;
  final String senderName;
  final String groupId;
  final String subject;
  final String topic;
  final List<String> imageUrls;
  final String? description;
  final DateTime timestamp;


NoteModel({
  required this.id,
  required this.senderId,
  required this.senderName,
  required this.groupId,
  required this.subject,
  required this.topic,
  required this.imageUrls,
  this.description,
  required this.timestamp,
});

factory NoteModel.fromMap(Map<String, dynamic> map) {
  return NoteModel(
    id: map['id'] ?? '',
      senderId: map['sender_id'] ?? '',
      senderName: map['sender_name'] ?? '',
      groupId: map['group_id'] ?? '',
      subject: map['subject'] ?? '',
      topic: map['topic'] ?? '',
      imageUrls: (map['image_urls'] as List? ?? [])
      .map((e) => e.toString().replaceAll('"', '').trim())
      .where((e) => e.isNotEmpty && e.startsWith('http'))
      .toList(),
      description: map['description'],
      timestamp: _parseDate(map['created_at']),
  );
}

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }
}