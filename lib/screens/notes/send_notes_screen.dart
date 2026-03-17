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
    setState(() {
      _isSending = true;
      _uploadStatus = 'Uploading images...';
    });
    try {
      final List<String> imageUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        setState(() => _uploadStatus =
          'Uploading image ${i + 1} of ${_selectedImages.length}...');
        final url = await CloudinaryService.uploadImage(_selectedImages[i]);
        if (url != null) imageUrls.add(url);
      }
      if (imageUrls.isEmpty) {
        throw Exception('Failed to upload images');
      }
      setState(() => _uploadStatus = 'Saving notes...');
      final noteId = await _db.saveNote(
        senderId: widget.currentUid,
        senderName: widget.senderName,
        groupId: widget.group.id,
        subject: _subjectController.text.trim(),
        topic: _topicController.text.trim(),
        imageUrls: imageUrls,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      );
      await _db.sendMessage(
        groupId: widget.group.id,
        senderId: widget.currentUid,
        senderName: widget.senderName,
        text: 'Shared Notes: ${_subjectController.text.trim()} - ${_topicController.text.trim()} (${imageUrls.length} pages)',
        type: MessageType.note,
        noteId: noteId,
        subject: _subjectController.text.trim(),
        topic: _topicController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes sent successfuly'),
            backgroundColor: Colors.grey,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isSending = false);
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
                            width: 80, height: 80, fit: BoxFit.cover),
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