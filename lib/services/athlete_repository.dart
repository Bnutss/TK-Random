import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/athlete.dart';
import '../models/bracket.dart';
import '../models/gender.dart';

class AthleteRepository extends ChangeNotifier {
  static const _uuid = Uuid();

  final List<Athlete> _athletes = [];
  bool _loaded = false;
  File? _file;

  List<Athlete> get athletes => List.unmodifiable(_athletes);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final dir = await getApplicationSupportDirectory();
    _file = File('${dir.path}/athletes.json');
    if (await _file!.exists()) {
      try {
        final raw = await _file!.readAsString();
        final list = jsonDecode(raw) as List;
        _athletes
          ..clear()
          ..addAll(
            list.map((e) => Athlete.fromJson(e as Map<String, dynamic>)),
          );
      } catch (_) {
        // corrupt or unreadable file: start with an empty roster rather than crash
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final file = _file;
    if (file == null) return;
    final raw = jsonEncode(_athletes.map((a) => a.toJson()).toList());
    await file.writeAsString(raw);
  }

  Future<Athlete> add({
    required String fullName,
    required int birthYear,
    required Gender gender,
    required double weightKg,
    String club = '',
  }) async {
    final athlete = Athlete(
      id: _uuid.v4(),
      fullName: fullName,
      birthYear: birthYear,
      gender: gender,
      weightKg: weightKg,
      club: club,
    );
    _athletes.add(athlete);
    await _save();
    notifyListeners();
    return athlete;
  }

  Future<void> update(Athlete updated) async {
    final index = _athletes.indexWhere((a) => a.id == updated.id);
    if (index == -1) return;
    _athletes[index] = updated;
    await _save();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _athletes.removeWhere((a) => a.id == id);
    await _save();
    notifyListeners();
  }

  /// Groups athletes that have a resolvable category and weight class,
  /// sorted by group key. Athletes with an unresolved category are omitted.
  Map<GroupKey, List<Athlete>> groupForDraw() {
    final groups = <GroupKey, List<Athlete>>{};
    for (final athlete in _athletes) {
      final category = athlete.ageCategory;
      final weightClass = athlete.weightClass;
      if (category == null || weightClass == null) continue;
      final key = GroupKey(
        ageCategory: category,
        gender: athlete.gender,
        weightClass: weightClass,
      );
      groups.putIfAbsent(key, () => []).add(athlete);
    }
    final sortedKeys = groups.keys.toList()..sort();
    return {for (final k in sortedKeys) k: groups[k]!};
  }

  List<Athlete> withUnresolvedCategory() =>
      _athletes.where((a) => a.ageCategory == null).toList();
}
