import 'package:flutter/material.dart';
import '../../models/group_model.dart';
import '../../models/message_model.dart';
import '../../services/firestore_service.dart';

class RequestNotesScreen extends StatefulWidget {
  final GroupModel group;
  final String currentUid;
  final String senderName;

  const RequestNotesScreen({
    super.key,
    required this.group,
    required this.currentUid,
    required this.senderName,
  });

  @override
  State<RequestNotesScreen> createState() => _RequestNotesScreenState();
}

class _RequestNotesScreenState extends State<RequestNotesScreen> {
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  bool _isSending = false;

  final List<String> _commonSubjects = [
    'Mathematics', 'Physics', 'Chemistry', 'Biology',
    'History', 'Geography', 'English', 'Computer Science',
    'Economics', 'Psychology',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    if (_subjectController.text.trim().isEmpty ||
        _topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both Subject and Topic')),
      );
      return;
    }

    setState(() => _isSending = true);
    final db = FirestoreService();

    try {
      await db.sendMessage(
        groupId: widget.group.id,
        senderId: widget.currentUid,
        senderName: widget.senderName,
        text:
            ' ${widget.senderName} is requesting notes for ${_subjectController.text.trim()} - ${_topicController.text.trim()}',
        type: MessageType.noteRequest,
        subject: _subjectController.text.trim(),
        topic: _topicController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Note request sent to ${widget.group.name}!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Notes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF8E1), Color(0xFFFFF3CD)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.request_page, color: Color(0xFFF57C00)),
                      SizedBox(width: 8),
                      Text(
                        'Request Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF57C00),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will notify all ${widget.group.memberUids.length} members of "${widget.group.name}" that you need notes.',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Subject',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'e.g. Physics',
                prefixIcon: const Icon(Icons.book_outlined,
                    color: Color(0xFF5C6BC0)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF3F51B5), width: 2),
                ),
              ),
            ),

            const SizedBox(height: 12),
          
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _commonSubjects
                  .map((s) => ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        onPressed: () =>
                            _subjectController.text = s,
                        backgroundColor:
                            const Color(0xFFE8EAF6),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 20),
            const Text('Topic',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                hintText: 'e.g. Newton\'s Laws of Motion',
                prefixIcon: const Icon(Icons.topic_outlined,
                    color: Color(0xFF5C6BC0)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF3F51B5), width: 2),
                ),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendRequest,
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.notifications_active),
                label: Text(_isSending ? 'Sending...' : 'Send Request to Group'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF57C00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}