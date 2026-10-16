import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/support_content.dart';

/// "Before you write": the questions, each opening into its answer.
class SupportFaqCard extends StatelessWidget {
  const SupportFaqCard({super.key, required this.faqs});

  final List<SupportFaq> faqs;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const Key('support_faqCard'),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < faqs.length; i++) ...[
            if (i > 0) AppCard.divider(context),
            _FaqTile(index: i, faq: faqs[i]),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.index, required this.faq});

  final int index;
  final SupportFaq faq;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            key: Key('support_faq_${widget.index}'),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 22,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    widget.faq.answer,
                    key: Key('support_faqAnswer_${widget.index}'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
