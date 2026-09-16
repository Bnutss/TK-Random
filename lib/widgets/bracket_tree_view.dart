import 'package:fluent_ui/fluent_ui.dart';

import '../models/bracket.dart';

/// Renders a generated draw as horizontally scrollable round columns, each
/// holding its match cards top to bottom.
class BracketTreeView extends StatelessWidget {
  final WeightGroupDraw draw;

  const BracketTreeView({super.key, required this.draw});

  String _roundLabel(int roundIndex) {
    final fromEnd = draw.rounds.length - roundIndex;
    return switch (fromEnd) {
      1 => 'Финал',
      2 => '1/2 финала',
      3 => '1/4 финала',
      4 => '1/8 финала',
      _ => 'Раунд ${roundIndex + 1}',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var r = 0; r < draw.rounds.length; r++)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: SizedBox(
                width: 240,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _roundLabel(r),
                        style: FluentTheme.of(context).typography.bodyStrong,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    for (final match in draw.rounds[r])
                      _MatchCard(match: match),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final BracketMatch match;

  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SlotLine(slot: match.slotA),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 7),
            child: Divider(size: double.infinity),
          ),
          _SlotLine(slot: match.slotB),
        ],
      ),
    );
  }
}

class _SlotLine extends StatelessWidget {
  final BracketSlot slot;

  const _SlotLine({required this.slot});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    if (slot.athlete != null) {
      return Text(
        slot.athlete!.fullName,
        style: theme.typography.body,
        overflow: TextOverflow.ellipsis,
      );
    }
    if (slot.isBye) {
      return Text(
        'БАЙ',
        style: theme.typography.caption?.copyWith(
          color: theme.resources.textFillColorSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Text(
      'ожидается',
      style: theme.typography.caption?.copyWith(
        color: theme.resources.textFillColorTertiary,
      ),
    );
  }
}
