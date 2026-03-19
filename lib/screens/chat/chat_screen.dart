import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/group_model.dart';
import '../../models/message_model.dart';
import '../../models/note_model.dart';
import '../../services/firestore_service.dart';
import '../notes/request_notes_screen.dart';
import '../notes/send_notes_screen.dart';
import '../notes/note_viewer_screen.dart';

class ChatScreen extends StatefulWidget {
  final GroupModel group;
  final String currentUid;
  final String currentUsername;

  const ChatScreen({
    super.key,
    required this.group,
    required this.currentUid,
    this.currentUsername = '',
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final _db = FirestoreService();
  String _senderName = '';

  @override
  void initState() {
    super.initState();
    _loadSenderName();
  }

  Future<void> _loadSenderName() async {
    final user = await _db.getUserById(widget.currentUid);
    if (mounted) setState(() => _senderName = user?.username ?? '');
  }

  Future<void> _sendText() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();
    await _db.sendMessage(
      groupId: widget.group.id,
      senderId: widget.currentUid,
      senderName: _senderName,
      text: text,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.name,
                style: const TextStyle(fontSize: 17)),
            Text(
              '${widget.group.memberUids.length} members',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // Notes Manager shortcut for this group
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'Group Notes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SendNotesScreen(
                  group: widget.group,
                  currentUid: widget.currentUid,
                  senderName: _senderName,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Message list
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _db.messagesStream(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('No messages yet',
                            style: TextStyle(color: Colors.grey.shade400)),
                        Text('Say hello or request notes!',
                            style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == widget.currentUid;
                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                      db: _db,
                      currentUid: widget.currentUid,
                      senderName: _senderName,
                      group: widget.group,
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Request Notes button
          Tooltip(
            message: 'Request Notes',
            child: IconButton(
              icon: const Icon(Icons.request_page_outlined,
                  color: Color(0xFF5C6BC0)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestNotesScreen(
                    group: widget.group,
                    currentUid: widget.currentUid,
                    senderName: _senderName,
                  ),
                ),
              ),
            ),
          ),

          // Send Notes button
          Tooltip(
            message: 'Send Notes',
            child: IconButton(
              icon: const Icon(Icons.upload_file_outlined,
                  color: Color(0xFF5C6BC0)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SendNotesScreen(
                    group: widget.group,
                    currentUid: widget.currentUid,
                    senderName: _senderName,
                  ),
                ),
              ),
            ),
          ),

          // Text input
          Expanded(
            child: TextField(
              controller: _msgController,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Message...',
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendText(),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: _sendText,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF3F51B5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final FirestoreService db;
  final String currentUid;
  final String senderName;
  final GroupModel group;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.db,
    required this.currentUid,
    required this.senderName,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.noteRequest) {
      return _NoteRequestBubble(
        message: message,
        isMe: isMe,
        db: db,
        currentUid: currentUid,
        senderName: senderName,
        group: group,
      );
    }

    if (message.type == MessageType.note) {
      return _NoteBubble(
        message: message,
        isMe: isMe,
        db: db,
      );
    }
    if (message.type == MessageType.noteUploading) {
      return _UploadingNoteBubble(message: message);
    }

    // Regular text message
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF3F51B5) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Text(
                message.senderName,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C6BC0)),
              ),
            Text(
              message.text ?? '',
              style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('h:mm a').format(message.timestamp),
              style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white60 : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteRequestBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final FirestoreService db;
  final String currentUid;
  final String senderName;
  final GroupModel group;

  const _NoteRequestBubble({
    required this.message,
    required this.isMe,
    required this.db,
    required this.currentUid,
    required this.senderName,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.request_page, color: Color(0xFFF57C00), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${message.senderName} is requesting notes',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFFF57C00)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InfoRow('Subject', message.subject ?? '-'),
          _InfoRow('Topic', message.topic ?? '-'),
          const SizedBox(height: 10),
          if (!isMe)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SendNotesScreen(
                      group: group,
                      currentUid: currentUid,
                      senderName: senderName,
                      prefillSubject: message.subject,
                      prefillTopic: message.topic,
                    ),
                  ),
                ),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Send Notes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          Text(
            DateFormat('h:mm a').format(message.timestamp),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _NoteBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final FirestoreService db;

  const _NoteBubble({
    required this.message,
    required this.isMe,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (message.noteId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteViewerScreen(noteId: message.noteId!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EAF6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF5C6BC0), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_alt, color: Color(0xFF3F51B5), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${message.senderName} shared notes',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F51B5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow('Subject', message.subject ?? '-'),
            _InfoRow('Topic', message.topic ?? '-'),
            const SizedBox(height: 6),
            const Row(
              children: [
                Icon(Icons.touch_app, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text('Tap to view notes',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message.timestamp),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          Text(value,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }
}
class _UploadingNoteBubble extends StatefulWidget {
  final MessageModel message;
  const _UploadingNoteBubble({required this.message});

  @override
  State<_UploadingNoteBubble> createState() => _UploadingNoteBubbleState();
}
class _UploadingNoteBubbleState extends State<_UploadingNoteBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder:  (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF5C6BC0), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.note_alt,
                        color: Color(0xFF3F51B5), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.message.senderName} is uploading notes...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3F51B5)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRect(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow('Subject', widget.message.subject ?? 'Loading...'),
                        _InfoRow('Topic', widget.message.topic ?? 'Loading...'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    SizedBox(width: 12, height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF5C6BC0),
                            ),
                          ),
                          SizedBox(width: 6),
                          Text('Uploading...',
                                style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}