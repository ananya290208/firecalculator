class DebtShiftTradeoffOption {
  final String title;
  final String description;
  final double equityMFValue;
  final double debtBucketValue;
  final double epfValue;
  final double totalCorpus;
  final double deltaVsAllEquity;
  final String taxImplication;
  final String riskProfile;

  const DebtShiftTradeoffOption({
    required this.title,
    required this.description,
    required this.equityMFValue,
    required this.debtBucketValue,
    required this.epfValue,
    required this.totalCorpus,
    required this.deltaVsAllEquity,
    required this.taxImplication,
    required this.riskProfile,
  });

  double get totalCrores => totalCorpus / 10000000.0;
  double get equityCrores => equityMFValue / 10000000.0;
  double get debtCrores => debtBucketValue / 10000000.0;
  double get epfCrores => epfValue / 10000000.0;
}

class DebtBucketInputs {
  final double initialEquityMF;
  final double redirectedMonthlySIP;
  final double horizonYears;
  final double equityReturnRate;
  final double debtReturnRate;
  final double currentEPF;
  final double monthlyEPF;
  final double epfReturnRate;
  final double capitalShiftAmount;
  final double currentMonthlyExpenses;
  final double expectedInflationRate;

  const DebtBucketInputs({
    this.initialEquityMF = 0.0,
    this.redirectedMonthlySIP = 0.0,
    this.horizonYears = 0.0,
    this.equityReturnRate = 0.0,
    this.debtReturnRate = 0.0,
    this.currentEPF = 0.0,
    this.monthlyEPF = 0.0,
    this.epfReturnRate = 0.0,
    this.capitalShiftAmount = 0.0,
    this.currentMonthlyExpenses = 0.0,
    this.expectedInflationRate = 0.0,
  });

  factory DebtBucketInputs.promptDefaults() => const DebtBucketInputs(
        initialEquityMF: 35000000.0,
        redirectedMonthlySIP: 90000.0,
        horizonYears: 3.0,
        equityReturnRate: 0.12,
        debtReturnRate: 0.07,
        currentEPF: 5000000.0,
        monthlyEPF: 50000.0,
        epfReturnRate: 0.0825,
        capitalShiftAmount: 5000000.0,
        currentMonthlyExpenses: 125000.0,
        expectedInflationRate: 0.06,
      );

  DebtBucketInputs copyWith({
    double? initialEquityMF,
    double? redirectedMonthlySIP,
    double? horizonYears,
    double? equityReturnRate,
    double? debtReturnRate,
    double? currentEPF,
    double? monthlyEPF,
    double? epfReturnRate,
    double? capitalShiftAmount,
    double? currentMonthlyExpenses,
    double? expectedInflationRate,
  }) {
    return DebtBucketInputs(
      initialEquityMF: initialEquityMF ?? this.initialEquityMF,
      redirectedMonthlySIP: redirectedMonthlySIP ?? this.redirectedMonthlySIP,
      horizonYears: horizonYears ?? this.horizonYears,
      equityReturnRate: equityReturnRate ?? this.equityReturnRate,
      debtReturnRate: debtReturnRate ?? this.debtReturnRate,
      currentEPF: currentEPF ?? this.currentEPF,
      monthlyEPF: monthlyEPF ?? this.monthlyEPF,
      epfReturnRate: epfReturnRate ?? this.epfReturnRate,
      capitalShiftAmount: capitalShiftAmount ?? this.capitalShiftAmount,
      currentMonthlyExpenses: currentMonthlyExpenses ?? this.currentMonthlyExpenses,
      expectedInflationRate: expectedInflationRate ?? this.expectedInflationRate,
    );
  }
}

class DebtBucketResults {
  final DebtBucketInputs inputs;
  final int horizonMonths;
  final double existingEquityCorpus;
  final double accumulatedDebtBucket;
  final double projectedEPF;
  final double totalCombinedCorpus;
  final double allEquitySIPTotal;
  final double deltaVsAllEquity;
  final double fireTarget25x;
  final double fireTarget30x;
  final List<DebtShiftTradeoffOption> tradeoffOptions;

  const DebtBucketResults({
    required this.inputs,
    required this.horizonMonths,
    required this.existingEquityCorpus,
    required this.accumulatedDebtBucket,
    required this.projectedEPF,
    required this.totalCombinedCorpus,
    required this.allEquitySIPTotal,
    required this.deltaVsAllEquity,
    required this.fireTarget25x,
    required this.fireTarget30x,
    required this.tradeoffOptions,
  });

  double get totalCombinedCrores => totalCombinedCorpus / 10000000.0;
  double get existingEquityCrores => existingEquityCorpus / 10000000.0;
  double get accumulatedDebtCrores => accumulatedDebtBucket / 10000000.0;
  double get projectedEPFCrores => projectedEPF / 10000000.0;
  double get allEquitySIPCrores => allEquitySIPTotal / 10000000.0;

  double get equityPct =>
      totalCombinedCorpus > 0 ? (existingEquityCorpus / totalCombinedCorpus) * 100.0 : 0.0;
  double get debtPct =>
      totalCombinedCorpus > 0 ? (accumulatedDebtBucket / totalCombinedCorpus) * 100.0 : 0.0;
  double get epfPct =>
      totalCombinedCorpus > 0 ? (projectedEPF / totalCombinedCorpus) * 100.0 : 0.0;
}
