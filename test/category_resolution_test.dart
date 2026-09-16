import 'package:flutter_test/flutter_test.dart';
import 'package:tk_random/models/age_category.dart';
import 'package:tk_random/models/gender.dart';
import 'package:tk_random/models/weight_class.dart';

void main() {
  group('resolveAgeCategory', () {
    test('adult is 2009 and earlier', () {
      expect(resolveAgeCategory(2009), AgeCategory.adult);
      expect(resolveAgeCategory(1990), AgeCategory.adult);
    });

    test('junior is 2010-2012', () {
      expect(resolveAgeCategory(2010), AgeCategory.junior);
      expect(resolveAgeCategory(2012), AgeCategory.junior);
    });

    test('cadet is 2013-2015', () {
      expect(resolveAgeCategory(2013), AgeCategory.cadet);
      expect(resolveAgeCategory(2015), AgeCategory.cadet);
    });

    test('child challenger is 2016-2017', () {
      expect(resolveAgeCategory(2016), AgeCategory.childChallenger);
      expect(resolveAgeCategory(2017), AgeCategory.childChallenger);
    });

    test('outside all ranges is unresolved', () {
      expect(resolveAgeCategory(2018), isNull);
    });
  });

  group('WeightClassTables.resolve', () {
    test('weight exactly on a boundary falls into that class', () {
      final wc = WeightClassTables.resolve(AgeCategory.adult, Gender.male, 54);
      expect(wc.label, '54');
      expect(wc.isOpenTop, isFalse);
    });

    test('weight just above a boundary falls into the next class', () {
      final wc = WeightClassTables.resolve(
        AgeCategory.adult,
        Gender.male,
        54.1,
      );
      expect(wc.label, '58');
    });

    test('weight above the last boundary is the open class', () {
      final wc = WeightClassTables.resolve(AgeCategory.adult, Gender.male, 200);
      expect(wc.label, '+87');
      expect(wc.isOpenTop, isTrue);
    });

    test('weight exactly on the last boundary is still closed, not open', () {
      final wc = WeightClassTables.resolve(AgeCategory.adult, Gender.male, 87);
      expect(wc.label, '87');
      expect(wc.isOpenTop, isFalse);
    });

    test('child challenger shares the same table for both genders', () {
      final m = WeightClassTables.resolve(
        AgeCategory.childChallenger,
        Gender.male,
        27,
      );
      final f = WeightClassTables.resolve(
        AgeCategory.childChallenger,
        Gender.female,
        27,
      );
      expect(m.label, f.label);
      expect(m.label, '28');
    });
  });
}
