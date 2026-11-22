import 'dart:convert';

/// Represents all 12 input parameters from Section 1 of the Excel model:
/// '1. YOUR INPUTS & ASSUMPTIONS (EDIT YELLOW CELLS)'
class FireInputs {
  /// Target Years to Retirement (Cell C6, e.g., 3, 5, 6, 7)
  final double targetYears;

  /// Current Monthly Expenses (Today) in ₹ (Cell C7, e.g., 125,000 or 200,000)
  final double currentMonthlyExpenses;

  /// Expected Inflation Rate (% p.a.) (Cell C8, e.g., 0.06 = 6.00%)
  final double expectedInflationRate;

  /// Current Mutual Fund Value in ₹ (Cell C9, e.g., 35,000,000)
  final double currentMFValue;

  /// Current MF Cost Basis in ₹ (Cell C10, e.g., 21,000,000)
  final double currentMFCostBasis;

  /// Monthly Mutual Fund SIP in ₹ (Cell C11, e.g., 90,000)
  final double monthlyMFSIP;

  /// Expected MF Return (% p.a.) (Cell C12, e.g., 0.12 = 12.00%)
  final double expectedMFReturn;

  /// Current EPF Balance in ₹ (Cell C13, e.g., 5,000,000)
  final double currentEPFBalance;

  /// Monthly EPF Contribution in ₹ (Cell C14, e.g., 50,000)
  final double monthlyEPFContribution;

  /// Expected EPF Return (% p.a.) (Cell C15, e.g., 0.0825 = 8.25%)
  final double expectedEPFReturn;

  /// Upfront MF Cash-Out / Withdrawal (%) (Cell C16, e.g., 0.00 = 0%)
  final double upfrontMFCashOutRate;

  /// LTCG Tax Rate on Equity Gains (%) (Cell C17, e.g., 0.125 = 12.50%)
  final double ltcgTaxRate;

  const FireInputs({
    this.targetYears = 0.0,
    this.currentMonthlyExpenses = 0.0,
    this.expectedInflationRate = 0.0,
    this.currentMFValue = 0.0,
    this.currentMFCostBasis = 0.0,
    this.monthlyMFSIP = 0.0,
    this.expectedMFReturn = 0.0,
    this.currentEPFBalance = 0.0,
    this.monthlyEPFContribution = 0.0,
    this.expectedEPFReturn = 0.0,
    this.upfrontMFCashOutRate = 0.0,
    this.ltcgTaxRate = 0.0,
  });

  /// Factory for standard Excel defaults
  factory FireInputs.excelDefaults() => const FireInputs(
        targetYears: 3.0,
        currentMonthlyExpenses: 125000.0,
        expectedInflationRate: 0.06,
        currentMFValue: 35000000.0,
        currentMFCostBasis: 21000000.0,
        monthlyMFSIP: 90000.0,
        expectedMFReturn: 0.12,
        currentEPFBalance: 5000000.0,
        monthlyEPFContribution: 50000.0,
        expectedEPFReturn: 0.0825,
        upfrontMFCashOutRate: 0.0,
        ltcgTaxRate: 0.125,
      );

  /// Factory for the 7-Year Horizon ₹2 Lakh/mo Stress-Test Scenario from report
  factory FireInputs.sevenYearStressTest() => const FireInputs(
        targetYears: 7.0,
        currentMonthlyExpenses: 200000.0,
        expectedInflationRate: 0.06,
        currentMFValue: 34000000.0,
        currentMFCostBasis: 21000000.0,
        monthlyMFSIP: 90000.0,
        expectedMFReturn: 0.12,
        currentEPFBalance: 5000000.0,
        monthlyEPFContribution: 50000.0,
        expectedEPFReturn: 0.0825,
        upfrontMFCashOutRate: 0.0,
        ltcgTaxRate: 0.125,
      );

