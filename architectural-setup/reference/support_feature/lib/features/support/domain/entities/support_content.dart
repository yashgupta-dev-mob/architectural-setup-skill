import 'package:equatable/equatable.dart';

/// How a [SupportChannel] is reached; it picks the row's icon.
enum SupportChannelKind { email, phone, whatsapp }

/// One way to reach support, e.g. "Orders · orders@example.com".
class SupportChannel extends Equatable {
  const SupportChannel({
    required this.kind,
    required this.value,
    required this.url,
    this.label = '',
  });

  final SupportChannelKind kind;

  /// The small caption above [value], e.g. "General"; may be empty.
  final String label;

  /// What the row shows: the address, the number, or "Chat with us".
  final String value;

  /// What a tap opens: `mailto:`, `tel:` or a WhatsApp link.
  final String url;

  @override
  List<Object?> get props => [kind, label, value, url];
}

/// One question of "Before you write" and its answer.
class SupportFaq extends Equatable {
  const SupportFaq({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  List<Object?> get props => [question, answer];
}

/// The Help & Support page's content, from the server (`settings:support`):
/// the line at the top, the contact channels and the questions. Only
/// channels with a value and a link, and questions with an answer, are
/// kept.
class SupportContent extends Equatable {
  const SupportContent({
    this.intro = '',
    this.channels = const [],
    this.faqs = const [],
  });

  final String intro;
  final List<SupportChannel> channels;
  final List<SupportFaq> faqs;

  /// Nothing to contact and nothing to read.
  bool get isEmpty => channels.isEmpty && faqs.isEmpty;

  @override
  List<Object?> get props => [intro, channels, faqs];
}
