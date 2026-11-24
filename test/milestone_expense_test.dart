import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fire_calculator/controllers/fire_calculator_controller.dart';
import 'package:fire_calculator/models/fire_inputs.dart';
import 'package:fire_calculator/models/liabilities_emi_models.dart';
import 'package:fire_calculator/models/milestone_expense_models.dart';
import 'package:fire_calculator/models/physical_assets_models.dart';
import 'package:fire_calculator/services/dashboard_service.dart';
import 'package:fire_calculator/services/fire_calculator_service.dart';
import 'package:fire_calculator/services/history_service.dart';
import 'package:fire_calculator/services/liabilities_emi_service.dart';
import 'package:fire_calculator/services/physical_assets_service.dart';

void main() {
  group('MilestoneCategory and Extension Tests', () {
    test('Category default titles and amounts are correctly configured', () {
      expect(MilestoneCategory.education.displayName, 'Child Education');
      expect(MilestoneCategory.education.defaultTitle, "Child's Higher Education");
      expect(MilestoneCategory.education.defaultAmount, 3000000.0);

      expect(MilestoneCategory.marriage.displayName, 'Child Marriage');
      expect(MilestoneCategory.marriage.defaultTitle, "Child's Marriage");
      expect(MilestoneCategory.marriage.defaultAmount, 3500000.0);

      expect(MilestoneCategory.housing.displayName, 'Home Renovation / Purchase');
      expect(MilestoneCategory.housing.defaultAmount, 1500000.0);

      expect(MilestoneCategory.vehicle.displayName, 'Vehicle Upgrade');
      expect(MilestoneCategory.travel.displayName, 'Vacation / Travel');
      expect(MilestoneCategory.health.displayName, 'Medical / Family Reserve');
      expect(MilestoneCategory.other.displayName, 'Other Major Expense');
    });
  });

  group('MilestoneExpenseGoal Model Tests', () {
    test('Calculates remaining duration and formatted strings correctly', () {
      final now = DateTime.now();
      final fiveYearsLater = DateTime(now.year + 5, now.month, 15);

      final goal = MilestoneExpenseGoal(
        id: 'test_edu',
        name: "Child's Engineering College",
        category: MilestoneCategory.education,
        targetAmount: 2500000.0,
        endDate: fiveYearsLater,
        notes: '4-year B.Tech fees',
      );

      expect(goal.id, 'test_edu');
      expect(goal.name, "Child's Engineering College");
      expect(goal.category, MilestoneCategory.education);
      expect(goal.targetAmount, 2500000.0);
      expect(goal.monthsRemaining, 60);
      expect(goal.yearsRemaining, closeTo(5.0, 0.1));
      expect(goal.durationFormatted, '5 Years');
      expect(goal.notes, '4-year B.Tech fees');
    });

    test('Required monthly SIP is calculated with compounding sinking fund formula', () {
      final now = DateTime.now();
      // 5 years = 60 months, ₹30,00,000 at 12% p.a.
      final fiveYearsLater = DateTime(now.year + 5, now.month, 1);
      final goal = MilestoneExpenseGoal(
        id: 'test_sip',
        name: 'Higher Ed',
        category: MilestoneCategory.education,
        targetAmount: 3000000.0,
        endDate: fiveYearsLater,
      );

      final sip = goal.requiredMonthlySip(0.12);
      expect(sip, greaterThan(0));
      // At 12% p.a., 60 months: ₹30L requires ~₹36k - ₹37k/mo
      expect(sip, greaterThan(30000.0));
      expect(sip, lessThan(45000.0));
    });

    test('Serialization toMap and fromMap works seamlessly', () {
      final goal = MilestoneExpenseGoal(
        id: 'm1',
        name: 'Daughter Marriage',
        category: MilestoneCategory.marriage,
        targetAmount: 4000000.0,
        endDate: DateTime(2035, 11, 20),
        notes: 'Gold and wedding hall',
      );

      final map = goal.toMap();
      final reconstructed = MilestoneExpenseGoal.fromMap(map);

      expect(reconstructed.id, goal.id);
      expect(reconstructed.name, goal.name);
      expect(reconstructed.category, MilestoneCategory.marriage);
      expect(reconstructed.targetAmount, 4000000.0);
      expect(reconstructed.endDate.year, 2035);
      expect(reconstructed.endDate.month, 11);
      expect(reconstructed.notes, 'Gold and wedding hall');
    });

    test('copyWith properly updates specified fields', () {
      final goal = MilestoneExpenseGoal(
        id: 'g1',
        name: 'Old Name',
        category: MilestoneCategory.other,
        targetAmount: 1000000.0,
        endDate: DateTime(2028, 1, 1),
      );

      final updated = goal.copyWith(
        name: 'New Name',
        targetAmount: 1500000.0,
        category: MilestoneCategory.vehicle,
      );

      expect(updated.id, 'g1');
      expect(updated.name, 'New Name');
      expect(updated.targetAmount, 1500000.0);
      expect(updated.category, MilestoneCategory.vehicle);
      expect(updated.endDate, goal.endDate);
    });
  });

  group('MilestoneExpensesSummary Tests', () {
    test('Empty goals list produces zeroed summary without errors', () {
      final summary = MilestoneExpensesSummary.calculate(
        goals: [],
        retirementYears: 6.0,
      );

      expect(summary.totalTargetAmount, 0.0);
      expect(summary.preRetirementAmount, 0.0);
      expect(summary.postRetirementAmount, 0.0);
      expect(summary.totalMonthlySipNeeded, 0.0);
      expect(summary.count, 0);
    });

    test('Correctly splits pre-retirement vs post-retirement goals', () {
      final now = DateTime.now();
      final retirementYears = 5.0;

      final goal1 = MilestoneExpenseGoal(
        id: 'g1',
        name: 'Pre-Retirement Education',
        category: MilestoneCategory.education,
        targetAmount: 2000000.0,
        endDate: DateTime(now.year + 3, now.month, 1), // 3 years: Pre-retirement
      );

      final goal2 = MilestoneExpenseGoal(
        id: 'g2',
        name: 'Post-Retirement Marriage',
        category: MilestoneCategory.marriage,
        targetAmount: 3500000.0,
        endDate: DateTime(now.year + 8, now.month, 1), // 8 years: Post-retirement
      );

      final summary = MilestoneExpensesSummary.calculate(
        goals: [goal1, goal2],
        retirementYears: retirementYears,
        expectedReturnRate: 0.12,
      );

      expect(summary.count, 2);
      expect(summary.totalTargetAmount, 5500000.0);
      expect(summary.preRetirementAmount, 2000000.0);
      expect(summary.postRetirementAmount, 3500000.0);
      expect(summary.totalMonthlySipNeeded, greaterThan(0.0));
    });
  });

  group('DashboardService Integration with Milestone Expenses', () {
    test('When milestone goals exist, adjustedFire25x and 30x increase by totalMilestoneExpenses', () {
      final inputs = FireInputs.excelDefaults();

      final fireResults = FireCalculatorService.calculate(inputs);
      const emiInputs = LiabilitiesEmiInputs();
      final emiResults = LiabilitiesEmiService.calculate(
        fireInputs: inputs,
        fireResults: fireResults,
        emiInputs: emiInputs,
      );
      const physicalInputs = PhysicalAssetsInputs();
      final physicalResults = PhysicalAssetsService.calculate(
        inputs: physicalInputs,
        targetYears: inputs.targetYears,
      );

      // Baseline with 0 milestone goals
      final summaryBaseline = DashboardService.calculate(
        fireInputs: inputs,
        fireResults: fireResults,
        emiInputs: emiInputs,
        emiResults: emiResults,
        physicalInputs: physicalInputs,
        physicalResults: physicalResults,
        milestoneGoals: [],
      );

      expect(summaryBaseline.totalMilestoneExpenses, 0.0);
      expect(summaryBaseline.hasMilestoneGoals, isFalse);
      expect(summaryBaseline.adjustedFire25x, fireResults.fireTarget25x);
      expect(summaryBaseline.adjustedFire30x, fireResults.fireTarget30x);

      // Add two milestone goals totaling ₹50 Lakhs
      final now = DateTime.now();
      final goals = [
        MilestoneExpenseGoal(
          id: 'edu',
          name: 'Child College',
          category: MilestoneCategory.education,
          targetAmount: 3000000.0,
          endDate: DateTime(now.year + 4, now.month, 1),
        ),
        MilestoneExpenseGoal(
          id: 'marr',
          name: 'Child Marriage',
          category: MilestoneCategory.marriage,
          targetAmount: 2000000.0,
          endDate: DateTime(now.year + 7, now.month, 1),
        ),
      ];

      final summaryWithGoals = DashboardService.calculate(
        fireInputs: inputs,
        fireResults: fireResults,
        emiInputs: emiInputs,
        emiResults: emiResults,
        physicalInputs: physicalInputs,
        physicalResults: physicalResults,
        milestoneGoals: goals,
      );

      expect(summaryWithGoals.totalMilestoneExpenses, 5000000.0);
      expect(summaryWithGoals.hasMilestoneGoals, isTrue);
      expect(summaryWithGoals.milestoneGoalsCount, 2);
      expect(summaryWithGoals.adjustedFire25x, summaryBaseline.adjustedFire25x + 5000000.0);
      expect(summaryWithGoals.adjustedFire30x, summaryBaseline.adjustedFire30x + 5000000.0);
      expect(summaryWithGoals.surplus25x, summaryBaseline.surplus25x - 5000000.0);
      expect(summaryWithGoals.surplus30x, summaryBaseline.surplus30x - 5000000.0);
    });
  });

  group('FireCalculatorController CRUD for Milestone Goals', () {
    late HistoryService historyService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      historyService = HistoryService();
      await historyService.loadHistory();
    });

    test('Adding, updating, and removing milestone goals triggers recalculation', () {
      final controller = FireCalculatorController(historyService: historyService);

      expect(controller.milestoneGoals, isEmpty);
      expect(controller.milestoneSummary.count, 0);
      expect(controller.dashboardSummary.totalMilestoneExpenses, 0.0);

      final now = DateTime.now();
      final goal1 = MilestoneExpenseGoal(
        id: 'g_test_1',
        name: 'Higher Studies',
        category: MilestoneCategory.education,
        targetAmount: 2500000.0,
        endDate: DateTime(now.year + 5, now.month, 1),
      );

      // 1. Add Goal
      controller.addMilestoneGoal(goal1);
      expect(controller.milestoneGoals.length, 1);
      expect(controller.milestoneSummary.totalTargetAmount, 2500000.0);
      expect(controller.dashboardSummary.totalMilestoneExpenses, 2500000.0);

      // 2. Update Goal
      final updatedGoal1 = goal1.copyWith(targetAmount: 3500000.0);
      controller.updateMilestoneGoal(updatedGoal1);
      expect(controller.milestoneGoals.length, 1);
      expect(controller.milestoneSummary.totalTargetAmount, 3500000.0);
      expect(controller.dashboardSummary.totalMilestoneExpenses, 3500000.0);

      // 3. Remove Goal
      controller.removeMilestoneGoal('g_test_1');
      expect(controller.milestoneGoals, isEmpty);
      expect(controller.milestoneSummary.totalTargetAmount, 0.0);
      expect(controller.dashboardSummary.totalMilestoneExpenses, 0.0);

      controller.dispose();
    });

    test('resetToBlank clears all milestone goals', () {
      final controller = FireCalculatorController(historyService: historyService);

      controller.addMilestoneGoal(
        MilestoneExpenseGoal(
          id: 'temp',
          name: 'Renovation',
          category: MilestoneCategory.housing,
          targetAmount: 1500000.0,
          endDate: DateTime.now().add(const Duration(days: 365 * 2)),
        ),
      );
      expect(controller.milestoneGoals.length, 1);

      controller.resetToBlank();
      expect(controller.milestoneGoals, isEmpty);
      expect(controller.dashboardSummary.totalMilestoneExpenses, 0.0);

      controller.dispose();
    });
  });
}
