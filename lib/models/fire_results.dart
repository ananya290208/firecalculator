/// Data structure for a single year in Section 3 of Excel:
/// '3. YEAR-BY-YEAR PROJECTION SCHEDULE (YEARS 0 TO 10)'
class YearlyProjection {
  final int year;
  final double projectedMF; // Cell C21:C31
  final double projectedEPF; // Cell D21:D31
  final double totalCorpus; // Cell E21:E31 (Projected MF + Projected EPF)
  final double totalCorpusCrores; // Cell F21:F31 (Total Corpus / 10,000,000)
  final double annualExpense; // Cell G21:G31 ((C7*12)*((1+C8)^year))
  final double target25x; // 25x Annual Expense
  final double target30x; // 30x Annual Expense
  final double surplus25x; // Total Corpus - 25x Target
  final double surplus30x; // Total Corpus - 30x Target

  const YearlyProjection({
    required this.year,
    required this.projectedMF,
    required this.projectedEPF,
    required this.totalCorpus,
    required this.totalCorpusCrores,
    required this.annualExpense,
    required this.target25x,
    required this.target30x,
    required this.surplus25x,
    required this.surplus30x,
  });
}

/// Represents all calculated outputs from Section 2 of Excel:
/// '2. LIVE RETIREMENT READINESS OUTPUTS'
class FireResults {
  /// Net Reinvested MF Principal (Cell G6 = C9*(1-C16))
  final double netReinvestedMFPrincipal;

  /// Future Monthly Expenses at Retirement (Cell G7 = C7*((1+C8)^C6))
  final double futureMonthlyExpenses;

  /// Future Annual Expenses at Retirement (Cell G8 = G7*12)
  final double futureAnnualExpenses;

  /// Projected Mutual Fund Corpus (Cell G9 = FV(C12/12, C6*12, -C11, -G6, 0))
  final double projectedMFCorpus;

  /// Projected EPF Corpus (Cell G10 = FV(C15/12, C6*12, -C14, -C13, 0))
  final double projectedEPFCorpus;

  /// TOTAL PROJECTED CORPUS (Pre-Tax) (Cell G11 = G9+G10)
  final double totalProjectedCorpus;

  /// Total Corpus in ₹ Crores (Cell G12 = G11/10000000)
  final double totalCorpusCrores;

  /// FIRE Target — 25x Rule (4.0% SWR) (Cell G13 = G8*25)
  final double fireTarget25x;

  /// Surplus / (Shortfall) vs. 25x Target (Cell G14 = G11-G13)
  final double surplus25x;

  /// FIRE Target — 30x Rule (3.33% SWR) (Cell G15 = G8*30)
  final double fireTarget30x;

  /// Surplus / (Shortfall) vs. 30x Target (Cell G16 = G11-G15)
  final double surplus30x;

  /// Total equity gains: G9 - C10 - (C11*C6*12)
  final double totalEquityGain;

  /// Taxable equity gains after ₹1.25L exemption: MAX(0, gain - 125000)
  final double taxableEquityGain;

  /// Estimated LTCG Tax on equity exit
  final double ltcgTax;

  /// Est. Post-Tax Corpus (if full MF exit) (Cell G17 = G11 - MAX(0, (G9 - C10 - (C11*C6*12) - 125000)*C17))
  final double estPostTaxCorpus;

  /// Est. Post-Tax Corpus in ₹ Crores
  final double estPostTaxCorpusCrores;

  /// Readiness % against 25x Target (e.g. 110%)
  final double readinessPercentage25x;

  /// Readiness % against 30x Target (e.g. 96%)
  final double readinessPercentage30x;

  /// Year-by-Year accumulation schedule for Years 0 to 10
  final List<YearlyProjection> yearlyProjections;

  const FireResults({
    required this.netReinvestedMFPrincipal,
    required this.futureMonthlyExpenses,
    required this.futureAnnualExpenses,
    required this.projectedMFCorpus,
    required this.projectedEPFCorpus,
    required this.totalProjectedCorpus,
    required this.totalCorpusCrores,
    required this.fireTarget25x,
    required this.surplus25x,
    required this.fireTarget30x,
    required this.surplus30x,
    required this.totalEquityGain,
    required this.taxableEquityGain,
    required this.ltcgTax,
    required this.estPostTaxCorpus,
    required this.estPostTaxCorpusCrores,
    required this.readinessPercentage25x,
    required this.readinessPercentage30x,
    required this.yearlyProjections,
  });
}
