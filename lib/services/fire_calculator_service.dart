import 'dart:math';
import '../models/fire_inputs.dart';
import '../models/fire_results.dart';
import '../models/scenario_item.dart';

/// Pure calculation engine replicating the exact formulas from
/// 'Interactive_FIRE_Calculator.xlsx'
class FireCalculatorService {
  /// Excel-equivalent Future Value calculation: FV(rate, nper, pmt, pv, type)
  /// Matches Excel's FV() function with 100% precision.
  static double excelFV(
    double rate,
    double nper,
    double pmt,
    double pv, [
    int type = 0,
  ]) {
    if (nper == 0) {
      return -pv;
    }
    if (rate == 0) {
      return -(pv + pmt * nper);
    }
    final double pvif = pow(1.0 + rate, nper).toDouble();
    final double fv = -(pv * pvif + pmt * (1.0 + rate * type) * (pvif - 1.0) / rate);
    return fv;
  }

  /// Calculates Section 2 (Live Outputs) & Section 3 (Yearly Projections)
  /// exactly as defined in Excel sheet 'FIRE_Calculator'
  static FireResults calculate(FireInputs inputs) {
    // 1. G6: Net Reinvested MF Principal (₹) = C9 * (1 - C16)
    final double netReinvestedMF = inputs.currentMFValue * (1.0 - inputs.upfrontMFCashOutRate);

    // 2. G7: Future Monthly Expenses at Retirement = C7 * ((1 + C8) ^ C6)
    final double futureMonthlyExpenses = inputs.currentMonthlyExpenses *
        pow(1.0 + inputs.expectedInflationRate, inputs.targetYears).toDouble();

    // 3. G8: Future Annual Expenses at Retirement = G7 * 12
    final double futureAnnualExpenses = futureMonthlyExpenses * 12.0;

    // 4. G9: Projected Mutual Fund Corpus (₹) = FV(C12/12, C6*12, -C11, -G6, 0)
    final double projectedMFCorpus = excelFV(
      inputs.expectedMFReturn / 12.0,
      inputs.targetYears * 12.0,
      -inputs.monthlyMFSIP,
      -netReinvestedMF,
      0,
    );

    // 5. G10: Projected EPF Corpus (₹) = FV(C15/12, C6*12, -C14, -C13, 0)
    final double projectedEPFCorpus = excelFV(
      inputs.expectedEPFReturn / 12.0,
      inputs.targetYears * 12.0,
      -inputs.monthlyEPFContribution,
      -inputs.currentEPFBalance,
      0,
    );

    // 6. G11: TOTAL PROJECTED CORPUS (Pre-Tax) = G9 + G10
    final double totalProjectedCorpus = projectedMFCorpus + projectedEPFCorpus;

    // 7. G12: Total Corpus in ₹ Crores = G11 / 10,000,000
    final double totalCorpusCrores = totalProjectedCorpus / 10000000.0;

    // 8. G13: FIRE Target — 25x Rule (4.0% SWR) = G8 * 25
    final double fireTarget25x = futureAnnualExpenses * 25.0;

    // 9. G14: Surplus / (Shortfall) vs. 25x Target = G11 - G13
    final double surplus25x = totalProjectedCorpus - fireTarget25x;

    // 10. G15: FIRE Target — 30x Rule (3.33% SWR) = G8 * 30
    final double fireTarget30x = futureAnnualExpenses * 30.0;

    // 11. G16: Surplus / (Shortfall) vs. 30x Target = G11 - G15
    final double surplus30x = totalProjectedCorpus - fireTarget30x;

    // 12. G17: Est. Post-Tax Corpus (if full MF exit)
    // Formula: G11 - MAX(0, (G9 - C10 - (C11*C6*12) - 125000)*C17)
    final double totalInvestedSIP = inputs.monthlyMFSIP * inputs.targetYears * 12.0;
    final double totalEquityGain = projectedMFCorpus - inputs.currentMFCostBasis - totalInvestedSIP;
    final double taxableEquityGain = max(0.0, totalEquityGain - 125000.0);
    final double ltcgTax = taxableEquityGain * inputs.ltcgTaxRate;
    final double estPostTaxCorpus = totalProjectedCorpus - ltcgTax;
    final double estPostTaxCorpusCrores = estPostTaxCorpus / 10000000.0;

    // Readiness percentages
    final double readiness25x = fireTarget25x > 0 ? (totalProjectedCorpus / fireTarget25x) * 100.0 : 0.0;
    final double readiness30x = fireTarget30x > 0 ? (totalProjectedCorpus / fireTarget30x) * 100.0 : 0.0;

    // Section 3: Year-by-Year Schedule (Years 0 to 10)
    final List<YearlyProjection> yearly = [];
    for (int t = 0; t <= 10; t++) {
      final double mfT = excelFV(
        inputs.expectedMFReturn / 12.0,
        t * 12.0,
        -inputs.monthlyMFSIP,
        -netReinvestedMF,
        0,
      );
      final double epfT = excelFV(
        inputs.expectedEPFReturn / 12.0,
        t * 12.0,
        -inputs.monthlyEPFContribution,
        -inputs.currentEPFBalance,
        0,
      );
      final double totalT = mfT + epfT;
      final double totalCrT = totalT / 10000000.0;
      final double expT = (inputs.currentMonthlyExpenses * 12.0) *
          pow(1.0 + inputs.expectedInflationRate, t.toDouble()).toDouble();
      final double t25 = expT * 25.0;
      final double t30 = expT * 30.0;

      yearly.add(YearlyProjection(
        year: t,
        projectedMF: mfT,
        projectedEPF: epfT,
        totalCorpus: totalT,
        totalCorpusCrores: totalCrT,
        annualExpense: expT,
        target25x: t25,
        target30x: t30,
        surplus25x: totalT - t25,
        surplus30x: totalT - t30,
      ));
    }

    return FireResults(
      netReinvestedMFPrincipal: netReinvestedMF,
      futureMonthlyExpenses: futureMonthlyExpenses,
      futureAnnualExpenses: futureAnnualExpenses,
      projectedMFCorpus: projectedMFCorpus,
      projectedEPFCorpus: projectedEPFCorpus,
      totalProjectedCorpus: totalProjectedCorpus,
      totalCorpusCrores: totalCorpusCrores,
      fireTarget25x: fireTarget25x,
      surplus25x: surplus25x,
      fireTarget30x: fireTarget30x,
      surplus30x: surplus30x,
      totalEquityGain: totalEquityGain,
      taxableEquityGain: taxableEquityGain,
      ltcgTax: ltcgTax,
      estPostTaxCorpus: estPostTaxCorpus,
      estPostTaxCorpusCrores: estPostTaxCorpusCrores,
      readinessPercentage25x: readiness25x,
      readinessPercentage30x: readiness30x,
      yearlyProjections: yearly,
    );
  }

