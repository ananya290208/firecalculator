class LiabilitiesEmiInputs {
  /// Itemized monthly EMIs in ₹
  final double homeLoanEmi;
  final double carLoanEmi;
  final double personalLoanEmi;
  final double otherLoanEmi;

  /// Optional manual override for total monthly EMI.
  /// If null, totalMonthlyEmi equals the sum of itemized EMIs.
  final double? customTotalMonthlyEmi;

  /// Remaining loan tenure in months (0 - 300)
  final int remainingEmiMonths;

  /// Loan interest rate (% p.a., default: 0.085 = 8.50%)
  final double loanInterestRate;

  /// Total current outstanding principal across all loans (₹, default: 0)
  final double outstandingLoanPrincipal;

  /// Whether EMI payments squeeze/reduce monthly MF SIP investments
  final bool enableSipSqueeze;

  /// Reduced monthly MF SIP during active pre-retirement EMI months (₹, default: 40,000)
  final double reducedMonthlyMfSipDuringEmi;

  /// Discount rate for post-retirement EMI Present Value:
  /// true = inflationRate, false = loanInterestRate
  final bool discountPostRetirementEmiAtInflation;

  const LiabilitiesEmiInputs({
    this.homeLoanEmi = 0.0,
    this.carLoanEmi = 0.0,
    this.personalLoanEmi = 0.0,
    this.otherLoanEmi = 0.0,
    this.customTotalMonthlyEmi,
    this.remainingEmiMonths = 0,
    this.loanInterestRate = 0.0,
    this.outstandingLoanPrincipal = 0.0,
    this.enableSipSqueeze = false,
    this.reducedMonthlyMfSipDuringEmi = 0.0,
    this.discountPostRetirementEmiAtInflation = true,
  });

  /// Computed total monthly EMI (sum of itemized or manual override)
  double get totalMonthlyEmi {
    if (customTotalMonthlyEmi != null && customTotalMonthlyEmi! > 0) {
      return customTotalMonthlyEmi!;
    }
    return homeLoanEmi + carLoanEmi + personalLoanEmi + otherLoanEmi;
  }

  /// Helper display for remaining tenure: e.g. "10 Years 6 Months (126 Mo)"
  String get tenureFormatted {
    if (remainingEmiMonths == 0) return '0 Months (No Debt)';
    final int years = remainingEmiMonths ~/ 12;
    final int months = remainingEmiMonths % 12;
    if (years == 0) return '$months Months';
    if (months == 0) return '$years ${years == 1 ? "Year" : "Years"} ($remainingEmiMonths Mo)';
    return '$years ${years == 1 ? "Yr" : "Yrs"} $months Mo ($remainingEmiMonths Mo)';
  }

  LiabilitiesEmiInputs copyWith({
    double? homeLoanEmi,
    double? carLoanEmi,
    double? personalLoanEmi,
    double? otherLoanEmi,
    double? customTotalMonthlyEmi,
    bool clearCustomTotal = false,
    int? remainingEmiMonths,
    double? loanInterestRate,
    double? outstandingLoanPrincipal,
    bool? enableSipSqueeze,
    double? reducedMonthlyMfSipDuringEmi,
    bool? discountPostRetirementEmiAtInflation,
  }) {
    return LiabilitiesEmiInputs(
      homeLoanEmi: homeLoanEmi ?? this.homeLoanEmi,
      carLoanEmi: carLoanEmi ?? this.carLoanEmi,
      personalLoanEmi: personalLoanEmi ?? this.personalLoanEmi,
      otherLoanEmi: otherLoanEmi ?? this.otherLoanEmi,
      customTotalMonthlyEmi: clearCustomTotal
          ? null
          : (customTotalMonthlyEmi ?? this.customTotalMonthlyEmi),
      remainingEmiMonths: remainingEmiMonths ?? this.remainingEmiMonths,
      loanInterestRate: loanInterestRate ?? this.loanInterestRate,
      outstandingLoanPrincipal:
          outstandingLoanPrincipal ?? this.outstandingLoanPrincipal,
      enableSipSqueeze: enableSipSqueeze ?? this.enableSipSqueeze,
      reducedMonthlyMfSipDuringEmi:
          reducedMonthlyMfSipDuringEmi ?? this.reducedMonthlyMfSipDuringEmi,
      discountPostRetirementEmiAtInflation:
          discountPostRetirementEmiAtInflation ??
              this.discountPostRetirementEmiAtInflation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'homeLoanEmi': homeLoanEmi,
      'carLoanEmi': carLoanEmi,
      'personalLoanEmi': personalLoanEmi,
      'otherLoanEmi': otherLoanEmi,
      'customTotalMonthlyEmi': customTotalMonthlyEmi,
      'remainingEmiMonths': remainingEmiMonths,
      'loanInterestRate': loanInterestRate,
      'outstandingLoanPrincipal': outstandingLoanPrincipal,
      'enableSipSqueeze': enableSipSqueeze,
      'reducedMonthlyMfSipDuringEmi': reducedMonthlyMfSipDuringEmi,
      'discountPostRetirementEmiAtInflation':
          discountPostRetirementEmiAtInflation,
    };
  }

  factory LiabilitiesEmiInputs.fromMap(Map<String, dynamic> map) {
    return LiabilitiesEmiInputs(
      homeLoanEmi: (map['homeLoanEmi'] as num?)?.toDouble() ?? 0.0,
      carLoanEmi: (map['carLoanEmi'] as num?)?.toDouble() ?? 0.0,
      personalLoanEmi: (map['personalLoanEmi'] as num?)?.toDouble() ?? 0.0,
      otherLoanEmi: (map['otherLoanEmi'] as num?)?.toDouble() ?? 0.0,
      customTotalMonthlyEmi:
          (map['customTotalMonthlyEmi'] as num?)?.toDouble(),
      remainingEmiMonths: (map['remainingEmiMonths'] as num?)?.toInt() ?? 0,
      loanInterestRate:
          (map['loanInterestRate'] as num?)?.toDouble() ?? 0.085,
      outstandingLoanPrincipal:
          (map['outstandingLoanPrincipal'] as num?)?.toDouble() ?? 0.0,
      enableSipSqueeze: (map['enableSipSqueeze'] as bool?) ?? false,
      reducedMonthlyMfSipDuringEmi:
          (map['reducedMonthlyMfSipDuringEmi'] as num?)?.toDouble() ?? 40000.0,
      discountPostRetirementEmiAtInflation:
          (map['discountPostRetirementEmiAtInflation'] as bool?) ?? true,
    );
  }
}

