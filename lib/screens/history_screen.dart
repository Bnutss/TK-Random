import 'package:fluent_ui/fluent_ui.dart';

import '../models/bracket.dart';
import '../services/tournament_repository.dart';
import 'bracket_view_screen.dart';

class HistoryScreen extends StatelessWidget {
  final TournamentRepository repository;

  const HistoryScreen({super.key, required this.repository});

  Future<void> _confirmDelete(BuildContext context, Tournament tournament) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Удалить турнир из истории?'),
        content: Text(tournament.name),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await repository.delete(tournament.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('История турниров')),
      content: ListenableBuilder(
        listenable: repository,
        builder: (context, _) {
          final tournaments = repository.tournaments;
          if (tournaments.isEmpty) {
            return const Center(child: Text('История пуста'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final tournament = tournaments[index];
              final date = tournament.date;
              final dateLabel = '${date.day.toString().padLeft(2, '0')}.'
                  '${date.month.toString().padLeft(2, '0')}.${date.year}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Expander(
                  leading: const Icon(FluentIcons.trophy2),
                  header: Text(tournament.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$dateLabel · ${tournament.groups.length} сеток',
                        style: FluentTheme.of(context).typography.caption,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(FluentIcons.delete, size: 15),
                        onPressed: () => _confirmDelete(context, tournament),
                      ),
                    ],
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final draw in tournament.groups)
                        _DrawListTile(
                          draw: draw,
                          onTap: () => Navigator.of(context).push(
                            FluentPageRoute(
                              builder: (_) => BracketViewScreen(
                                draw: draw,
                                tournamentName: tournament.name,
                                tournamentDate: tournament.date,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DrawListTile extends StatelessWidget {
  final WeightGroupDraw draw;
  final VoidCallback onTap;

  const _DrawListTile({required this.draw, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return HyperlinkButton(
      onPressed: onTap,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              draw.key.label,
              style: theme.typography.body?.copyWith(color: theme.resources.textFillColorPrimary),
            ),
          ),
          Text(
            '${draw.participants.length} участников',
            style: theme.typography.caption,
          ),
          const SizedBox(width: 6),
          const Icon(FluentIcons.chevron_right, size: 12),
        ],
      ),
    );
  }
}
