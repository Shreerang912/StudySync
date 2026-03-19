enum MessageType { text, noteRequest, note, noteUploading, image }

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? text;
  final MessageType type;
  final String? noteId;
  final String? subject;
  final String? topic;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.text,
    required this.type,
    this.noteId,
    this.subject,
    this.topic,
    required this.timestamp,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['sender_id'] ?? '',
      senderName: map['sender_name'] ?? '',
      text: map['text'],
      type: MessageType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      noteId: map['note_id'],
      subject: map['subject'],
      topic: map['topic'],
      timestamp: _parseDate(map['created_at']),
    );
  }

  static DateTime _parseDate(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }
}