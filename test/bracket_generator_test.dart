import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tk_random/models/athlete.dart';
import 'package:tk_random/models/bracket.dart';
import 'package:tk_random/models/gender.dart';
import 'package:tk_random/models/weight_class.dart';
import 'package:tk_random/services/bracket_generator.dart';

List<Athlete> _athletes(int n) => List.generate(
  n,
  (i) => Athlete(
    id: 'id$i',
    fullName: 'Athlete $i',
    birthYear: 2011,
    gender: Gender.male,
    weightKg: 50,
  ),
);

final _key = GroupKey(
  ageCategoryId: 'junior',
  ageCategoryLabel: 'Юниор',
  ageCategoryYearRangeLabel: '2010–2012',
  ageCategoryOrder: 1,
  gender: Gender.male,
  weightClass: const WeightClass(baseValue: 51, isOpenTop: false),
);

void main() {
  test('throws when fewer than 2 athletes', () {
    expect(() => generateDraw(_key, _athletes(1)), throwsArgumentError);
  });

  for (final n in [2, 3, 4, 5, 6, 7, 8, 9, 15, 16, 17]) {
    test(
      'n=$n: every participant appears exactly once, byes never face byes',
      () {
        final draw = generateDraw(_key, _athletes(n), random: Random(42));
        final firstRound = draw.rounds.first;

        final bracketSize = firstRound.length * 2;
        expect(bracketSize, greaterThanOrEqualTo(n));
        expect(bracketSize ~/ 2, lessThan(bracketSize)); // sanity

        final seenIds = <String>{};
        var byeCount = 0;
        for (final match in firstRound) {
          expect(
            match.slotA.isBye && match.slotB.isBye,
            isFalse,
            reason: 'no match should be bye-vs-bye',
          );
          for (final slot in [match.slotA, match.slotB]) {
            if (slot.athlete != null) {
              expect(
                seenIds.add(slot.athlete!.id),
                isTrue,
                reason: 'duplicate athlete',
              );
            }
            if (slot.isBye) byeCount++;
          }
        }
        expect(seenIds.length, n);
        expect(byeCount, bracketSize - n);
      },
    );

    test('n=$n: round sizes halve down to a single final match', () {
      final draw = generateDraw(_key, _athletes(n), random: Random(7));
      for (var r = 1; r < draw.rounds.length; r++) {
        expect(draw.rounds[r].length, draw.rounds[r - 1].length ~/ 2);
      }
      expect(draw.rounds.last.length, 1);
    });

    test('n=$n: byes auto-advance into round 2, other slots start empty', () {
      final draw = generateDraw(_key, _athletes(n), random: Random(123));
      if (draw.rounds.length < 2) return;
      final firstRound = draw.rounds[0];
      final secondRound = draw.rounds[1];
      for (var i = 0; i < firstRound.length; i += 2) {
        final left = firstRound[i];
        final right = firstRound[i + 1];
        final nextMatch = secondRound[i ~/ 2];

        BracketSlot expectedFrom(BracketMatch m) {
          if (m.slotA.isBye) return BracketSlot.athlete(m.slotB.athlete);
          if (m.slotB.isBye) return BracketSlot.athlete(m.slotA.athlete);
          return const BracketSlot.empty();
        }

        final expectedA = expectedFrom(left);
        final expectedB = expectedFrom(right);
        expect(nextMatch.slotA.athlete?.id, expectedA.athlete?.id);
        expect(nextMatch.slotB.athlete?.id, expectedB.athlete?.id);
      }
    });
  }
}
