enum AgeCategory {
  adult,
  junior,
  cadet,
  childChallenger;

  String get label => switch (this) {
    AgeCategory.adult => 'Взрослый',
    AgeCategory.junior => 'Юниор',
    AgeCategory.cadet => 'Кадет',
    AgeCategory.childChallenger => 'Дети челленджер',
  };

  String get yearRangeLabel => switch (this) {
    AgeCategory.adult => '2009 и старше',
    AgeCategory.junior => '2010–2012',
    AgeCategory.cadet => '2013–2015',
    AgeCategory.childChallenger => '2016–2017',
  };
}

/// Returns null when the birth year falls outside every defined category.
AgeCategory? resolveAgeCategory(int birthYear) {
  if (birthYear <= 2009) return AgeCategory.adult;
  if (birthYear >= 2010 && birthYear <= 2012) return AgeCategory.junior;
  if (birthYear >= 2013 && birthYear <= 2015) return AgeCategory.cadet;
  if (birthYear >= 2016 && birthYear <= 2017) {
    return AgeCategory.childChallenger;
  }
  return null;
}
