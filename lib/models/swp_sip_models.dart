class MonthlyTrajectoryPoint {
  final int month;
  final int year;
  final double swpRemaining;
  final double sipAccumulated;
  final double combinedMF;
  final double stayInvestedMF;

  const MonthlyTrajectoryPoint({
    required this.month,
    required this.year,
    required this.swpRemaining,
    required this.sipAccumulated,
    required this.combinedMF,
    required this.stayInvestedMF,
  });
}

class SwpSipInputs {
  final double initialMFCorpus;
  final double monthlySwpAmount;
  final double horizonYears;
  final double swpBucketReturn;
  final double sipBucketReturn;
  final double baselineReturn;
  final double baselineSIP;
  final double currentEPF;
  final double monthlyEPF;
  final double epfReturn;
  final double currentCostBasis;
  final double ltcgTaxRate;
  final double currentMonthlyExpenses;
  final double expectedInflationRate;

  const SwpSipInputs({
    this.initialMFCorpus = 0.0,
    this.monthlySwpAmount = 0.0,
    this.horizonYears = 0.0,
    this.swpBucketReturn = 0.0,
    this.sipBucketReturn = 0.0,
    this.baselineReturn = 0.0,
    this.baselineSIP = 0.0,
    this.currentEPF = 0.0,
    this.monthlyEPF = 0.0,
    this.epfReturn = 0.0,
    this.currentCostBasis = 0.0,
    this.ltcgTaxRate = 0.0,
    this.currentMonthlyExpenses = 0.0,
    this.expectedInflationRate = 0.0,
  });

  factory SwpSipInputs.promptDefaults() => const SwpSipInputs(
        initialMFCorpus: 35000000.0,
        monthlySwpAmount: 175000.0,
        horizonYears: 6.0,
        swpBucketReturn: 0.09,
        sipBucketReturn: 0.12,
        baselineReturn: 0.12,
        baselineSIP: 90000.0,
        currentEPF: 5000000.0,
        monthlyEPF: 50000.0,
        epfReturn: 0.0825,
        currentCostBasis: 21000000.0,
        ltcgTaxRate: 0.125,
        currentMonthlyExpenses: 125000.0,
        expectedInflationRate: 0.06,
      );

  SwpSipInputs copyWith({
    double? initialMFCorpus,
    double? monthlySwpAmount,
    double? horizonYears,
    double? swpBucketReturn,
    double? sipBucketReturn,
    double? baselineReturn,
    double? baselineSIP,
    double? currentEPF,
    double? monthlyEPF,
    double? epfReturn,
    double? currentCostBasis,
    double? ltcgTaxRate,
    double? currentMonthlyExpenses,
    double? expectedInflationRate,
  }) {
    return SwpSipInputs(
      initialMFCorpus: initialMFCorpus ?? this.initialMFCorpus,
      monthlySwpAmount: monthlySwpAmount ?? this.monthlySwpAmount,
      horizonYears: horizonYears ?? this.horizonYears,
      swpBucketReturn: swpBucketReturn ?? this.swpBucketReturn,
      sipBucketReturn: sipBucketReturn ?? this.sipBucketReturn,
      baselineReturn: baselineReturn ?? this.baselineReturn,
      baselineSIP: baselineSIP ?? this.baselineSIP,
      currentEPF: currentEPF ?? this.currentEPF,
      monthlyEPF: monthlyEPF ?? this.monthlyEPF,
      epfReturn: epfReturn ?? this.epfReturn,
      currentCostBasis: currentCostBasis ?? this.currentCostBasis,
      ltcgTaxRate: ltcgTaxRate ?? this.ltcgTaxRate,
      currentMonthlyExpenses: currentMonthlyExpenses ?? this.currentMonthlyExpenses,
      expectedInflationRate: expectedInflationRate ?? this.expectedInflationRate,
    );
  }
}

class SwpSipScenarioResult {
  final String title;
  final double swpRate;
  final double sipRate;
  final double swpRemainingBalance;
  final double sipAccumulatedBalance;
  final double combinedMFCorpus;
  final double projectedEPF;
  final double combinedTotalCorpus;
  final double deltaVsStayInvested;
  final double surplus25x;
  final double surplus30x;
  final String upfrontLTCGTaxNote;
  final bool isBaseline;

  const SwpSipScenarioResult({
    required this.title,
    required this.swpRate,
    required this.sipRate,
    required this.swpRemainingBalance,
    required this.sipAccumulatedBalance,
    required this.combinedMFCorpus,
    required this.projectedEPF,
    required this.combinedTotalCorpus,
    required this.deltaVsStayInvested,
    required this.surplus25x,
    required this.surplus30x,
    required this.upfrontLTCGTaxNote,
    this.isBaseline = false,
  });

  double get combinedTotalCrores => combinedTotalCorpus / 10000000.0;
  double get combinedMFCrores => combinedMFCorpus / 10000000.0;
  double get swpRemainingCrores => swpRemainingBalance / 10000000.0;
  double get sipAccumulatedCrores => sipAccumulatedBalance / 10000000.0;
}

class SwpSipComparisonResults {
  final SwpSipInputs inputs;
  final int horizonMonths;
  final double fireTarget25x;
  final double fireTarget30x;
  final double upfrontCashoutLtcgTax;
  final SwpSipScenarioResult baselineResult;
  final List<SwpSipScenarioResult> scenarios;
  final List<MonthlyTrajectoryPoint> trajectory;

  const SwpSipComparisonResults({
    required this.inputs,
    required this.horizonMonths,
    required this.fireTarget25x,
    required this.fireTarget30x,
    required this.upfrontCashoutLtcgTax,
    required this.baselineResult,
    required this.scenarios,
    required this.trajectory,
  });
}
