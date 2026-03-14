import 'package:flutter/material.dart';

class NoteViewerScreen extends StatelessWidget {
  final String noteId;

  const NoteViewerScreen({super.key, required this.noteId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Note Viewer')),
      body: const Center(child: Text('Coming soon')),
    );
  }
}