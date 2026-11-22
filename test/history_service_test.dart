import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fire_calculator/controllers/fire_calculator_controller.dart';
import 'package:fire_calculator/models/fire_inputs.dart';
import 'package:fire_calculator/services/history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryService & 5 Combinations Limit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Strictly keeps the last 5 attempted combinations', () async {
      final historyService = HistoryService();
      await historyService.loadHistory();
      final controller = FireCalculatorController(historyService: historyService);

      // Attempt 6 distinct combinations
      for (int i = 1; i <= 6; i++) {
        controller.updateField(
          targetYears: i.toDouble(),
          currentMonthlyExpenses: 100000.0 + (i * 10000.0),
        );
        controller.saveCurrentToHistory(customName: 'Combination #$i');
      }

      // Verify that at most 5 combinations are kept
      expect(historyService.combinations.length, 5);

      // Verify that the newest is at index 0 (#6) and oldest is #2 (since #1 was evicted)
      expect(historyService.combinations.first.title, 'Combination #6');
      expect(historyService.combinations.last.title, 'Combination #2');
    });

    test('Restoring a saved combination updates the controller inputs and results', () async {
      final historyService = HistoryService();
      await historyService.loadHistory();
      final controller = FireCalculatorController(historyService: historyService);

      // Save a custom scenario
      final customInputs = FireInputs.sevenYearStressTest();
      controller.updateInputs(customInputs);
      controller.saveCurrentToHistory(customName: '7Y Stress Test');

      // Change inputs to something else
      controller.resetToExcelDefault();
      expect(controller.inputs.targetYears, 3.0);

      // Restore the 7Y combination from history
      final saved = historyService.combinations.firstWhere((c) => c.title == '7Y Stress Test');
      controller.loadCombination(saved.inputs, saved.title);

      expect(controller.inputs.targetYears, 7.0);
      expect(controller.inputs.currentMonthlyExpenses, 200000.0);
      expect((controller.results.totalCorpusCrores - 10.47).abs(), lessThan(0.05));
    });

    test('Deleting and clearing history works cleanly', () async {
      final historyService = HistoryService();
      await historyService.loadHistory();
      final controller = FireCalculatorController(historyService: historyService);

      controller.saveCurrentToHistory(customName: 'Test 1');
      controller.updateField(targetYears: 5);
      controller.saveCurrentToHistory(customName: 'Test 2');
      expect(historyService.combinations.length, 2);

      // Delete one
      final firstId = historyService.combinations.first.id;
      await historyService.removeCombination(firstId);
      expect(historyService.combinations.length, 1);

      // Clear all
      await historyService.clearHistory();
      expect(historyService.combinations.isEmpty, true);
    });
  });
}
