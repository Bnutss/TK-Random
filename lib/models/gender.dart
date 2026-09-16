enum Gender {
  male,
  female;

  String get label => switch (this) {
    Gender.male => 'М',
    Gender.female => 'Ж',
  };

  String get code => switch (this) {
    Gender.male => 'm',
    Gender.female => 'f',
  };

  static Gender fromCode(String code) =>
      code == 'm' ? Gender.male : Gender.female;
}
