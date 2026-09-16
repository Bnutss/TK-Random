import 'package:fluent_ui/fluent_ui.dart';

import '../models/age_category.dart';
import '../models/gender.dart';
import '../services/category_repository.dart';
import 'category_form_dialog.dart';

/// Manage age categories: add, edit, reorder and delete. Each category owns
/// its own birth-year range and weight-class boundaries per gender; athlete
/// forms, the draw screen and PDF export all read this list automatically.
class CategoriesScreen extends StatefulWidget {
  final CategoryRepository repository;

  const CategoriesScreen({super.key, required this.repository});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  Future<void> _openForm({AgeCategoryDef? existing}) async {
    final result = await showDialog<CategoryFormResult>(
      context: context,
      builder: (_) => CategoryFormDialog(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await widget.repository.add(
        label: result.label,
        minYear: result.minYear,
        maxYear: result.maxYear,
        weightBoundsByGender: result.weightBoundsByGender,
      );
    } else {
      await widget.repository.update(
        existing.copyWith(
          label: result.label,
          minYear: result.minYear,
          clearMinYear: result.minYear == null,
          maxYear: result.maxYear,
          clearMaxYear: result.maxYear == null,
          weightBoundsByGender: result.weightBoundsByGender,
        ),
      );
    }
  }

  Future<void> _confirmDelete(AgeCategoryDef category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Удалить категорию?'),
        content: Text(
          '${category.label}. Уже сформированные и сохранённые в истории '
          'сетки не изменятся, но участники с этой категорией пропадут из '
          'жеребьёвки, пока не выберут другую.',
        ),
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
      await widget.repository.delete(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Категории'),
        commandBar: FilledButton(
          onPressed: () => _openForm(),
          child: const Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.add, size: 16),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Добавить категорию',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      content: ListenableBuilder(
        listenable: widget.repository,
        builder: (context, _) {
          final categories = widget.repository.categories;
          if (categories.isEmpty) {
            return const Center(child: Text('Список категорий пуст'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(
                category: category,
                canMoveUp: index > 0,
                canMoveDown: index < categories.length - 1,
                onMoveUp: () => widget.repository.move(category.id, -1),
                onMoveDown: () => widget.repository.move(category.id, 1),
                onEdit: () => _openForm(existing: category),
                onDelete: () => _confirmDelete(category),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final AgeCategoryDef category;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
  });

  String _weightsSummary(Gender gender) {
    final bounds = category.weightBoundsFor(gender);
    if (bounds.isEmpty) return 'не заданы';
    final classes = category.weightClassesFor(gender);
    return classes.map((c) => c.label).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Card(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              IconButton(
                icon: const Icon(FluentIcons.chevron_up, size: 14),
                onPressed: canMoveUp ? onMoveUp : null,
              ),
              IconButton(
                icon: const Icon(FluentIcons.chevron_down, size: 14),
                onPressed: canMoveDown ? onMoveDown : null,
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    Text(category.label, style: theme.typography.bodyStrong),
                    Text(
                      'год рождения: ${category.yearRangeLabel}',
                      style: theme.typography.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Мужчины: до ${_weightsSummary(Gender.male)} кг',
                  style: theme.typography.body,
                ),
                Text(
                  'Женщины: до ${_weightsSummary(Gender.female)} кг',
                  style: theme.typography.body,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(FluentIcons.edit, size: 15),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(FluentIcons.delete, size: 15),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