  /// Calculates the 6 pre-built scenarios from Sheet 2:
  /// 'PRE-BUILT RETIREMENT HORIZON & EXPENSE SCENARIO MATRIX'
  static List<ScenarioItem> calculatePreBuiltScenarios(FireInputs baseInputs) {
    // The 6 pre-built matrix scenarios defined in Excel:
    final List<Map<String, dynamic>> defs = [
      {
        'name': '3-Year Horizon — Base Expense (₹1.25L/mo today)',
        'horizon': 3.0,
        'expense': 125000.0,
      },
      {
        'name': '3-Year Horizon — Upper Expense (₹2.00L/mo today)',
        'horizon': 3.0,
        'expense': 200000.0,
      },
      {
        'name': '6-Year Horizon — Base Expense (₹1.25L/mo today)',
        'horizon': 6.0,
        'expense': 125000.0,
      },
      {
        'name': '6-Year Horizon — Upper Expense (₹2.00L/mo today)',
        'horizon': 6.0,
        'expense': 200000.0,
      },
      {
        'name': '7-Year Horizon — Base Expense (₹1.25L/mo today)',
        'horizon': 7.0,
        'expense': 125000.0,
      },
      {
        'name': '7-Year Horizon — Upper Expense (₹2.00L/mo today)',
        'horizon': 7.0,
        'expense': 200000.0,
      },
    ];

    final double netMF = baseInputs.currentMFValue * (1.0 - baseInputs.upfrontMFCashOutRate);

    return defs.map((d) {
      final double h = d['horizon'] as double;
      final double exp = d['expense'] as double;

      // Excel Formula E5:
      // =(FV(FIRE_Calculator!$C$12/12, C5*12, -FIRE_Calculator!$C$11, -FIRE_Calculator!$G$6, 0)
      //  + FV(FIRE_Calculator!$C$15/12, C5*12, -FIRE_Calculator!$C$14, -FIRE_Calculator!$C$13, 0))/10000000
      final double mf = excelFV(
        baseInputs.expectedMFReturn / 12.0,
        h * 12.0,
        -baseInputs.monthlyMFSIP,
        -netMF,
        0,
      );
      final double epf = excelFV(
        baseInputs.expectedEPFReturn / 12.0,
        h * 12.0,
        -baseInputs.monthlyEPFContribution,
        -baseInputs.currentEPFBalance,
        0,
      );
      final double projectedCorpusCr = (mf + epf) / 10000000.0;

      // Excel Formula F5:
      // =((D5*12)*((1+FIRE_Calculator!$C$8)^C5)*25)/10000000
      final double annualExp = (exp * 12.0) * pow(1.0 + baseInputs.expectedInflationRate, h).toDouble();
      final double target25xCr = (annualExp * 25.0) / 10000000.0;

      // Excel Formula G5: =E5 - F5
      final double surplus25xCr = projectedCorpusCr - target25xCr;

      // Excel Formula H5:
      // =((D5*12)*((1+FIRE_Calculator!$C$8)^C5)*30)/10000000
      final double target30xCr = (annualExp * 30.0) / 10000000.0;
      final double surplus30xCr = projectedCorpusCr - target30xCr;

      return ScenarioItem(
        name: d['name'] as String,
        horizonYears: h,
        monthlyExpenseToday: exp,
        projectedCorpusCrores: projectedCorpusCr,
        target25xCrores: target25xCr,
        surplus25xCrores: surplus25xCr,
        target30xCrores: target30xCr,
        surplus30xCrores: surplus30xCr,
      );
    }).toList();
  }
}
