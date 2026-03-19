import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/group_model.dart';
import '../../models/message_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
Future<void> _backgroundUpload({
  required String placeholderMsgId,
  required List<File> images,
  required String currentUid,
  required String senderName,
  required String groupId,
  required String subject,
  required String topic,
  required String? description,
}) async {
  try {
    final db = FirestoreService();
    final results = await Future.wait(
      images.map((img) => CloudinaryService.uploadImage(img)),
    );
    final List<String> imageUrls = results.whereType<String>().toList();
    if (imageUrls.isEmpty) return;

    final noteId = await db.saveNote(
      senderId: currentUid,
      senderName: senderName,
      groupId: groupId,
      subject: subject,
      topic: topic,
      imageUrls: imageUrls,
      description: description,
    );

    await db.updateMessage(
      messageId: placeholderMsgId,
      data: {
        'type': 'note',
        'note_id': noteId,
        'text': 'Shared notes: $subject — $topic (${imageUrls.length} pages)',
      },
    );
  } catch (e) {
    debugPrint('Background upload error: $e');
  }
}
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

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final picked = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 80);
    if (picked != null) {
      setState(() => _selectedImages.add(File(picked.path)));
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _selectedImages.removeAt(oldIndex);
      _selectedImages.insert(newIndex, item);
    });
  }
  Future<void> _sendNotes() async {
    if (_subjectController.text.trim().isEmpty ||
        _topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Subject and Topic')),
      );
      return;
    }
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }
    
    final subject = _subjectController.text.trim();
    final topic = _topicController.text.trim();
    final description = _descController.text.trim().isEmpty
                    ? null
                    : _descController.text.trim();
    final imagesToUpload = List<File>.from(_selectedImages);
    final db = FirestoreService();

    final placeholderMsgId = await db.sendMessage(
      groupId: widget.group.id,
      senderId: widget.currentUid,
      senderName: widget.senderName,
      text: 'Uploading notes: $subject - $topic',
      type: MessageType.noteUploading,
      subject: subject,
      topic: topic,
    );
    if(mounted) Navigator.pop(context);


    _backgroundUpload(
      placeholderMsgId: placeholderMsgId,
      images: imagesToUpload,
      currentUid: widget.currentUid,
      senderName: widget.senderName,
      groupId: widget.group.id,
      subject: subject,
      topic: topic,
      description: description,
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notes'),
        actions: [
          TextButton(
            onPressed: _isSending ? null : _sendNotes,
            child: const Text('Send',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16)),
          ),
        ],
      ),
      body: _isSending
      ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF3F51B5)),
            const SizedBox(height: 16),
            Text(_uploadStatus, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ) : SingleChildScrollView(
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
            const SizedBox(height: 20),

         
            Row(
              children: [
                const Text('Images',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  '${_selectedImages.length} selected',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),

            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3F51B5),
                      side: const BorderSide(color: Color(0xFF3F51B5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3F51B5),
                      side: const BorderSide(color: Color(0xFF3F51B5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_selectedImages.isNotEmpty) ...[
              const Text(
                'Long press and drag to reorder pages',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:_selectedImages.length,
                onReorder: _reorderImages,
                itemBuilder: (context, index) {
                  return Container(
                    key: ValueKey(_selectedImages[index].path),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3F51B5),
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(11)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.drag_handle,
                              color: Colors.white, size: 18),
                              Text('${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                              Text('of ${_selectedImages.length}',
                                  style: const TextStyle(
                                    color: Colors.white60, fontSize: 10)),
                            ],
                          ),
                        ),
                        Image.file(_selectedImages[index],
                            width: 80, height: 80, fit: BoxFit.cover, cacheWidth: 160),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Page ${index + 1}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                              onPressed: () => _removeImage(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSending ? null : _sendNotes,
                icon: const Icon(Icons.send),
                label: const Text('Send Notes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
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
        borderSide: const BorderSide(color: Color(0xFF3F51B5), width: 2),
      ),
    );
  }
}