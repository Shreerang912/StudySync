import 'package:cached_network_image/cached_network_image.dart';
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
  int _currentPage = 0;

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
        if (note != null) {
          debugPrint('First URL: ${note.imageUrls.isNotEmpty ? note.imageUrls[0] : "EMPTY"}');
        }
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
       : Stack(
                  children: [
                
                    PageView.builder(
                      itemCount: _note!.imageUrls.length,
                      onPageChanged: (i) =>
                          setState(() => _currentPage = i),
                      itemBuilder: (context, index) {
                    return InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: CachedNetworkImage(
                                imageUrl: _note!.imageUrls[index],
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(color: Color(0xFF3F51B5)),
                                ),
                                errorWidget: (context, url, error) => const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Could not load image',
                                          style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                    );
                  },
                ),

                    Positioned(
                      top: 12,
                      left: 12,
                      right: 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3F51B5).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _note!.subject,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _note!.topic,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentPage + 1} / ${_note!.imageUrls.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),

               
                    Positioned(
                      bottom: 16,
                      left: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    size: 13, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(_note!.senderName,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 11)),
                                const SizedBox(width: 12),
                                const Icon(Icons.calendar_today_outlined,
                                    size: 13, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM d, yyyy')
                                      .format(_note!.timestamp),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (_note!.description != null &&
                              _note!.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _note!.description!,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}