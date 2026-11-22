import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fire_inputs.dart';
import '../models/fire_results.dart';
import '../models/saved_combination.dart';
import '../utils/currency_formatter.dart';

/// Manages persistence for the user requirement:
/// 'keep last 5 combinations attempted by user for comparison tab or dashboard.'
class HistoryService extends ChangeNotifier {
  static const String _storageKey = 'saved_fire_combinations_history';
  static const int maxCombinations = 5;

  List<SavedCombination> _combinations = [];
  bool _isInitialized = false;

  List<SavedCombination> get combinations => List.unmodifiable(_combinations);
  bool get isInitialized => _isInitialized;

  HistoryService() {
    loadHistory();
  }

  /// Loads stored combinations from SharedPreferences
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList(_storageKey);
      if (jsonList != null) {
        _combinations = jsonList
            .map((itemStr) => SavedCombination.fromJson(itemStr))
            .take(maxCombinations)
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  static int _idCounter = 0;

  /// Saves an attempted combination, maintaining strictly the last 5
  Future<void> recordCombination(
    FireInputs inputs,
    FireResults results, {
    String? customTitle,
  }) async {
    final String title = customTitle ??
        '${inputs.targetYears.toStringAsFixed(0)}Y Horizon • ${CurrencyFormatter.formatCompactINR(inputs.currentMonthlyExpenses)}/mo';

    final newCombination = SavedCombination(
      id: '${DateTime.now().microsecondsSinceEpoch}_${++_idCounter}',
      title: title,
      timestamp: DateTime.now(),
      inputs: inputs,
      projectedCorpusCrores: results.totalCorpusCrores,
      surplus25xCrores: results.surplus25x / 10000000.0,
      surplus30xCrores: results.surplus30x / 10000000.0,
      estPostTaxCorpusCrores: results.estPostTaxCorpusCrores,
    );

    // If an identical combination already exists, remove it first so it moves to top
    _combinations.removeWhere((c) => c.inputs == inputs);

    // Insert at front
    _combinations.insert(0, newCombination);

    // Keep only the last 5 combinations
    if (_combinations.length > maxCombinations) {
      _combinations = _combinations.sublist(0, maxCombinations);
    }

    notifyListeners();
    await _persist();
  }

  /// Removes a specific combination by ID
  Future<void> removeCombination(String id) async {
    _combinations.removeWhere((c) => c.id == id);
    notifyListeners();
    await _persist();
  }

  /// Clears all stored combinations
  Future<void> clearHistory() async {
    _combinations.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList =
          _combinations.map((c) => c.toJson()).toList();
      await prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      debugPrint('Error persisting combinations: $e');
    }
  }
}
