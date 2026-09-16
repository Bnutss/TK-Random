import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/bracket.dart';

class TournamentRepository extends ChangeNotifier {
  static const _uuid = Uuid();

  final List<Tournament> _tournaments = [];
  bool _loaded = false;
  File? _file;

  List<Tournament> get tournaments => List.unmodifiable(_tournaments.reversed);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final dir = await getApplicationSupportDirectory();
    _file = File('${dir.path}/tournaments.json');
    if (await _file!.exists()) {
      try {
        final raw = await _file!.readAsString();
        final list = jsonDecode(raw) as List;
        _tournaments
          ..clear()
          ..addAll(
            list.map((e) => Tournament.fromJson(e as Map<String, dynamic>)),
          );
      } catch (_) {
        // corrupt or unreadable file: start with empty history rather than crash
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final file = _file;
    if (file == null) return;
    final raw = jsonEncode(_tournaments.map((t) => t.toJson()).toList());
    await file.writeAsString(raw);
  }

  Future<Tournament> save({
    required String name,
    required DateTime date,
    required List<WeightGroupDraw> groups,
  }) async {
    final tournament = Tournament(
      id: _uuid.v4(),
      name: name,
      date: date,
      createdAt: DateTime.now(),
      groups: groups,
    );
    _tournaments.add(tournament);
    await _save();
    notifyListeners();
    return tournament;
  }

  Future<void> delete(String id) async {
    _tournaments.removeWhere((t) => t.id == id);
    await _save();
    notifyListeners();
  }
}
