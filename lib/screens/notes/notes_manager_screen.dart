import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import '../../models/group_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'note_viewer_screen.dart';

class NotesManagerScreen extends StatefulWidget {
  const NotesManagerScreen({super.key});

  @override
  State<NotesManagerScreen> createState() => _NotesManagerScreenState();
}

class _NotesManagerScreenState extends State<NotesManagerScreen> {
  final _db = FirestoreService();
  List<GroupModel> _myGroups = [];
  List<NoteModel> _allNotes = [];
  List<String> _subjects = [];
  String? _selectedSubject;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.id ?? '';

    _db.userGroupsStream(uid).listen((groups) async {
      _myGroups = groups;
      await _loadNotes();
    });
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final groupIds = _myGroups.map((g) => g.id).toList();
    final notes = await _db.fetchNotes(
      groupIds: groupIds,
      subject: _selectedSubject,
    );
    final subjects = await _db.getSubjectsForGroups(groupIds);

    if (mounted) {
      setState(() {
        _allNotes = notes;
        _subjects = subjects;
        _isLoading = false;
      });
    }
  }

  Map<String, List<NoteModel>> _groupNotesBySubject() {
    final Map<String, List<NoteModel>> grouped = {};
    for (final note in _allNotes) {
      grouped.putIfAbsent(note.subject, () => []).add(note);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: const Color(0xFF5C6BC0),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _selectedSubject == null,
                    onTap: () {
                      setState(() => _selectedSubject = null);
                      _loadNotes();
                    },
                  ),
                  ..._subjects.map(
                    (s) => _FilterChip(
                      label: s,
                      selected: _selectedSubject == s,
                      onTap: () {
                        setState(() => _selectedSubject = s);
                        _loadNotes();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open,
                                size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              _selectedSubject != null
                                  ? 'No notes for this subject'
                                  : 'No notes yet',
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Notes shared in your groups will appear here',
                              style:
                                  TextStyle(color: Colors.grey.shade400),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _loadNotes,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotes,
                        child: _selectedSubject != null
                            ? ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _allNotes.length,
                                itemBuilder: (ctx, i) =>
                                    _NoteCard(note: _allNotes[i]),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount:
                                    _groupNotesBySubject().keys.length,
                                itemBuilder: (ctx, i) {
                                  final subject = _groupNotesBySubject()
                                      .keys
                                      .toList()[i];
                                  final notes =
                                      _groupNotesBySubject()[subject]!;
                                  return _SubjectSection(
                                      subject: subject, notes: notes);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF3F51B5) : Colors.white,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SubjectSection extends StatefulWidget {
  final String subject;
  final List<NoteModel> notes;
  const _SubjectSection({required this.subject, required this.notes});

  @override
  State<_SubjectSection> createState() => _SubjectSectionState();
}

class _SubjectSectionState extends State<_SubjectSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF3F51B5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.book, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.subject,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.notes.length} notes',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          ...widget.notes.map((note) => _NoteCard(note: note)),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteModel note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoteViewerScreen(noteId: note.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: const Border(
            left: BorderSide(color: Color(0xFF5C6BC0), width: 4),
          ),
        ),
        child: Row(
          children: [
            if (note.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: note.imageUrls.first,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image,
                        color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.note_alt_outlined,
                    color: Colors.grey),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note.topic,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.book_outlined,
                          size: 13, color: Color(0xFF5C6BC0)),
                      const SizedBox(width: 4),
                      Text(note.subject,
                          style: const TextStyle(
                              color: Color(0xFF5C6BC0), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'by ${note.senderName} • ${DateFormat('d MMM').format(note.timestamp)}',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                  if (note.description != null &&
                      note.description!.isNotEmpty)
                    Text(
                      note.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${note.imageUrls.length} pg',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF3F51B5),
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
