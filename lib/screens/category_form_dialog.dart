import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart' show TextCapitalization;

import '../models/age_category.dart';
import '../models/gender.dart';

/// Add/edit dialog for one age category: its label, birth-year range and
/// the weight-class boundaries (kg, ascending) for each gender. Returns the
/// entered data via [Navigator.pop], or null if cancelled.
class CategoryFormDialog extends StatefulWidget {
  final AgeCategoryDef? existing;

  const CategoryFormDialog({super.key, this.existing});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _minYearController;
  late final TextEditingController _maxYearController;
  late final TextEditingController _maleWeightsController;
  late final TextEditingController _femaleWeightsController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _labelController = TextEditingController(text: existing?.label ?? '');
    _minYearController = TextEditingController(
      text: existing?.minYear?.toString() ?? '',
    );
    _maxYearController = TextEditingController(
      text: existing?.maxYear?.toString() ?? '',
    );
    _maleWeightsController = TextEditingController(
      text: _formatBounds(existing?.weightBoundsFor(Gender.male)),
    );
    _femaleWeightsController = TextEditingController(
      text: _formatBounds(existing?.weightBoundsFor(Gender.female)),
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _minYearController.dispose();
    _maxYearController.dispose();
    _maleWeightsController.dispose();
    _femaleWeightsController.dispose();
    super.dispose();
  }

  static String _formatBounds(List<double>? bounds) {
    if (bounds == null || bounds.isEmpty) return '';
    return bounds
        .map(
          (b) => b == b.roundToDouble()
              ? b.toStringAsFixed(0)
              : b.toStringAsFixed(1),
        )
        .join(', ');
  }

  /// Parses "45, 48, 51.5" into an ascending list of positive weights, or
  /// null if the text doesn't parse as a strictly ascending list.
  static List<double>? _parseBounds(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return [];
    final parts = trimmed.split(RegExp(r'[,\s]+'));
    final values = <double>[];
    for (final part in parts) {
      final v = double.tryParse(part.replaceAll(',', '.'));
      if (v == null || v <= 0) return null;
      values.add(v);
    }
    for (var i = 1; i < values.length; i++) {
      if (values[i] <= values[i - 1]) return null;
    }
    return values;
  }

  String? _validateBounds(String? value) {
    if (_parseBounds(value ?? '') == null) {
      return 'Числа по возрастанию через запятую, например 45, 48, 51';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 480),
      title: Text(
        widget.existing == null ? 'Новая категория' : 'Изменить категорию',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoLabel(
                label: 'Название категории',
                child: TextFormBox(
                  controller: _labelController,
                  placeholder: 'Например, Юниор',
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Укажите название'
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InfoLabel(
                      label: 'Год рождения от',
                      child: TextFormBox(
                        controller: _minYearController,
                        placeholder: 'не ограничено',
                        keyboardType: TextInputType.number,
                        validator: _validateYear,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoLabel(
                      label: 'Год рождения по',
                      child: TextFormBox(
                        controller: _maxYearController,
                        placeholder: 'не ограничено',
                        keyboardType: TextInputType.number,
                        validator: _validateYear,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Оставьте поле пустым, если граница не нужна (например, "2009 и старше").',
                style: FluentTheme.of(context).typography.caption,
              ),
              const SizedBox(height: 14),
              InfoLabel(
                label: 'Весовые категории, мужчины (кг, по возрастанию)',
                child: TextFormBox(
                  controller: _maleWeightsController,
                  placeholder: '54, 58, 63, 68, 74, 80, 87',
                  validator: _validateBounds,
                ),
              ),
              const SizedBox(height: 14),
              InfoLabel(
                label: 'Весовые категории, женщины (кг, по возрастанию)',
                child: TextFormBox(
                  controller: _femaleWeightsController,
                  placeholder: '46, 49, 53, 57, 62, 67, 73',
                  validator: _validateBounds,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Последнее значение автоматически становится открытой категорией "+X".',
                style: FluentTheme.of(context).typography.caption,
              ),
            ],
          ),
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final minYear = int.tryParse(_minYearController.text.trim());
            final maxYear = int.tryParse(_maxYearController.text.trim());
            Navigator.of(context).pop(
              CategoryFormResult(
                label: _labelController.text.trim(),
                minYear: minYear,
                maxYear: maxYear,
                weightBoundsByGender: {
                  Gender.male: _parseBounds(_maleWeightsController.text)!,
                  Gender.female: _parseBounds(_femaleWeightsController.text)!,
                },
              ),
            );
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  String? _validateYear(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final y = int.tryParse(text);
    if (y == null) return 'Число';
    return null;
  }
}

class CategoryFormResult {
  final String label;
  final int? minYear;
  final int? maxYear;
  final Map<Gender, List<double>> weightBoundsByGender;

  CategoryFormResult({
    required this.label,
    required this.minYear,
    required this.maxYear,
    required this.weightBoundsByGender,
  });
}
