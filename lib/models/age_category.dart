import 'gender.dart';
import 'weight_class.dart';

/// A user-editable age category: a birth-year range plus its weight-class
/// boundaries per gender. Replaces the old fixed enum so tournaments can add,
/// rename or remove categories without a code change.
class AgeCategoryDef {
  final String id;
  final String label;

  /// Inclusive birth-year bounds. Null [minYear] means "this year and
  /// older" (no lower bound); null [maxYear] means "this year and younger".
  final int? minYear;
  final int? maxYear;

  final Map<Gender, List<double>> weightBoundsByGender;

  const AgeCategoryDef({
    required this.id,
    required this.label,
    required this.minYear,
    required this.maxYear,
    required this.weightBoundsByGender,
  });

  bool matches(int birthYear) {
    if (minYear != null && birthYear < minYear!) return false;
    if (maxYear != null && birthYear > maxYear!) return false;
    return true;
  }

  String get yearRangeLabel {
    if (minYear == null && maxYear == null) return 'любой год';
    if (minYear == null) return '$maxYear и старше';
    if (maxYear == null) return '$minYear и младше';
    if (minYear == maxYear) return '$minYear';
    return '$minYear–$maxYear';
  }

  List<double> weightBoundsFor(Gender gender) =>
      weightBoundsByGender[gender] ?? const [];

  /// All weight classes (closed + the trailing open class) for [gender], in
  /// ascending order. Empty if no bounds are configured for that gender.
  List<WeightClass> weightClassesFor(Gender gender) {
    final bounds = weightBoundsFor(gender);
    if (bounds.isEmpty) return const [];
    return [
      for (final b in bounds) WeightClass(baseValue: b, isOpenTop: false),
      WeightClass(baseValue: bounds.last, isOpenTop: true),
    ];
  }

  WeightClass? resolveWeightClass(Gender gender, double weightKg) {
    final bounds = weightBoundsFor(gender);
    if (bounds.isEmpty) return null;
    for (final b in bounds) {
      if (weightKg <= b) return WeightClass(baseValue: b, isOpenTop: false);
    }
    return WeightClass(baseValue: bounds.last, isOpenTop: true);
  }

  AgeCategoryDef copyWith({
    String? label,
    int? minYear,
    bool clearMinYear = false,
    int? maxYear,
    bool clearMaxYear = false,
    Map<Gender, List<double>>? weightBoundsByGender,
  }) {
    return AgeCategoryDef(
      id: id,
      label: label ?? this.label,
      minYear: clearMinYear ? null : (minYear ?? this.minYear),
      maxYear: clearMaxYear ? null : (maxYear ?? this.maxYear),
      weightBoundsByGender: weightBoundsByGender ?? this.weightBoundsByGender,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'minYear': minYear,
    'maxYear': maxYear,
    'weightBounds': {
      for (final entry in weightBoundsByGender.entries)
        entry.key.code: entry.value,
    },
  };

  factory AgeCategoryDef.fromJson(Map<String, dynamic> json) {
    final rawBounds = json['weightBounds'] as Map<String, dynamic>? ?? {};
    return AgeCategoryDef(
      id: json['id'] as String,
      label: json['label'] as String,
      minYear: json['minYear'] as int?,
      maxYear: json['maxYear'] as int?,
      weightBoundsByGender: {
        for (final entry in rawBounds.entries)
          Gender.fromCode(entry.key): (entry.value as List)
              .map((e) => (e as num).toDouble())
              .toList(),
      },
    );
  }
}

/// Returns the first category (in list order) whose year range covers
/// [birthYear], or null if none matches.
AgeCategoryDef? resolveAgeCategoryFrom(
  List<AgeCategoryDef> categories,
  int birthYear,
) {
  for (final category in categories) {
    if (category.matches(birthYear)) return category;
  }
  return null;
}

/// Seed categories matching the tournament's original fixed rules. IDs are
/// stable and intentionally match the identifiers used before categories
/// became editable, so history saved by earlier versions keeps resolving.
List<AgeCategoryDef> defaultAgeCategories() => [
  const AgeCategoryDef(
    id: 'adult',
    label: 'Взрослый',
    minYear: null,
    maxYear: 2009,
    weightBoundsByGender: {
      Gender.male: [54, 58, 63, 68, 74, 80, 87],
      Gender.female: [46, 49, 53, 57, 62, 67, 73],
    },
  ),
  const AgeCategoryDef(
    id: 'junior',
    label: 'Юниор',
    minYear: 2010,
    maxYear: 2012,
    weightBoundsByGender: {
      Gender.male: [45, 48, 51, 55, 59, 63, 68, 73, 78],
      Gender.female: [42, 44, 46, 49, 52, 55, 59, 63, 68],
    },
  ),
  const AgeCategoryDef(
    id: 'cadet',
    label: 'Кадет',
    minYear: 2013,
    maxYear: 2015,
    weightBoundsByGender: {
      Gender.male: [33, 37, 41, 45, 49, 53, 57, 61, 65],
      Gender.female: [29, 33, 37, 41, 44, 47, 51, 55, 59],
    },
  ),
  const AgeCategoryDef(
    id: 'childChallenger',
    label: 'Дети челленджер',
    minYear: 2016,
    maxYear: 2017,
    weightBoundsByGender: {
      Gender.male: [26, 28, 30, 32, 34, 36, 38, 40, 42],
      Gender.female: [26, 28, 30, 32, 34, 36, 38, 40, 42],
    },
  ),
];
