import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../services/api_service.dart';

class NotesProvider extends ChangeNotifier {
  NotesProvider({ApiService? api, this.onUnauthorized})
    : _api = api ?? ApiService();

  final ApiService _api;

  /// Called when the server rejects the token (a 401 on load).
  final VoidCallback? onUnauthorized;

  List<Note> _notes = [];
  bool _isLoading = false;
  String? _error;

  List<Note> get notes => List.unmodifiable(_notes);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetches the notes. Every call hits the network; nothing is cached.
  Future<void> load(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _notes = await _api.fetchNotes(token);
    } on UnauthorizedException {
      _notes = [];
      onUnauthorized?.call();
    } on ApiException {
      _error = 'Could not load notes';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates the note on the server and puts it at the top of the list.
  /// Failures propagate to the caller; the list is left unchanged.
  Future<void> add(String token, String title, String body) async {
    final note = await _api.createNote(token, title, body);
    _notes.insert(0, note);
    notifyListeners();
  }

  /// Optimistic delete: the note leaves the list before the server is
  /// asked. If the server refuses, the note is put back at its original
  /// index and the error is rethrown so the screen can tell the user.
  Future<void> remove(String token, String id) async {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index == -1) {
      return;
    }
    final removed = _notes.removeAt(index);
    notifyListeners();
    try {
      await _api.deleteNote(token, id);
    } catch (_) {
      _notes.insert(index > _notes.length ? _notes.length : index, removed);
      notifyListeners();
      rethrow;
    }
  }

  /// Forgets the notes and the error, so the next user starts clean.
  void clear() {
    _notes = [];
    _error = null;
    notifyListeners();
  }
}
