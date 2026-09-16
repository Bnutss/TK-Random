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
