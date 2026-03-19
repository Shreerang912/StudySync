import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/note_model.dart';
import '../../services/firestore_service.dart';

class NoteViewerScreen extends StatefulWidget {
  final String noteId;

  const NoteViewerScreen({super.key, required this.noteId});

  @override
  State<NoteViewerScreen> createState() => _NoteViewerScreenState();
}

class _NoteViewerScreenState extends State<NoteViewerScreen> {
  final _db = FirestoreService();
  NoteModel? _note;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final note = await _db.getNoteById(widget.noteId);
    if (mounted) {
      setState(() {
        _note = note;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _note?.subject ?? 'Note Viewer',
          style: const TextStyle(fontSize: 17),
        ),
      ),
      body: _isLoading
      ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF3F51B5)),
      )
      :  _note == null
        ? const Center(child: Text('Note not found'))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFFE8EAF6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F51B5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _note!.subject,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          _note!.topic,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                        ),
                      ),
                     ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _note!.senderName,
                          style: const TextStyle( color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: Colors.grey,),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, yyyy').format(_note!.timestamp),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const Spacer(),
                        const Icon(Icons.photo_library_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${_note!.imageUrls.length} pages',
                        style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Images coming soon',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
        ),
    );
  }
}