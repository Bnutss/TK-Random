import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart' show TextCapitalization;

import '../models/age_category.dart';
import '../models/athlete.dart';
import '../models/gender.dart';

/// Add/edit dialog for one athlete. Returns the entered data via the
/// dialog's [Navigator.pop] result, or null if cancelled.
class AthleteFormDialog extends StatefulWidget {
  final Athlete? existing;
  final List<AgeCategoryDef> categories;

  const AthleteFormDialog({super.key, this.existing, required this.categories});

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
    final category = year != null
        ? resolveAgeCategoryFrom(widget.categories, year)
        : null;
    final weightClass = (category != null && weight != null)
        ? category.resolveWeightClass(_gender, weight)
        : null;

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 460),
      title: Text(
        widget.existing == null ? 'Новый участник' : 'Изменить участника',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoLabel(
                label: 'Ф.И. спортсмена',
                child: TextFormBox(
                  key: const Key('athlete_name_field'),
                  controller: _nameController,
                  placeholder: 'Например, Saliyev Xayotjon',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Укажите имя' : null,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InfoLabel(
                      label: 'Год рождения',
                      child: TextFormBox(
                        key: const Key('athlete_year_field'),
                        controller: _yearController,
                        placeholder: '2011',
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoLabel(
                      label: 'Вес, кг',
                      child: TextFormBox(
                        key: const Key('athlete_weight_field'),
                        controller: _weightController,
                        placeholder: '45.5',
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
                  ),
                ],
              ),
              const SizedBox(height: 14),
              InfoLabel(
                label: 'Пол',
                child: ComboBox<Gender>(
                  isExpanded: true,
                  value: _gender,
                  items: const [
                    ComboBoxItem(value: Gender.male, child: Text('Мужской')),
                    ComboBoxItem(value: Gender.female, child: Text('Женский')),
                  ],
                  onChanged: (g) => setState(() => _gender = g ?? Gender.male),
                ),
              ),
              const SizedBox(height: 14),
              InfoLabel(
                label: 'Клуб / тренер (необязательно)',
                child: TextFormBox(
                  controller: _clubController,
                  placeholder: 'Chirchiq Saliyev',
                ),
              ),
              const SizedBox(height: 16),
              InfoBar(
                title: const Text('Категория'),
                content: Text(
                  (category == null || weightClass == null)
                      ? 'Заполните год рождения и вес'
                      : '${category.label} · до ${weightClass.label} кг',
                ),
                severity: (category == null || weightClass == null)
                    ? InfoBarSeverity.warning
                    : InfoBarSeverity.info,
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
