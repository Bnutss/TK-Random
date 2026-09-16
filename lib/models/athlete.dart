import 'gender.dart';

class Athlete {
  final String id;
  final String fullName;
  final int birthYear;
  final Gender gender;
  final double weightKg;
  final String club;

  const Athlete({
    required this.id,
    required this.fullName,
    required this.birthYear,
    required this.gender,
    required this.weightKg,
    this.club = '',
  });

  Athlete copyWith({
    String? fullName,
    int? birthYear,
    Gender? gender,
    double? weightKg,
    String? club,
  }) {
    return Athlete(
      id: id,
      fullName: fullName ?? this.fullName,
      birthYear: birthYear ?? this.birthYear,
      gender: gender ?? this.gender,
      weightKg: weightKg ?? this.weightKg,
      club: club ?? this.club,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'birthYear': birthYear,
    'gender': gender.code,
    'weightKg': weightKg,
    'club': club,
  };

  factory Athlete.fromJson(Map<String, dynamic> json) => Athlete(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    birthYear: json['birthYear'] as int,
    gender: Gender.fromCode(json['gender'] as String),
    weightKg: (json['weightKg'] as num).toDouble(),
    club: json['club'] as String? ?? '',
  );
}
