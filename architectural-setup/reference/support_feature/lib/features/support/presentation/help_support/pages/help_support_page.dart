import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/services/analytics/analytics_service.dart';
import '../../../../../core/services/analytics/app_events.dart';
import '../../../../../core/widgets/reload_widget.dart';
import '../../../../../core/widgets/section_label.dart';
import '../../../domain/entities/support_content.dart';
import '../bloc/help_support_bloc.dart';
import '../utils/support_texts.dart';
import '../widgets/help_support_header.dart';
import '../widgets/support_channels_card.dart';
import '../widgets/support_faq_card.dart';

/// Help & Support: how to reach us (email, phone, WhatsApp) and answers to
/// common questions, all from the server so a changed number needs no
/// release. [HelpSupportBloc] owns it.
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HelpSupportBloc>(
      create: (_) => sl<HelpSupportBloc>()..add(HelpSupportStarted()),
      child: const _HelpSupportView(),
    );
  }
}

class _HelpSupportView extends StatelessWidget {
  const _HelpSupportView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<HelpSupportBloc, HelpSupportState>(
      // A refresh failed while the content stays on screen.
      listenWhen: (previous, current) =>
          current.status == HelpSupportStatus.loaded &&
          current.failure != null &&
          current.failure != previous.failure,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            key: Key('support_refreshFailedMessage'),
            content: Text(supportRefreshFailedMessage),
          ),
        ),
      child: Scaffold(
        key: const Key('support_page'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HelpSupportHeader(
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.goNamed(AppRoute.account.name),
            ),
            const Expanded(child: _HelpSupportBody()),
          ],
        ),
      ),
    );
  }
}

class _HelpSupportBody extends StatelessWidget {
  const _HelpSupportBody();

  @override
  Widget build(BuildContext context) {
    final status = context.select((HelpSupportBloc b) => b.state.status);
    final content = context.select((HelpSupportBloc b) => b.state.content);
    void refresh() =>
        context.read<HelpSupportBloc>().add(HelpSupportRefreshed());

    switch (status) {
      case HelpSupportStatus.initial:
      case HelpSupportStatus.loading:
        return const _LoadingSkeleton();
      case HelpSupportStatus.failure:
        final failure = context.select((HelpSupportBloc b) => b.state.failure);
        return ReloadWidget(
          key: const Key('support_errorView'),
          errorMessage: supportLoadFailureMessage(failure),
          onReload: refresh,
        );
      case HelpSupportStatus.loaded:
        if (content.isEmpty) {
          return ReloadWidget(
            key: const Key('support_emptyView'),
            errorMessage: supportUnavailableMessage,
            onReload: refresh,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            final bloc = context.read<HelpSupportBloc>()
              ..add(HelpSupportRefreshed());
            await bloc.stream.firstWhere((s) => !s.isBusy);
          },
          child: _SupportContentList(
            content: content,
            onOpen: (channel) => _open(context, channel),
          ),
        );
    }
  }

  /// Opens the channel's mail, phone or WhatsApp link in its app.
  static Future<void> _open(
    BuildContext context,
    SupportChannel channel,
  ) async {
    context.read<AnalyticsService>().track(
      AppEvents.supportChannelTapped,
      properties: {'channel': channel.kind.name},
    );

    final uri = Uri.tryParse(channel.url);
    var opened = false;
    if (uri != null) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } on Exception {
        opened = false;
      }
    }
    if (opened || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('support_openFailedMessage'),
          content: Text(supportOpenFailedMessage(channel)),
        ),
      );
  }
}

/// The intro, the channels and "Before you write".
class _SupportContentList extends StatelessWidget {
  const _SupportContentList({
    required this.content,
    required this.onOpen,
    this.scrollable = true,
  });

  final SupportContent content;
  final ValueChanged<SupportChannel> onOpen;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      key: const Key('support_scrollView'),
      physics: scrollable
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        if (content.intro.isNotEmpty) ...[
          Text(
            content.intro,
            key: const Key('support_intro'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (content.channels.isNotEmpty)
          SupportChannelsCard(channels: content.channels, onOpen: onOpen),
        if (content.faqs.isNotEmpty) ...[
          const SectionLabel(
            title: 'Before you write',
            padding: EdgeInsets.fromLTRB(0, 24, 0, 10),
          ),
          SupportFaqCard(faqs: content.faqs),
        ],
      ],
    );
  }
}

/// Shimmering placeholder while the content loads, built from the real
/// cards.
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  static const SupportContent _placeholder = SupportContent(
    intro:
        'Questions about an order, a plant or your account? We answer '
        'within one business day.',
    channels: [
      SupportChannel(
        kind: SupportChannelKind.email,
        label: 'General',
        value: 'support@example.com',
        url: '',
      ),
      SupportChannel(
        kind: SupportChannelKind.email,
        label: 'Orders',
        value: 'orders@example.com',
        url: '',
      ),
      SupportChannel(
        kind: SupportChannelKind.phone,
        label: 'Phone',
        value: '+91 00000 00000',
        url: '',
      ),
    ],
    faqs: [
      SupportFaq(question: 'How soon will I get a reply?', answer: ''),
      SupportFaq(question: 'Where is my order?', answer: ''),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Skeletonizer(
      effect: ShimmerEffect(
        baseColor: colors.surfaceContainerHighest,
        highlightColor: colors.surfaceContainerLow,
      ),
      child: KeyedSubtree(
        key: const Key('support_loadingSkeleton'),
        child: _SupportContentList(
          content: _placeholder,
          onOpen: (_) {},
          scrollable: false,
        ),
      ),
    );
  }
}