  FireInputs copyWith({
    double? targetYears,
    double? currentMonthlyExpenses,
    double? expectedInflationRate,
    double? currentMFValue,
    double? currentMFCostBasis,
    double? monthlyMFSIP,
    double? expectedMFReturn,
    double? currentEPFBalance,
    double? monthlyEPFContribution,
    double? expectedEPFReturn,
    double? upfrontMFCashOutRate,
    double? ltcgTaxRate,
  }) {
    return FireInputs(
      targetYears: targetYears ?? this.targetYears,
      currentMonthlyExpenses:
          currentMonthlyExpenses ?? this.currentMonthlyExpenses,
      expectedInflationRate:
          expectedInflationRate ?? this.expectedInflationRate,
      currentMFValue: currentMFValue ?? this.currentMFValue,
      currentMFCostBasis: currentMFCostBasis ?? this.currentMFCostBasis,
      monthlyMFSIP: monthlyMFSIP ?? this.monthlyMFSIP,
      expectedMFReturn: expectedMFReturn ?? this.expectedMFReturn,
      currentEPFBalance: currentEPFBalance ?? this.currentEPFBalance,
      monthlyEPFContribution:
          monthlyEPFContribution ?? this.monthlyEPFContribution,
      expectedEPFReturn: expectedEPFReturn ?? this.expectedEPFReturn,
      upfrontMFCashOutRate: upfrontMFCashOutRate ?? this.upfrontMFCashOutRate,
      ltcgTaxRate: ltcgTaxRate ?? this.ltcgTaxRate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetYears': targetYears,
      'currentMonthlyExpenses': currentMonthlyExpenses,
      'expectedInflationRate': expectedInflationRate,
      'currentMFValue': currentMFValue,
      'currentMFCostBasis': currentMFCostBasis,
      'monthlyMFSIP': monthlyMFSIP,
      'expectedMFReturn': expectedMFReturn,
      'currentEPFBalance': currentEPFBalance,
      'monthlyEPFContribution': monthlyEPFContribution,
      'expectedEPFReturn': expectedEPFReturn,
      'upfrontMFCashOutRate': upfrontMFCashOutRate,
      'ltcgTaxRate': ltcgTaxRate,
    };
  }

  factory FireInputs.fromMap(Map<String, dynamic> map) {
    return FireInputs(
      targetYears: (map['targetYears'] as num?)?.toDouble() ?? 3.0,
      currentMonthlyExpenses:
          (map['currentMonthlyExpenses'] as num?)?.toDouble() ?? 125000.0,
      expectedInflationRate:
          (map['expectedInflationRate'] as num?)?.toDouble() ?? 0.06,
      currentMFValue:
          (map['currentMFValue'] as num?)?.toDouble() ?? 35000000.0,
      currentMFCostBasis:
          (map['currentMFCostBasis'] as num?)?.toDouble() ?? 21000000.0,
      monthlyMFSIP: (map['monthlyMFSIP'] as num?)?.toDouble() ?? 90000.0,
      expectedMFReturn:
          (map['expectedMFReturn'] as num?)?.toDouble() ?? 0.12,
      currentEPFBalance:
          (map['currentEPFBalance'] as num?)?.toDouble() ?? 5000000.0,
      monthlyEPFContribution:
          (map['monthlyEPFContribution'] as num?)?.toDouble() ?? 50000.0,
      expectedEPFReturn:
          (map['expectedEPFReturn'] as num?)?.toDouble() ?? 0.0825,
      upfrontMFCashOutRate:
          (map['upfrontMFCashOutRate'] as num?)?.toDouble() ?? 0.0,
      ltcgTaxRate: (map['ltcgTaxRate'] as num?)?.toDouble() ?? 0.125,
    );
  }

  String toJson() => json.encode(toMap());

  factory FireInputs.fromJson(String source) =>
      FireInputs.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FireInputs &&
        other.targetYears == targetYears &&
        other.currentMonthlyExpenses == currentMonthlyExpenses &&
        other.expectedInflationRate == expectedInflationRate &&
        other.currentMFValue == currentMFValue &&
        other.currentMFCostBasis == currentMFCostBasis &&
        other.monthlyMFSIP == monthlyMFSIP &&
        other.expectedMFReturn == expectedMFReturn &&
        other.currentEPFBalance == currentEPFBalance &&
        other.monthlyEPFContribution == monthlyEPFContribution &&
        other.expectedEPFReturn == expectedEPFReturn &&
        other.upfrontMFCashOutRate == upfrontMFCashOutRate &&
        other.ltcgTaxRate == ltcgTaxRate;
  }

  @override
  int get hashCode => Object.hash(
        targetYears,
        currentMonthlyExpenses,
        expectedInflationRate,
        currentMFValue,
        currentMFCostBasis,
        monthlyMFSIP,
        expectedMFReturn,
        currentEPFBalance,
        monthlyEPFContribution,
        expectedEPFReturn,
        upfrontMFCashOutRate,
        ltcgTaxRate,
      );
}
