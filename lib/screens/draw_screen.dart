import 'package:flutter/material.dart';

import '../models/athlete.dart';
import '../models/bracket.dart';
import '../services/athlete_repository.dart';
import '../services/bracket_generator.dart';
import '../services/tournament_repository.dart';
import 'bracket_view_screen.dart';

class DrawScreen extends StatefulWidget {
  final AthleteRepository athleteRepository;
  final TournamentRepository tournamentRepository;

  const DrawScreen({
    super.key,
    required this.athleteRepository,
    required this.tournamentRepository,
  });

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  final Map<GroupKey, WeightGroupDraw> _draws = {};

  void _generate(GroupKey key, List<Athlete> athletes) {
    setState(() {
      _draws[key] = generateDraw(key, athletes);
    });
  }

  void _generateAll(Map<GroupKey, List<Athlete>> groups) {
    setState(() {
      for (final entry in groups.entries) {
        if (entry.value.length >= 2) {
          _draws[entry.key] = generateDraw(entry.key, entry.value);
        }
      }
    });
  }

  Future<void> _saveToHistory() async {
    if (_draws.isEmpty) return;
    final result = await showDialog<_SaveDialogResult>(
      context: context,
      builder: (_) => const _SaveTournamentDialog(),
    );
    if (result == null) return;
    await widget.tournamentRepository.save(
      name: result.name,
      date: result.date,
      groups: _draws.values.toList(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Сохранено в историю')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.athleteRepository,
      builder: (context, _) {
        final groups = widget.athleteRepository.groupForDraw();
        final unresolved = widget.athleteRepository.withUnresolvedCategory();
        final eligibleCount = groups.values.where((v) => v.length >= 2).length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Жеребьёвка'),
            actions: [
              TextButton.icon(
                onPressed: eligibleCount == 0
                    ? null
                    : () => _generateAll(groups),
                icon: const Icon(Icons.shuffle),
                label: const Text('Сформировать все сетки'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _draws.isEmpty ? null : _saveToHistory,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Сохранить в историю'),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: groups.isEmpty
              ? const Center(
                  child: Text('Нет участников с определённой категорией'),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (unresolved.isNotEmpty)
                      Card(
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Категория не определена (${unresolved.length}): '
                            '${unresolved.map((a) => a.fullName).join(', ')}',
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    for (final entry in groups.entries)
                      _GroupTile(
                        athletes: entry.value,
                        draw: _draws[entry.key],
                        onGenerate: entry.value.length >= 2
                            ? () => _generate(entry.key, entry.value)
                            : null,
                        onOpen: _draws[entry.key] == null
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BracketViewScreen(
                                    draw: _draws[entry.key]!,
                                  ),
                                ),
                              ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _GroupTile extends StatelessWidget {
  final List<Athlete> athletes;
  final WeightGroupDraw? draw;
  final VoidCallback? onGenerate;
  final VoidCallback? onOpen;

  const _GroupTile({
    required this.athletes,
    required this.draw,
    required this.onGenerate,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final key = draw?.key;
    final first = athletes.first;
    final label =
        key?.label ??
        '${first.ageCategory!.label} · ${first.gender.label} · до ${first.weightClass!.label} кг';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(label),
        subtitle: Text(
          athletes.length < 2
              ? 'Нет соперников (${athletes.length})'
              : '${athletes.length} участников'
                    '${draw != null ? ' · сетка сформирована' : ''}',
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            if (onGenerate != null)
              OutlinedButton(
                onPressed: onGenerate,
                child: Text(draw == null ? 'Жеребьёвка' : 'Заново'),
              ),
            if (onOpen != null)
              FilledButton(
                onPressed: onOpen,
                child: const Text('Открыть сетку'),
              ),
          ],
        ),
      ),
    );
  }
}

class _SaveDialogResult {
  final String name;
  final DateTime date;

  _SaveDialogResult(this.name, this.date);
}

class _SaveTournamentDialog extends StatefulWidget {
  const _SaveTournamentDialog();

  @override
  State<_SaveTournamentDialog> createState() => _SaveTournamentDialogState();
}

class _SaveTournamentDialogState extends State<_SaveTournamentDialog> {
  final _nameController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Сохранить турнир'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Название турнира'),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Дата: ${_date.day.toString().padLeft(2, '0')}.'
                '${_date.month.toString().padLeft(2, '0')}.${_date.year}',
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: const Text('Изменить'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(_SaveDialogResult(name, _date));
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
