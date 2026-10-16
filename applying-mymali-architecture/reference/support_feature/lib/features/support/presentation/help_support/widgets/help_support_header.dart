import 'package:flutter/material.dart';

import '../../../../../core/widgets/page_header.dart';

/// The Help & Support page's header: back button and title.
class HelpSupportHeader extends StatelessWidget {
  const HelpSupportHeader({super.key, required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return PageHeader(
      title: 'Help & Support',
      backKey: const Key('support_backButton'),
      onBack: onBack,
    );
  }
}
