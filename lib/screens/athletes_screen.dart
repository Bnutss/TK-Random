import 'package:fluent_ui/fluent_ui.dart';

import '../models/age_category.dart';
import '../models/athlete.dart';
import '../services/athlete_repository.dart';
import '../services/category_repository.dart';
import 'athlete_form_dialog.dart';

class AthletesScreen extends StatefulWidget {
  final AthleteRepository repository;
  final CategoryRepository categoryRepository;

  const AthletesScreen({
    super.key,
    required this.repository,
    required this.categoryRepository,
  });

  @override
  State<AthletesScreen> createState() => _AthletesScreenState();
}

class _AthletesScreenState extends State<AthletesScreen> {
  String _query = '';

  Future<void> _openForm({Athlete? existing}) async {
    final result = await showDialog<AthleteFormResult>(
      context: context,
      builder: (_) => AthleteFormDialog(
        existing: existing,
        categories: widget.categoryRepository.categories,
      ),
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
      builder: (context) => ContentDialog(
        title: const Text('Удалить участника?'),
        content: Text(athlete.fullName),
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
      await widget.repository.delete(athlete.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Участники'),
        commandBar: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 220,
              child: TextBox(
                placeholder: 'Поиск по имени',
                prefix: const Padding(
                  padding: EdgeInsetsDirectional.only(start: 8),
                  child: Icon(FluentIcons.search, size: 16),
                ),
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            FilledButton(
              onPressed: () => _openForm(),
              child: const Padding(
                padding: EdgeInsetsDirectional.symmetric(horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.add, size: 16),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text('Добавить', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      content: ListenableBuilder(
        listenable: Listenable.merge([
          widget.repository,
          widget.categoryRepository,
        ]),
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
            return const Center(
              child: Text(
                'Список участников пуст',
                style: TextStyle(fontSize: 14),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _AthletesTable(
              athletes: athletes,
              categories: widget.categoryRepository.categories,
              onEdit: (a) => _openForm(existing: a),
              onDelete: _confirmDelete,
            ),
          );
        },
      ),
    );
  }
}

class _AthletesTable extends StatelessWidget {
  final List<Athlete> athletes;
  final List<AgeCategoryDef> categories;
  final ValueChanged<Athlete> onEdit;
  final ValueChanged<Athlete> onDelete;

  const _AthletesTable({
    required this.athletes,
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  static const _columns = [
    _Column('Ф.И.', flex: 3),
    _Column('Год', width: 64),
    _Column('Пол', width: 56),
    _Column('Вес', width: 64),
    _Column('Категория', flex: 2),
    _Column('Весовая', width: 96),
    _Column('Клуб / тренер', flex: 2),
    _Column('', width: 84),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.resources.dividerStrokeColorDefault,
              ),
            ),
          ),
          child: Row(
            children: [
              for (final column in _columns)
                _cellSlot(
                  column,
                  Text(
                    column.label,
                    style: theme.typography.bodyStrong?.copyWith(
                      color: theme.resources.textFillColorSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: athletes.length,
            separatorBuilder: (_, _) => Divider(
              style: DividerThemeData(
                thickness: 1,
                horizontalMargin: EdgeInsets.zero,
              ),
            ),
            itemBuilder: (context, index) {
              final athlete = athletes[index];
              return _AthleteRow(
                athlete: athlete,
                categories: categories,
                columns: _columns,
                onEdit: () => onEdit(athlete),
                onDelete: () => onDelete(athlete),
              );
            },
          ),
        ),
      ],
    );
  }
}

Widget _cellSlot(_Column column, Widget child) {
  if (column.width != null) {
    return SizedBox(width: column.width, child: child);
  }
  return Expanded(flex: column.flex, child: child);
}

class _Column {
  final String label;
  final double? width;
  final int flex;

  const _Column(this.label, {this.width, this.flex = 1});
}

class _AthleteRow extends StatefulWidget {
  final Athlete athlete;
  final List<AgeCategoryDef> categories;
  final List<_Column> columns;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AthleteRow({
    required this.athlete,
    required this.categories,
    required this.columns,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_AthleteRow> createState() => _AthleteRowState();
}

class _AthleteRowState extends State<_AthleteRow> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final athlete = widget.athlete;
    final bodyStyle = theme.typography.body;
    final category = resolveAgeCategoryFrom(
      widget.categories,
      athlete.birthYear,
    );
    final weightClass = category?.resolveWeightClass(
      athlete.gender,
      athlete.weightKg,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Container(
        color: _hovering
            ? theme.resources.subtleFillColorSecondary
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _cellSlot(
              widget.columns[0],
              Text(athlete.fullName, style: bodyStyle),
            ),
            _cellSlot(
              widget.columns[1],
              Text('${athlete.birthYear}', style: bodyStyle),
            ),
            _cellSlot(
              widget.columns[2],
              Text(athlete.gender.label, style: bodyStyle),
            ),
            _cellSlot(
              widget.columns[3],
              Text(_formatWeight(athlete.weightKg), style: bodyStyle),
            ),
            _cellSlot(
              widget.columns[4],
              Text(
                category?.label ?? 'не определена',
                style: bodyStyle?.copyWith(
                  color: category == null ? Colors.red : null,
                ),
              ),
            ),
            _cellSlot(
              widget.columns[5],
              Text(
                weightClass != null ? 'до ${weightClass.label}' : '—',
                style: bodyStyle,
              ),
            ),
            _cellSlot(
              widget.columns[6],
              Text(
                athlete.club.isEmpty ? '—' : athlete.club,
                style: bodyStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _cellSlot(
              widget.columns[7],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(FluentIcons.edit, size: 15),
                    onPressed: widget.onEdit,
                  ),
                  IconButton(
                    icon: const Icon(FluentIcons.delete, size: 15),
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatWeight(double weight) {
  return weight == weight.roundToDouble()
      ? weight.toStringAsFixed(0)
      : weight.toStringAsFixed(1);
}
