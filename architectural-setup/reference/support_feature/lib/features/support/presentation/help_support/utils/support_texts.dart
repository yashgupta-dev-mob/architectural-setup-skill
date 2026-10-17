import 'package:flutter/material.dart';

import '../../../../../core/app/failure.dart';
import '../../../domain/entities/support_content.dart';
import '../../../domain/failures/support_failures.dart';

/// Why Help & Support could not load (section 4: by failure type, never
/// the server's text).
String supportLoadFailureMessage(Failure? failure) {
  if (failure is NetworkFailure) {
    return "Couldn't load support details. Check your connection and try "
        'again.';
  }
  if (failure is SupportUnavailableFailure) return supportUnavailableMessage;
  return "Couldn't load support details. Please try again.";
}

/// The server answered with no channels and no questions.
const String supportUnavailableMessage =
    "Support details aren't available right now. Please try again later.";

/// The pull-to-refresh failed while the content stays on screen.
const String supportRefreshFailedMessage =
    "Couldn't refresh support details. Showing the last saved ones.";

/// No app on the phone could open [channel]'s link.
String supportOpenFailedMessage(SupportChannel channel) {
  return switch (channel.kind) {
    SupportChannelKind.email => 'No email app found. Write to ${channel.value}',
    SupportChannelKind.phone => "Couldn't start a call. Dial ${channel.value}",
    SupportChannelKind.whatsapp => "Couldn't open WhatsApp.",
  };
}

/// The icon of a channel row.
IconData supportChannelIcon(SupportChannelKind kind) {
  return switch (kind) {
    SupportChannelKind.email => Icons.mail_outline_rounded,
    SupportChannelKind.phone => Icons.call_outlined,
    SupportChannelKind.whatsapp => Icons.chat_bubble_outline_rounded,
  };
}
