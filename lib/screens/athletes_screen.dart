import 'package:flutter/material.dart';

import '../models/athlete.dart';
import '../services/athlete_repository.dart';
import 'athlete_form_dialog.dart';

class AthletesScreen extends StatefulWidget {
  final AthleteRepository repository;

  const AthletesScreen({super.key, required this.repository});

  @override
  State<AthletesScreen> createState() => _AthletesScreenState();
}

class _AthletesScreenState extends State<AthletesScreen> {
  String _query = '';

  Future<void> _openForm({Athlete? existing}) async {
    final result = await showDialog<AthleteFormResult>(
      context: context,
      builder: (_) => AthleteFormDialog(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await widget.repository.add(
        fullName: result.fullName,
        birthYear: result.birthYear,
        gender: result.gender,
        weightKg: result.weightKg,
        club: result.club,
      );
    } else {
      await widget.repository.update(
        existing.copyWith(
          fullName: result.fullName,
          birthYear: result.birthYear,
          gender: result.gender,
          weightKg: result.weightKg,
          club: result.club,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Athlete athlete) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить участника?'),
        content: Text(athlete.fullName),
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
      await widget.repository.delete(athlete.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Участники'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              width: 260,
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Поиск по имени',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Добавить'),
      ),
      body: ListenableBuilder(
        listenable: widget.repository,
        builder: (context, _) {
          final athletes =
              widget.repository.athletes
                  .where(
                    (a) =>
                        _query.isEmpty ||
                        a.fullName.toLowerCase().contains(_query),
                  )
                  .toList()
                ..sort((a, b) => a.fullName.compareTo(b.fullName));

          if (athletes.isEmpty) {
            return const Center(child: Text('Список участников пуст'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Ф.И.')),
                  DataColumn(label: Text('Год')),
                  DataColumn(label: Text('Пол')),
                  DataColumn(label: Text('Вес')),
                  DataColumn(label: Text('Категория')),
                  DataColumn(label: Text('Весовая')),
                  DataColumn(label: Text('Клуб / тренер')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  for (final athlete in athletes)
                    DataRow(
                      cells: [
                        DataCell(Text(athlete.fullName)),
                        DataCell(Text('${athlete.birthYear}')),
                        DataCell(Text(athlete.gender.label)),
                        DataCell(Text('${athlete.weightKg}')),
                        DataCell(
                          Text(
                            athlete.ageCategory?.label ?? 'не определена',
                            style: athlete.ageCategory == null
                                ? TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  )
                                : null,
                          ),
                        ),
                        DataCell(
                          Text(
                            athlete.weightClass != null
                                ? 'до ${athlete.weightClass!.label}'
                                : '—',
                          ),
                        ),
                        DataCell(Text(athlete.club)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Изменить',
                                onPressed: () => _openForm(existing: athlete),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Удалить',
                                onPressed: () => _confirmDelete(athlete),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