class LiabilitiesEmiResults {
  final int retirementMonths;
  final int emiMonthsBeforeRetirement;
  final int postRetirementEmiMonths;
  final double totalMonthlyEmi;
  final double postRetirementEmiPv;
  final double lifestyleFire25x;
  final double lifestyleFire30x;
  final double adjustedFire25x;
  final double adjustedFire30x;
  final double totalCorpus;
  final double surplus25xAdjusted;
  final double surplus30xAdjusted;
  final double unsqueezedMFCorpus;
  final double squeezedMFCorpus;
  final double sipSqueezeCorpusDelta;
  final bool hasPostRetirementEmi;
  final bool isSipSqueezed;

  const LiabilitiesEmiResults({
    required this.retirementMonths,
    required this.emiMonthsBeforeRetirement,
    required this.postRetirementEmiMonths,
    required this.totalMonthlyEmi,
    required this.postRetirementEmiPv,
    required this.lifestyleFire25x,
    required this.lifestyleFire30x,
    required this.adjustedFire25x,
    required this.adjustedFire30x,
    required this.totalCorpus,
    required this.surplus25xAdjusted,
    required this.surplus30xAdjusted,
    required this.unsqueezedMFCorpus,
    required this.squeezedMFCorpus,
    required this.sipSqueezeCorpusDelta,
    required this.hasPostRetirementEmi,
    required this.isSipSqueezed,
  });

  double get postRetirementEmiPvCrores => postRetirementEmiPv / 10000000.0;
  double get adjustedFire25xCrores => adjustedFire25x / 10000000.0;
  double get adjustedFire30xCrores => adjustedFire30x / 10000000.0;
  double get lifestyleFire25xCrores => lifestyleFire25x / 10000000.0;
  double get lifestyleFire30xCrores => lifestyleFire30x / 10000000.0;
  double get totalCorpusCrores => totalCorpus / 10000000.0;
}
