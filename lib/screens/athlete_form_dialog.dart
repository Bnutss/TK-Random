import 'package:flutter/material.dart';

import '../models/age_category.dart';
import '../models/athlete.dart';
import '../models/gender.dart';
import '../models/weight_class.dart';

/// Add/edit dialog for one athlete. Returns the entered data via the
/// dialog's [Navigator.pop] result, or null if cancelled.
class AthleteFormDialog extends StatefulWidget {
  final Athlete? existing;

  const AthleteFormDialog({super.key, this.existing});

  @override
  State<AthleteFormDialog> createState() => _AthleteFormDialogState();
}

class _AthleteFormDialogState extends State<AthleteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _yearController;
  late final TextEditingController _weightController;
  late final TextEditingController _clubController;
  Gender _gender = Gender.male;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.fullName ?? '');
    _yearController = TextEditingController(
      text: existing != null ? existing.birthYear.toString() : '',
    );
    _weightController = TextEditingController(
      text: existing != null ? _formatWeight(existing.weightKg) : '',
    );
    _clubController = TextEditingController(text: existing?.club ?? '');
    _gender = existing?.gender ?? Gender.male;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _weightController.dispose();
    _clubController.dispose();
    super.dispose();
  }

  static String _formatWeight(double weight) {
    return weight == weight.roundToDouble()
        ? weight.toStringAsFixed(0)
        : weight.toStringAsFixed(1);
  }

  int? get _parsedYear => int.tryParse(_yearController.text.trim());
  double? get _parsedWeight =>
      double.tryParse(_weightController.text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    final year = _parsedYear;
    final weight = _parsedWeight;
    final category = year != null ? resolveAgeCategory(year) : null;
    final weightClass = (category != null && weight != null)
        ? WeightClassTables.resolve(category, _gender, weight)
        : null;

    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Новый участник' : 'Изменить участника',
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ф.И. спортсмена',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Укажите имя' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'Год рождения',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final y = int.tryParse((v ?? '').trim());
                          if (y == null) return 'Число';
                          if (y < 1950 || y > DateTime.now().year) {
                            return 'Неверный год';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(labelText: 'Вес, кг'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final w = double.tryParse(
                            (v ?? '').trim().replaceAll(',', '.'),
                          );
                          if (w == null || w <= 0) return 'Число';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<Gender>(
                  segments: const [
                    ButtonSegment(value: Gender.male, label: Text('Муж.')),
                    ButtonSegment(value: Gender.female, label: Text('Жен.')),
                  ],
                  selected: {_gender},
                  onSelectionChanged: (s) => setState(() => _gender = s.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _clubController,
                  decoration: const InputDecoration(
                    labelText: 'Клуб / тренер (необязательно)',
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (category == null || weightClass == null)
                              ? 'Заполните год рождения и вес'
                              : 'Категория: ${category.label} · Весовая: до ${weightClass.label} кг',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              AthleteFormResult(
                fullName: _nameController.text.trim(),
                birthYear: _parsedYear!,
                gender: _gender,
                weightKg: _parsedWeight!,
                club: _clubController.text.trim(),
              ),
            );
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class AthleteFormResult {
  final String fullName;
  final int birthYear;
  final Gender gender;
  final double weightKg;
  final String club;

  AthleteFormResult({
    required this.fullName,
    required this.birthYear,
    required this.gender,
    required this.weightKg,
    required this.club,
  });
}
