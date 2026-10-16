import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/auth_provider.dart';
import '../providers/notes_provider.dart';
import 'new_note_screen.dart';
import 'settings_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  Future<void> _load() {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      return Future.value();
    }
    return context.read<NotesProvider>().load(token);
  }

  Future<void> _logout() async {
    context.read<NotesProvider>().clear();
    await context.read<AuthProvider>().logout();
  }

  Future<void> _delete(Note note) async {
    final token = context.read<AuthProvider>().token;
    final notes = context.read<NotesProvider>();
    if (token == null) {
      return;
    }
    try {
      await notes.remove(token, note.id);
      Fluttertoast.showToast(msg: 'Note deleted');
    } catch (_) {
      Fluttertoast.showToast(msg: 'Could not delete note');
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  void _openNewNote() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const NewNoteScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field notes'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(notesProvider),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        tooltip: 'New note',
        onPressed: _openNewNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(NotesProvider provider) {
    final error = provider.error;
    if (error != null) {
      return _fillViewport(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, style: const TextStyle(color: Colors.redAccent)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (provider.isLoading && provider.notes.isEmpty) {
      return _fillViewport(const CircularProgressIndicator());
    }
    if (provider.notes.isEmpty) {
      return _fillViewport(
        const Text('No notes yet', style: TextStyle(color: Colors.grey)),
      );
    }

    final notes = provider.notes;
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Dismissible(
          key: ValueKey(note.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.redAccent,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _delete(note),
          child: ListTile(
            title: Text(note.title),
            subtitle: Text(
              note.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              _formatDate(note.createdAt),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  /// Makes a non-list state scrollable so pull-to-refresh still works.
  Widget _fillViewport(Widget child) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(hasScrollBody: false, child: Center(child: child)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}
