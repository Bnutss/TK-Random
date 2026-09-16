import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/age_category.dart';
import '../models/gender.dart';

/// Owns the editable list of age categories (each with its own weight-class
/// boundaries per gender). Persisted locally so custom categories survive a
/// restart, same as athletes and tournament history.
class CategoryRepository extends ChangeNotifier {
  static const _uuid = Uuid();

  final List<AgeCategoryDef> _categories = [];
  bool _loaded = false;
  File? _file;

  CategoryRepository();

  /// Starts already populated with [categories] and without touching disk.
  /// Useful for widget tests that don't want real file I/O via [load].
  CategoryRepository.seeded(List<AgeCategoryDef> categories) {
    _categories.addAll(categories);
    _loaded = true;
  }

  List<AgeCategoryDef> get categories => List.unmodifiable(_categories);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final dir = await getApplicationSupportDirectory();
    _file = File('${dir.path}/categories.json');
    if (await _file!.exists()) {
      try {
        final raw = await _file!.readAsString();
        final list = jsonDecode(raw) as List;
        _categories
          ..clear()
          ..addAll(
            list.map((e) => AgeCategoryDef.fromJson(e as Map<String, dynamic>)),
          );
      } catch (_) {
        // corrupt or unreadable file: fall through to seeding defaults
      }
    }
    if (_categories.isEmpty) {
      _categories.addAll(defaultAgeCategories());
      await _save();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final file = _file;
    if (file == null) return;
    final raw = jsonEncode(_categories.map((c) => c.toJson()).toList());
    await file.writeAsString(raw);
  }

  Future<AgeCategoryDef> add({
    required String label,
    required int? minYear,
    required int? maxYear,
    required Map<Gender, List<double>> weightBoundsByGender,
  }) async {
    final category = AgeCategoryDef(
      id: _uuid.v4(),
      label: label,
      minYear: minYear,
      maxYear: maxYear,
      weightBoundsByGender: weightBoundsByGender,
    );
    _categories.add(category);
    await _save();
    notifyListeners();
    return category;
  }

  Future<void> update(AgeCategoryDef updated) async {
    final index = _categories.indexWhere((c) => c.id == updated.id);
    if (index == -1) return;
    _categories[index] = updated;
    await _save();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _categories.removeWhere((c) => c.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> move(String id, int delta) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final target = index + delta;
    if (target < 0 || target >= _categories.length) return;
    final item = _categories.removeAt(index);
    _categories.insert(target, item);
    await _save();
    notifyListeners();
  }

  AgeCategoryDef? resolveAgeCategory(int birthYear) =>
      resolveAgeCategoryFrom(_categories, birthYear);
}
