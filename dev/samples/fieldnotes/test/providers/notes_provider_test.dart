import 'dart:async';

import 'package:fieldnotes/models/note.dart';
import 'package:fieldnotes/providers/notes_provider.dart';
import 'package:fieldnotes/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// An [ApiService] that never touches the network.
class FakeApiService extends ApiService {
  FakeApiService({this.notes = const []});

  final List<Note> notes;

  /// Ids the provider asked to delete, in order.
  final List<String> deletedIds = [];

  /// When set, `deleteNote` waits for it instead of answering at once.
  Completer<void>? pendingDelete;

  /// When true, `fetchNotes` answers like a server returning 500.
  bool failFetch = false;

  /// When true, `fetchNotes` answers like a server returning 401.
  bool unauthorized = false;

  @override
  Future<List<Note>> fetchNotes(String token) async {
    if (unauthorized) {
      throw const UnauthorizedException();
    }
    if (failFetch) {
      throw const ApiException(500, 'Server error');
    }
    return List.of(notes);
  }

  @override
  Future<Note> createNote(String token, String title, String body) async {
    return Note(
      id: 'created',
      title: title,
      body: body,
      createdAt: DateTime.utc(2024, 1, 1),
    );
  }

  @override
  Future<void> deleteNote(String token, String id) {
    deletedIds.add(id);
    final pending = pendingDelete;
    if (pending != null) {
      return pending.future;
    }
    return Future.value();
  }
}

Note _note(String id) => Note(
  id: id,
  title: 'Title $id',
  body: 'Body $id',
  createdAt: DateTime.utc(2024, 1, 1),
);

List<String> _ids(NotesProvider provider) =>
    provider.notes.map((note) => note.id).toList();

void main() {
  group('NotesProvider.remove', () {
    late FakeApiService api;
    late NotesProvider provider;

    setUp(() async {
      api = FakeApiService(notes: [_note('a'), _note('b'), _note('c')]);
      provider = NotesProvider(api: api);
      await provider.load('token');
      expect(_ids(provider), ['a', 'b', 'c']);
    });

    test('removes the note before the server answers', () async {
      api.pendingDelete = Completer<void>();
      final notifications = <List<String>>[];
      provider.addListener(() => notifications.add(_ids(provider)));

      final removal = provider.remove('token', 'b');

      expect(_ids(provider), ['a', 'c']);
      expect(api.deletedIds, ['b']);
      expect(notifications, [
        ['a', 'c'],
      ]);

      api.pendingDelete!.complete();
      await removal;

      expect(_ids(provider), ['a', 'c']);
      expect(notifications, [
        ['a', 'c'],
      ]);
    });

    test(
      'puts the note back at its original index when the server refuses',
      () async {
        api.pendingDelete = Completer<void>();
        final notifications = <List<String>>[];
        provider.addListener(() => notifications.add(_ids(provider)));

        final removal = provider.remove('token', 'b');
        expect(_ids(provider), ['a', 'c']);

        api.pendingDelete!.completeError(
          const ApiException(500, 'Server error'),
        );

        await expectLater(removal, throwsA(isA<ApiException>()));
        expect(_ids(provider), ['a', 'b', 'c']);
        expect(provider.notes[1].title, 'Title b');
        expect(notifications, [
          ['a', 'c'],
          ['a', 'b', 'c'],
        ]);
      },
    );

    test('does nothing for an id that is not in the list', () async {
      final notifications = <List<String>>[];
      provider.addListener(() => notifications.add(_ids(provider)));

      await provider.remove('token', 'missing');

      expect(_ids(provider), ['a', 'b', 'c']);
      expect(api.deletedIds, isEmpty);
      expect(notifications, isEmpty);
    });
  });

  group('NotesProvider.load', () {
    test(
      'sets the error text on an ApiException and keeps loading false',
      () async {
        final api = FakeApiService()..failFetch = true;
        final provider = NotesProvider(api: api);

        await provider.load('token');

        expect(provider.error, 'Could not load notes');
        expect(provider.isLoading, isFalse);
        expect(provider.notes, isEmpty);
      },
    );

    test('clears the error on the next call', () async {
      final api = FakeApiService(notes: [_note('a')])..failFetch = true;
      final provider = NotesProvider(api: api);
      await provider.load('token');
      expect(provider.error, 'Could not load notes');

      api.failFetch = false;
      await provider.load('token');

      expect(provider.error, isNull);
      expect(_ids(provider), ['a']);
    });

    test('on 401 empties the list and calls onUnauthorized', () async {
      final api = FakeApiService(notes: [_note('a')])..unauthorized = true;
      var unauthorizedCalls = 0;
      final provider = NotesProvider(
        api: api,
        onUnauthorized: () => unauthorizedCalls++,
      );

      await provider.load('token');

      expect(unauthorizedCalls, 1);
      expect(provider.notes, isEmpty);
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
    });
  });

  group('NotesProvider.add', () {
    test('puts the created note at the top of the list', () async {
      final api = FakeApiService(notes: [_note('a')]);
      final provider = NotesProvider(api: api);
      await provider.load('token');

      await provider.add('token', 'New title', 'New body');

      expect(_ids(provider), ['created', 'a']);
      expect(provider.notes.first.title, 'New title');
      expect(provider.notes.first.body, 'New body');
    });
  });
}
