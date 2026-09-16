import 'package:fluent_ui/fluent_ui.dart';

import '../models/athlete.dart';
import '../models/bracket.dart';
import '../services/athlete_repository.dart';
import '../services/bracket_generator.dart';
import '../services/category_repository.dart';
import '../services/tournament_repository.dart';
import 'bracket_view_screen.dart';

class DrawScreen extends StatefulWidget {
  final AthleteRepository athleteRepository;
  final CategoryRepository categoryRepository;
  final TournamentRepository tournamentRepository;

  const DrawScreen({
    super.key,
    required this.athleteRepository,
    required this.categoryRepository,
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
    await showDialog<void>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Сохранено'),
        content: const Text('Турнир сохранён в историю.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ок'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.athleteRepository,
        widget.categoryRepository,
      ]),
      builder: (context, _) {
        final categories = widget.categoryRepository.categories;
        final groups = widget.athleteRepository.groupForDraw(categories);
        final unresolved = widget.athleteRepository.withUnresolvedCategory(
          categories,
        );
        final eligibleCount = groups.values.where((v) => v.length >= 2).length;

        return ScaffoldPage(
          header: PageHeader(
            title: const Text('Жеребьёвка'),
            commandBar: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Button(
                  onPressed: eligibleCount == 0
                      ? null
                      : () => _generateAll(groups),
                  child: const Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.branch_fork2, size: 15),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Сформировать все сетки',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: _draws.isEmpty ? null : _saveToHistory,
                  child: const Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.save, size: 15),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Сохранить в историю',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          content: groups.isEmpty
              ? const Center(
                  child: Text('Нет участников с определённой категорией'),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    if (unresolved.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InfoBar(
                          title: const Text('Категория не определена'),
                          content: Text(
                            unresolved.map((a) => a.fullName).join(', '),
                          ),
                          severity: InfoBarSeverity.warning,
                        ),
                      ),
                    for (final entry in groups.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _GroupExpander(
                          groupKey: entry.key,
                          athletes: entry.value,
                          draw: _draws[entry.key],
                          onGenerate: entry.value.length >= 2
                              ? () => _generate(entry.key, entry.value)
                              : null,
                          onOpen: _draws[entry.key] == null
                              ? null
                              : () => Navigator.of(context).push(
                                  FluentPageRoute(
                                    builder: (_) => BracketViewScreen(
                                      draw: _draws[entry.key]!,
                                    ),
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

class _GroupExpander extends StatelessWidget {
  final GroupKey groupKey;
  final List<Athlete> athletes;
  final WeightGroupDraw? draw;
  final VoidCallback? onGenerate;
  final VoidCallback? onOpen;

  const _GroupExpander({
    required this.groupKey,
    required this.athletes,
    required this.draw,
    required this.onGenerate,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final label = groupKey.label;

    return Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            FluentIcons.people,
            size: 18,
            color: theme.resources.textFillColorSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.typography.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  athletes.length < 2
                      ? 'Нет соперников (${athletes.length})'
                      : '${athletes.length} участников'
                            '${draw != null ? ' · сетка сформирована' : ''}',
                  style: theme.typography.caption,
                ),
              ],
            ),
          ),
          if (onGenerate != null)
            Button(
              onPressed: onGenerate,
              child: Text(draw == null ? 'Жеребьёвка' : 'Заново'),
            ),
          if (onOpen != null) ...[
            const SizedBox(width: 8),
            FilledButton(onPressed: onOpen, child: const Text('Открыть сетку')),
          ],
        ],
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
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 420),
      title: const Text('Сохранить турнир'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoLabel(
            label: 'Название турнира',
            child: TextBox(
              controller: _nameController,
              placeholder: 'Например, Чемпионат Ташкентской области',
              autofocus: true,
            ),
          ),
          const SizedBox(height: 14),
          InfoLabel(
            label: 'Дата проведения',
            child: DatePicker(
              selected: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
          ),
        ],
      ),
      actions: [
        Button(
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
