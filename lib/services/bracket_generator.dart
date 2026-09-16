import 'dart:math';

import '../models/athlete.dart';
import '../models/bracket.dart';

/// Builds a random single-elimination draw for one weight group.
///
/// Byes are spread one-per-first-round-match (never bye-vs-bye): with
/// `n` participants and `bracketSize` the next power of two ≥ n, the
/// number of byes is always `< bracketSize / 2`, so there are always at
/// least as many real first-round matches as byes.
WeightGroupDraw generateDraw(
  GroupKey key,
  List<Athlete> athletes, {
  Random? random,
}) {
  if (athletes.length < 2) {
    throw ArgumentError('Need at least 2 athletes to generate a draw');
  }
  final rng = random ?? Random();
  final shuffled = List<Athlete>.of(athletes)..shuffle(rng);

  final n = shuffled.length;
  final bracketSize = _nextPowerOfTwo(n);
  final pairCount = bracketSize ~/ 2;
  final byeCount = bracketSize - n;

  final pairIndexes = List<int>.generate(pairCount, (i) => i)..shuffle(rng);
  final byePairs = pairIndexes.take(byeCount).toSet();

  final firstRound = <BracketMatch>[];
  var cursor = 0;
  for (var pairIndex = 0; pairIndex < pairCount; pairIndex++) {
    if (byePairs.contains(pairIndex)) {
      final athlete = shuffled[cursor++];
      firstRound.add(
        BracketMatch(
          round: 0,
          indexInRound: pairIndex,
          slotA: BracketSlot.athlete(athlete),
          slotB: const BracketSlot.bye(),
        ),
      );
    } else {
      final a = shuffled[cursor++];
      final b = shuffled[cursor++];
      firstRound.add(
        BracketMatch(
          round: 0,
          indexInRound: pairIndex,
          slotA: BracketSlot.athlete(a),
          slotB: BracketSlot.athlete(b),
        ),
      );
    }
  }

  final rounds = <List<BracketMatch>>[firstRound];
  var previousRound = firstRound;
  var roundIndex = 1;
  while (previousRound.length > 1) {
    final nextRound = <BracketMatch>[];
    for (var i = 0; i < previousRound.length; i += 2) {
      final left = previousRound[i];
      final right = previousRound[i + 1];
      final leftAutoAdvance = _autoAdvance(left);
      final rightAutoAdvance = _autoAdvance(right);
      nextRound.add(
        BracketMatch(
          round: roundIndex,
          indexInRound: i ~/ 2,
          slotA: leftAutoAdvance ?? const BracketSlot.empty(),
          slotB: rightAutoAdvance ?? const BracketSlot.empty(),
        ),
      );
    }
    rounds.add(nextRound);
    previousRound = nextRound;
    roundIndex++;
  }

  return WeightGroupDraw(
    key: key,
    participants: shuffled,
    rounds: rounds,
    generatedAt: DateTime.now(),
  );
}

/// If [match] was a bye, the real athlete auto-advances into the next
/// round's slot; otherwise the next round starts empty pending the result.
BracketSlot? _autoAdvance(BracketMatch match) {
  if (match.slotB.isBye) return BracketSlot.athlete(match.slotA.athlete);
  if (match.slotA.isBye) return BracketSlot.athlete(match.slotB.athlete);
  return null;
}

int _nextPowerOfTwo(int n) {
  var size = 1;
  while (size < n) {
    size *= 2;
  }
  return size;
}
