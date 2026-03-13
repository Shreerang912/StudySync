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
