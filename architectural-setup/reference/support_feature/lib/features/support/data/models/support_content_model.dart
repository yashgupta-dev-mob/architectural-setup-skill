import '../../../../core/utils/json_readers.dart';
import '../../domain/entities/support_content.dart';

/// The `support` object of the app-state Edge Function
/// (`settings:support`):
/// `{ intro, channels: [{ kind, label, value, url }], faqs: [{ q, a }] }`.
/// Every field may be missing; the entity keeps only usable entries.
class SupportContentModel {
  const SupportContentModel({
    this.intro = '',
    this.channels = const [],
    this.faqs = const [],
  });

  factory SupportContentModel.fromJson(Map<String, dynamic> json) {
    return SupportContentModel(
      intro: asString(json['intro'])?.trim() ?? '',
      channels: [
        for (final channel in asMapList(json['channels']))
          SupportChannelModel.fromJson(channel),
      ],
      faqs: [
        for (final faq in asMapList(json['faqs']))
          SupportFaqModel.fromJson(faq),
      ],
    );
  }

  factory SupportContentModel.fromEntity(SupportContent entity) {
    return SupportContentModel(
      intro: entity.intro,
      channels: [
        for (final channel in entity.channels)
          SupportChannelModel.fromEntity(channel),
      ],
      faqs: [for (final faq in entity.faqs) SupportFaqModel.fromEntity(faq)],
    );
  }

  final String intro;
  final List<SupportChannelModel> channels;
  final List<SupportFaqModel> faqs;

  Map<String, dynamic> toJson() => {
    'intro': intro,
    'channels': [for (final channel in channels) channel.toJson()],
    'faqs': [for (final faq in faqs) faq.toJson()],
  };

  SupportContent toEntity() => SupportContent(
    intro: intro,
    channels: [
      for (final channel in channels)
        if (channel.isUsable) channel.toEntity(),
    ],
    faqs: [
      for (final faq in faqs)
        if (faq.isUsable) faq.toEntity(),
    ],
  );
}

/// One entry of `channels`:
/// `{ kind: "email" | "phone" | "whatsapp", label, value, url }`.
class SupportChannelModel {
  const SupportChannelModel({
    this.kind = '',
    this.label = '',
    this.value = '',
    this.url = '',
  });

  factory SupportChannelModel.fromJson(Map<String, dynamic> json) {
    String text(String key) => asString(json[key])?.trim() ?? '';
    return SupportChannelModel(
      kind: text('kind'),
      label: text('label'),
      value: text('value'),
      url: text('url'),
    );
  }

  factory SupportChannelModel.fromEntity(SupportChannel entity) {
    return SupportChannelModel(
      kind: entity.kind.name,
      label: entity.label,
      value: entity.value,
      url: entity.url,
    );
  }

  final String kind;
  final String label;
  final String value;
  final String url;

  /// A row needs something to show and something to open.
  bool get isUsable => value.isNotEmpty && url.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'label': label,
    'value': value,
    'url': url,
  };

  /// An unknown kind reads as email, as the previous app does.
  SupportChannel toEntity() => SupportChannel(
    kind:
        SupportChannelKind.values.asNameMap()[kind] ?? SupportChannelKind.email,
    label: label,
    value: value,
    url: url,
  );
}

/// One entry of `faqs`: `{ q, a }`.
class SupportFaqModel {
  const SupportFaqModel({this.question = '', this.answer = ''});

  factory SupportFaqModel.fromJson(Map<String, dynamic> json) {
    return SupportFaqModel(
      question: asString(json['q'])?.trim() ?? '',
      answer: asString(json['a'])?.trim() ?? '',
    );
  }

  factory SupportFaqModel.fromEntity(SupportFaq entity) {
    return SupportFaqModel(question: entity.question, answer: entity.answer);
  }

  final String question;
  final String answer;

  bool get isUsable => question.isNotEmpty && answer.isNotEmpty;

  Map<String, dynamic> toJson() => {'q': question, 'a': answer};

  SupportFaq toEntity() => SupportFaq(question: question, answer: answer);
}
