import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:template_app/core/app/failure.dart';
import 'package:template_app/features/support/domain/entities/support_content.dart';
import 'package:template_app/features/support/domain/repositories/support_repository.dart';

/// The content the "server" answers with. Test data.
const testSupportContent = SupportContent(
  intro: 'Questions about an order, a plant or your account?',
  channels: [
    SupportChannel(
      kind: SupportChannelKind.email,
      label: 'General',
      value: 'support@example.com',
      url: 'mailto:support@example.com',
    ),
    SupportChannel(
      kind: SupportChannelKind.phone,
      label: 'Phone',
      value: '+91 90000 00000',
      url: 'tel:+919000000000',
    ),
    SupportChannel(
      kind: SupportChannelKind.whatsapp,
      label: 'WhatsApp',
      value: 'Chat with us',
      url: 'https://wa.me/919000000000',
    ),
  ],
  faqs: [
    SupportFaq(
      question: 'How soon will I get a reply?',
      answer: 'Within one business day.',
    ),
    SupportFaq(
      question: 'Where is my order?',
      answer: 'You will get a tracking link once it ships.',
    ),
  ],
);

/// [content] is what the server answers, [cachedContent] what the device
/// holds (null = a miss). Set [failure] to make the server call fail, and
/// [gate] to hold the server's answer until it completes.
class FakeSupportRepository implements SupportRepository {
  FakeSupportRepository({
    this.content = testSupportContent,
    this.cachedContent,
  });

  SupportContent content;
  SupportContent? cachedContent;
  Failure? failure;
  Completer<void>? gate;
  int calls = 0;

  @override
  Future<Either<Failure, SupportContent>> getSupportContent() async {
    calls++;
    await gate?.future;
    final error = failure;
    return error == null ? Right(content) : Left(error);
  }

  @override
  Future<Either<Failure, SupportContent>> getCachedSupportContent() async {
    final saved = cachedContent;
    return saved == null ? Left(CacheMissFailure()) : Right(saved);
  }
}
