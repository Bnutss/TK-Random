import 'age_category.dart';
import 'gender.dart';

/// A resolved weight class, e.g. "up to 54 kg" or the open-ended "+87 kg".
class WeightClass implements Comparable<WeightClass> {
  final double baseValue;
  final bool isOpenTop;

  const WeightClass({required this.baseValue, required this.isOpenTop});

  String get label {
    final valueLabel = baseValue == baseValue.roundToDouble()
        ? baseValue.toStringAsFixed(0)
        : baseValue.toStringAsFixed(1);
    return isOpenTop ? '+$valueLabel' : valueLabel;
  }

  /// Stable key for grouping/storage, independent of display formatting.
  String get key => '${isOpenTop ? "open" : "upto"}_$baseValue';

  @override
  int compareTo(WeightClass other) {
    final byValue = baseValue.compareTo(other.baseValue);
    if (byValue != 0) return byValue;
    // an open class with the same base value sorts after the closed one
    return (isOpenTop ? 1 : 0).compareTo(other.isOpenTop ? 1 : 0);
  }

  @override
  bool operator ==(Object other) =>
      other is WeightClass &&
      other.baseValue == baseValue &&
      other.isOpenTop == isOpenTop;

  @override
  int get hashCode => Object.hash(baseValue, isOpenTop);

  @override
  String toString() => label;
}

/// Fixed weight-class boundaries (kg), "up to and including" each value.
/// Anything heavier than the last value falls into the open `+X` class.
class WeightClassTables {
  WeightClassTables._();

  static const Map<AgeCategory, Map<Gender, List<double>>> _bounds = {
    AgeCategory.adult: {
      Gender.male: [54, 58, 63, 68, 74, 80, 87],
      Gender.female: [46, 49, 53, 57, 62, 67, 73],
    },
    AgeCategory.junior: {
      Gender.male: [45, 48, 51, 55, 59, 63, 68, 73, 78],
      Gender.female: [42, 44, 46, 49, 52, 55, 59, 63, 68],
    },
    AgeCategory.cadet: {
      Gender.male: [33, 37, 41, 45, 49, 53, 57, 61, 65],
      Gender.female: [29, 33, 37, 41, 44, 47, 51, 55, 59],
    },
    // Child Challenger shares one list across both genders.
    AgeCategory.childChallenger: {
      Gender.male: [26, 28, 30, 32, 34, 36, 38, 40, 42],
      Gender.female: [26, 28, 30, 32, 34, 36, 38, 40, 42],
    },
  };

  static List<double> boundsFor(AgeCategory category, Gender gender) =>
      _bounds[category]![gender]!;

  /// All weight classes (closed + the trailing open class) for a category/gender,
  /// in ascending order — useful for listing buckets even when empty.
  static List<WeightClass> allClassesFor(AgeCategory category, Gender gender) {
    final bounds = boundsFor(category, gender);
    return [
      for (final b in bounds) WeightClass(baseValue: b, isOpenTop: false),
      WeightClass(baseValue: bounds.last, isOpenTop: true),
    ];
  }

  static WeightClass resolve(
    AgeCategory category,
    Gender gender,
    double weightKg,
  ) {
    final bounds = boundsFor(category, gender);
    for (final b in bounds) {
      if (weightKg <= b) return WeightClass(baseValue: b, isOpenTop: false);
    }
    return WeightClass(baseValue: bounds.last, isOpenTop: true);
  }
}
