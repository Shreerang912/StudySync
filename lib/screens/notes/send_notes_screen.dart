import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/group_model.dart';
import '../../models/message_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
 
class SendNotesScreen extends StatefulWidget {
  final GroupModel group;
  final String currentUid;
  final String senderName;
  final String? prefillSubject;
  final String? prefillTopic;
 
  const SendNotesScreen({
    super.key,
    required this.group,
    required this.currentUid,
    required this.senderName,
    this.prefillSubject,
    this.prefillTopic,
  });
 
  @override
  State<SendNotesScreen> createState() => _SendNotesScreenState();
}
 
class _SendNotesScreenState extends State<SendNotesScreen> {
  final _subjectController = TextEditingController();
  final _topicController = TextEditingController();
  final _descController = TextEditingController();
  final _picker = ImagePicker();
  final _db = FirestoreService();
 
  List<File> _selectedImages = [];
  bool _isSending = false;
  String _uploadStatus = '';
 
  @override
  void initState() {
    super.initState();
    if (widget.prefillSubject != null) {
      _subjectController.text = widget.prefillSubject!;
    }
    if (widget.prefillTopic != null) {
      _topicController.text = widget.prefillTopic!;
    }
  }
  @override
  void dispose() {
    _subjectController.dispose();
    _topicController.dispose();
    _descController.dispose();
    super.dispose();
  }
 
   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group, color: Color(0xFF3F51B5)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sending to: ${widget.group.name}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3F51B5)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(_subjectController, 'Subject *',
                'e.g. Physics', Icons.book_outlined),
            const SizedBox(height: 14),
            _buildTextField(_topicController, 'Topic *',
                'e.g. Newton\'s Laws', Icons.topic_outlined),
            const SizedBox(height: 14),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: _inputDecoration(
                'Description (optional)',
                'Any extra notes or context...',
                Icons.description_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildTextField(TextEditingController ctrl, String label,
      String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: _inputDecoration(label, hint, icon),
    );
  }

  InputDecoration _inputDecoration(
      String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF5C6BC0)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF3F51B5), width: 2),
      ),
    );
  }
}