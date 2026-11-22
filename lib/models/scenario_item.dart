import 'fire_inputs.dart';

/// Represents a scenario row from Sheet 2:
/// 'PRE-BUILT RETIREMENT HORIZON & EXPENSE SCENARIO MATRIX'
class ScenarioItem {
  final String name;
  final double horizonYears; // Column C
  final double monthlyExpenseToday; // Column D
  final double projectedCorpusCrores; // Column E
  final double target25xCrores; // Column F
  final double surplus25xCrores; // Column G
  final double target30xCrores; // Column H
  final double surplus30xCrores; // Projected - 30x Target

  const ScenarioItem({
    required this.name,
    required this.horizonYears,
    required this.monthlyExpenseToday,
    required this.projectedCorpusCrores,
    required this.target25xCrores,
    required this.surplus25xCrores,
    required this.target30xCrores,
    required this.surplus30xCrores,
  });

  /// Generate a FireInputs configuration corresponding to this scenario
  FireInputs toFireInputs(FireInputs baseInputs) {
    return baseInputs.copyWith(
      targetYears: horizonYears,
      currentMonthlyExpenses: monthlyExpenseToday,
    );
  }
}
