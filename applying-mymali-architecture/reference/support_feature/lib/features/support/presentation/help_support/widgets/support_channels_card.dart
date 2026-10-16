import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_card.dart';
import '../../../../../core/widgets/icon_list_tile.dart';
import '../../../domain/entities/support_content.dart';
import '../utils/support_texts.dart';

/// The ways to reach support, one row each: the channel's caption over
/// its address or number, opened on tap.
class SupportChannelsCard extends StatelessWidget {
  const SupportChannelsCard({
    super.key,
    required this.channels,
    required this.onOpen,
  });

  final List<SupportChannel> channels;
  final ValueChanged<SupportChannel> onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const Key('support_channelsCard'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < channels.length; i++) ...[
            if (i > 0) AppCard.divider(context),
            IconListTile(
              key: Key('support_channel_$i'),
              icon: supportChannelIcon(channels[i].kind),
              overline: channels[i].label,
              title: channels[i].value,
              showChevron: true,
              onTap: () => onOpen(channels[i]),
            ),
          ],
        ],
      ),
    );
  }
}
