import 'age_category.dart';
import 'athlete.dart';
import 'gender.dart';
import 'weight_class.dart';

/// Identifies one (age category × gender × weight class) drawing group.
class GroupKey implements Comparable<GroupKey> {
  final AgeCategory ageCategory;
  final Gender gender;
  final WeightClass weightClass;

  const GroupKey({
    required this.ageCategory,
    required this.gender,
    required this.weightClass,
  });

  String get label =>
      '${ageCategory.label} · ${gender.label} · до ${weightClass.label} кг';

  @override
  int compareTo(GroupKey other) {
    final byCategory = ageCategory.index.compareTo(other.ageCategory.index);
    if (byCategory != 0) return byCategory;
    final byGender = gender.index.compareTo(other.gender.index);
    if (byGender != 0) return byGender;
    return weightClass.compareTo(other.weightClass);
  }

  @override
  bool operator ==(Object other) =>
      other is GroupKey &&
      other.ageCategory == ageCategory &&
      other.gender == gender &&
      other.weightClass == weightClass;

  @override
  int get hashCode => Object.hash(ageCategory, gender, weightClass);

  Map<String, dynamic> toJson() => {
    'ageCategory': ageCategory.name,
    'gender': gender.code,
    'weightBase': weightClass.baseValue,
    'weightOpen': weightClass.isOpenTop,
  };

  factory GroupKey.fromJson(Map<String, dynamic> json) => GroupKey(
    ageCategory: AgeCategory.values.byName(json['ageCategory'] as String),
    gender: Gender.fromCode(json['gender'] as String),
    weightClass: WeightClass(
      baseValue: (json['weightBase'] as num).toDouble(),
      isOpenTop: json['weightOpen'] as bool,
    ),
  );
}

/// One position in a bracket match: either a drawn athlete, a bye (the
/// opposing athlete auto-advances), or empty (to be filled once an earlier
/// match is fought and the result is recorded by hand).
class BracketSlot {
  final Athlete? athlete;
  final bool isBye;

  const BracketSlot.athlete(this.athlete) : isBye = false;
  const BracketSlot.bye() : athlete = null, isBye = true;
  const BracketSlot.empty() : athlete = null, isBye = false;

  bool get isEmpty => athlete == null && !isBye;

  Map<String, dynamic> toJson() => {
    'athlete': athlete?.toJson(),
    'isBye': isBye,
  };

  factory BracketSlot.fromJson(Map<String, dynamic> json) {
    final athleteJson = json['athlete'] as Map<String, dynamic>?;
    if (athleteJson != null) {
      return BracketSlot.athlete(Athlete.fromJson(athleteJson));
    }
    if (json['isBye'] as bool) return const BracketSlot.bye();
    return const BracketSlot.empty();
  }
}

class BracketMatch {
  final int round;
  final int indexInRound;
  final BracketSlot slotA;
  final BracketSlot slotB;

  const BracketMatch({
    required this.round,
    required this.indexInRound,
    required this.slotA,
    required this.slotB,
  });

  Map<String, dynamic> toJson() => {
    'round': round,
    'indexInRound': indexInRound,
    'slotA': slotA.toJson(),
    'slotB': slotB.toJson(),
  };

  factory BracketMatch.fromJson(Map<String, dynamic> json) => BracketMatch(
    round: json['round'] as int,
    indexInRound: json['indexInRound'] as int,
    slotA: BracketSlot.fromJson(json['slotA'] as Map<String, dynamic>),
    slotB: BracketSlot.fromJson(json['slotB'] as Map<String, dynamic>),
  );
}

/// A generated single-elimination draw for one weight group.
class WeightGroupDraw {
  final GroupKey key;
  final List<Athlete> participants;
  final List<List<BracketMatch>> rounds;
  final DateTime generatedAt;

  const WeightGroupDraw({
    required this.key,
    required this.participants,
    required this.rounds,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
    'key': key.toJson(),
    'participants': participants.map((a) => a.toJson()).toList(),
    'rounds': rounds
        .map((round) => round.map((m) => m.toJson()).toList())
        .toList(),
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory WeightGroupDraw.fromJson(Map<String, dynamic> json) =>
      WeightGroupDraw(
        key: GroupKey.fromJson(json['key'] as Map<String, dynamic>),
        participants: (json['participants'] as List)
            .map((e) => Athlete.fromJson(e as Map<String, dynamic>))
            .toList(),
        rounds: (json['rounds'] as List)
            .map(
              (round) => (round as List)
                  .map((m) => BracketMatch.fromJson(m as Map<String, dynamic>))
                  .toList(),
            )
            .toList(),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}

/// A saved batch of draws generated together, kept for history/reprinting.
class Tournament {
  final String id;
  final String name;
  final DateTime date;
  final DateTime createdAt;
  final List<WeightGroupDraw> groups;

  const Tournament({
    required this.id,
    required this.name,
    required this.date,
    required this.createdAt,
    required this.groups,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'groups': groups.map((g) => g.toJson()).toList(),
  };

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
    id: json['id'] as String,
    name: json['name'] as String,
    date: DateTime.parse(json['date'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    groups: (json['groups'] as List)
        .map((g) => WeightGroupDraw.fromJson(g as Map<String, dynamic>))
        .toList(),
  );
}
