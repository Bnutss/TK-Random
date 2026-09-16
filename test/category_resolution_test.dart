import 'package:flutter_test/flutter_test.dart';
import 'package:tk_random/models/age_category.dart';
import 'package:tk_random/models/gender.dart';

void main() {
  final categories = defaultAgeCategories();

  group('resolveAgeCategoryFrom (default categories)', () {
    test('adult is 2009 and earlier', () {
      expect(resolveAgeCategoryFrom(categories, 2009)?.id, 'adult');
      expect(resolveAgeCategoryFrom(categories, 1990)?.id, 'adult');
    });

    test('junior is 2010-2012', () {
      expect(resolveAgeCategoryFrom(categories, 2010)?.id, 'junior');
      expect(resolveAgeCategoryFrom(categories, 2012)?.id, 'junior');
    });

    test('cadet is 2013-2015', () {
      expect(resolveAgeCategoryFrom(categories, 2013)?.id, 'cadet');
      expect(resolveAgeCategoryFrom(categories, 2015)?.id, 'cadet');
    });

    test('child challenger is 2016-2017', () {
      expect(resolveAgeCategoryFrom(categories, 2016)?.id, 'childChallenger');
      expect(resolveAgeCategoryFrom(categories, 2017)?.id, 'childChallenger');
    });

    test('outside all ranges is unresolved', () {
      expect(resolveAgeCategoryFrom(categories, 2018), isNull);
    });
  });

  group('AgeCategoryDef.resolveWeightClass (default categories)', () {
    AgeCategoryDef byId(String id) => categories.firstWhere((c) => c.id == id);

    test('weight exactly on a boundary falls into that class', () {
      final wc = byId('adult').resolveWeightClass(Gender.male, 54);
      expect(wc!.label, '54');
      expect(wc.isOpenTop, isFalse);
    });

    test('weight just above a boundary falls into the next class', () {
      final wc = byId('adult').resolveWeightClass(Gender.male, 54.1);
      expect(wc!.label, '58');
    });

    test('weight above the last boundary is the open class', () {
      final wc = byId('adult').resolveWeightClass(Gender.male, 200);
      expect(wc!.label, '+87');
      expect(wc.isOpenTop, isTrue);
    });

    test('weight exactly on the last boundary is still closed, not open', () {
      final wc = byId('adult').resolveWeightClass(Gender.male, 87);
      expect(wc!.label, '87');
      expect(wc.isOpenTop, isFalse);
    });

    test('child challenger shares the same table for both genders', () {
      final m = byId('childChallenger').resolveWeightClass(Gender.male, 27);
      final f = byId('childChallenger').resolveWeightClass(Gender.female, 27);
      expect(m!.label, f!.label);
      expect(m.label, '28');
    });
  });

  group('custom categories', () {
    test('an added category with an open lower bound matches older years', () {
      const veteran = AgeCategoryDef(
        id: 'veteran',
        label: 'Ветеран',
        minYear: null,
        maxYear: 1990,
        weightBoundsByGender: {
          Gender.male: [70, 80],
        },
      );
      final withVeteran = [veteran, ...categories];
      expect(resolveAgeCategoryFrom(withVeteran, 1985)?.id, 'veteran');
      expect(veteran.resolveWeightClass(Gender.male, 75)!.label, '80');
      expect(veteran.resolveWeightClass(Gender.female, 75), isNull);
    });

    test('categories are matched in list order, first match wins', () {
      const narrow = AgeCategoryDef(
        id: 'narrow',
        label: 'Узкая',
        minYear: 2010,
        maxYear: 2010,
        weightBoundsByGender: {},
      );
      final ordered = [narrow, ...categories];
      expect(resolveAgeCategoryFrom(ordered, 2010)?.id, 'narrow');
    });
  });
}
