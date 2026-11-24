import 'milestone_expense_models.dart';

class AssetAllocationSlice {
  final String label;
  final double amount;
  final double percentage;
  final int colorValue; // ARGB integer

  const AssetAllocationSlice({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.colorValue,
  });
}

class ComprehensiveFireSummary {
  // 1. Net Worth Today
  final double totalFinancialAssets;
  final double totalRealEstateAssets;
  final double totalGoldAssets;
  final double totalCashAssets;
  final double totalGrossAssets;
  final double totalOutstandingLiabilities;
  final double totalNetWorth;

  // 2. Projected Retirement Horizon
  final double targetYears;
  final double projectedMFCorpus;
  final double projectedEPFCorpus;
  final double baselineFinancialCorpus; // MF + EPF
  final double additionalLiquidAssets; // Gold, Cash, Monetized properties
  final double totalProjectedFireCorpus;

  // 3. Cashflow & Living Expenses at Retirement
  final double futureMonthlyExpenses;
  final double futureGrossAnnualExpenses;
  final double annualRentalIncome;
  final double netAnnualExpenseDrawdown;

  // 4. FIRE Targets
  final double postRetirementEmiPv;
  final double lifestyleFire25x;
  final double lifestyleFire30x;
  final double adjustedFire25x;
  final double adjustedFire30x;

  // 4b. Milestone Expense Goals (Child education, marriage, large capital goals)
  final double totalMilestoneExpenses;
  final double preRetirementMilestones;
  final double postRetirementMilestones;
  final int milestoneGoalsCount;
  final List<MilestoneExpenseGoal> milestoneGoals;
  final double milestoneMonthlySipNeeded;

  // 5. Surplus / Shortfall
  final double surplus25x;
  final double surplus30x;
  final double fundingPercentage25x;
  final double fundingPercentage30x;
  final String readinessStatus;

  // 6. Asset Allocation
  final List<AssetAllocationSlice> allocationSlices;

  const ComprehensiveFireSummary({
    required this.totalFinancialAssets,
    required this.totalRealEstateAssets,
    required this.totalGoldAssets,
    required this.totalCashAssets,
    required this.totalGrossAssets,
    required this.totalOutstandingLiabilities,
    required this.totalNetWorth,
    required this.targetYears,
    required this.projectedMFCorpus,
    required this.projectedEPFCorpus,
    required this.baselineFinancialCorpus,
    required this.additionalLiquidAssets,
    required this.totalProjectedFireCorpus,
    required this.futureMonthlyExpenses,
    required this.futureGrossAnnualExpenses,
    required this.annualRentalIncome,
    required this.netAnnualExpenseDrawdown,
    required this.postRetirementEmiPv,
    required this.lifestyleFire25x,
    required this.lifestyleFire30x,
    required this.adjustedFire25x,
    required this.adjustedFire30x,
    this.totalMilestoneExpenses = 0.0,
    this.preRetirementMilestones = 0.0,
    this.postRetirementMilestones = 0.0,
    this.milestoneGoalsCount = 0,
    this.milestoneGoals = const [],
    this.milestoneMonthlySipNeeded = 0.0,
    required this.surplus25x,
    required this.surplus30x,
    required this.fundingPercentage25x,
    required this.fundingPercentage30x,
    required this.readinessStatus,
    required this.allocationSlices,
  });

  bool get isFireReady => surplus30x >= 0;
  bool get hasRentalIncome => annualRentalIncome > 0;
  bool get hasDebtOverhang => postRetirementEmiPv > 0;
  bool get hasMilestoneGoals => totalMilestoneExpenses > 0;
}
