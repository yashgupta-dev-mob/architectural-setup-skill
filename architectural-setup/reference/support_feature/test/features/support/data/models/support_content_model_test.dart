import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/features/support/data/models/support_content_model.dart';
import 'package:template_app/features/support/domain/entities/support_content.dart';

const Map<String, dynamic> _json = {
  'intro': 'We answer within one business day.',
  'channels': [
    {
      'kind': 'email',
      'label': 'General',
      'value': 'support@example.com',
      'url': 'mailto:support@example.com',
    },
    {
      'kind': 'whatsapp',
      'label': 'WhatsApp',
      'value': 'Chat with us',
      'url': 'https://wa.me/919000000000',
    },
  ],
  'faqs': [
    {'q': 'Where is my order?', 'a': 'You will get a tracking link.'},
  ],
};

void main() {
  test('reads the support object', () {
    final entity = SupportContentModel.fromJson(_json).toEntity();

    expect(entity.intro, 'We answer within one business day.');
    expect(entity.channels.first.kind, SupportChannelKind.email);
    expect(entity.channels.first.label, 'General');
    expect(entity.channels.last.kind, SupportChannelKind.whatsapp);
    expect(entity.faqs.single.question, 'Where is my order?');
    expect(entity.faqs.single.answer, 'You will get a tracking link.');
  });

  test('round-trips through the entity', () {
    final entity = SupportContentModel.fromJson(_json).toEntity();

    expect(SupportContentModel.fromEntity(entity).toJson(), _json);
  });

  test('drops channels without a value or link, and questions without an '
      'answer', () {
    final entity = SupportContentModel.fromJson(const {
      'channels': [
        {'kind': 'phone', 'value': '+91 90000 00000'},
        {'kind': 'phone', 'url': 'tel:+919000000000'},
        {'kind': 'fax', 'value': 'x', 'url': 'mailto:x'},
      ],
      'faqs': [
        {'q': 'No answer?'},
        {'a': 'No question.'},
      ],
    }).toEntity();

    // An unknown kind is kept and reads as email.
    expect(entity.channels.single.kind, SupportChannelKind.email);
    expect(entity.faqs, isEmpty);
    expect(entity.intro, isEmpty);
  });

  test('missing lists read as empty', () {
    final entity = SupportContentModel.fromJson(const {}).toEntity();

    expect(entity.isEmpty, isTrue);
  });
}
