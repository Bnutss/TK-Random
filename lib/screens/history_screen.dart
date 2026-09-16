import 'package:flutter/material.dart';

import '../models/bracket.dart';
import '../services/tournament_repository.dart';
import 'bracket_view_screen.dart';

class HistoryScreen extends StatelessWidget {
  final TournamentRepository repository;

  const HistoryScreen({super.key, required this.repository});

  Future<void> _confirmDelete(
    BuildContext context,
    Tournament tournament,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить турнир из истории?'),
        content: Text(tournament.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
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
    return Scaffold(
      appBar: AppBar(title: const Text('История турниров')),
      body: ListenableBuilder(
        listenable: repository,
        builder: (context, _) {
          final tournaments = repository.tournaments;
          if (tournaments.isEmpty) {
            return const Center(child: Text('История пуста'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final tournament = tournaments[index];
              final date = tournament.date;
              final dateLabel =
                  '${date.day.toString().padLeft(2, '0')}.'
                  '${date.month.toString().padLeft(2, '0')}.${date.year}';
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  title: Text(tournament.name),
                  subtitle: Text(
                    '$dateLabel · ${tournament.groups.length} сеток',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Удалить',
                    onPressed: () => _confirmDelete(context, tournament),
                  ),
                  children: [
                    for (final draw in tournament.groups)
                      ListTile(
                        title: Text(draw.key.label),
                        subtitle: Text(
                          '${draw.participants.length} участников',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
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
              );
            },
          );
        },
      ),
    );
  }
}
