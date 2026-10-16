import 'package:fieldnotes/models/note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Note', () {
    final json = <String, dynamic>{
      'id': 'n-42',
      'title': 'Soil sample',
      'body': 'Dark, loamy, slightly damp.',
      'created_at': '2024-03-05T09:15:30.000Z',
    };

    test('fromJson reads every field', () {
      final note = Note.fromJson(json);

      expect(note.id, 'n-42');
      expect(note.title, 'Soil sample');
      expect(note.body, 'Dark, loamy, slightly damp.');
      expect(note.createdAt, DateTime.utc(2024, 3, 5, 9, 15, 30));
    });

    test('fromJson then toJson reproduces the original map', () {
      expect(Note.fromJson(json).toJson(), json);
    });

    test('toJson writes created_at as ISO-8601', () {
      final note = Note(
        id: 'a',
        title: 't',
        body: 'b',
        createdAt: DateTime.utc(2025, 12, 31, 23, 59, 59),
      );

      expect(note.toJson()['created_at'], '2025-12-31T23:59:59.000Z');
    });
  });
}
