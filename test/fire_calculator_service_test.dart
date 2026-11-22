import 'package:flutter_test/flutter_test.dart';
import 'package:fire_calculator/models/fire_inputs.dart';
import 'package:fire_calculator/services/fire_calculator_service.dart';

void main() {
  group('FireCalculatorService Excel Matching Tests', () {
    test('Default 3-Year Excel Scenario matches exact values', () {
      final inputs = FireInputs.excelDefaults();
      final results = FireCalculatorService.calculate(inputs);

      // Section 1 checks
      expect(inputs.targetYears, 3.0);
      expect(inputs.currentMonthlyExpenses, 125000.0);
      expect(inputs.expectedInflationRate, 0.06);
      expect(inputs.currentMFValue, 35000000.0);
      expect(inputs.currentMFCostBasis, 21000000.0);
      expect(inputs.monthlyMFSIP, 90000.0);
      expect(inputs.expectedMFReturn, 0.12);
      expect(inputs.currentEPFBalance, 5000000.0);
      expect(inputs.monthlyEPFContribution, 50000.0);
      expect(inputs.expectedEPFReturn, 0.0825);

      // Section 2 outputs
      // G6: Net Reinvested MF Principal
      expect(results.netReinvestedMFPrincipal, 35000000.0);

      // G7: Future Monthly Expenses at Retirement = 125000 * (1.06^3) = 148,877
      expect((results.futureMonthlyExpenses - 148877.0).abs(), lessThan(1.0));

      // G8: Future Annual Expenses at Retirement = 148877 * 12 = 1,786,524
      expect((results.futureAnnualExpenses - 1786524.0).abs(), lessThan(1.0));

      // G9: Projected Mutual Fund Corpus = ~5,39,53,826.48
      expect((results.projectedMFCorpus - 53953826.48).abs(), lessThan(5.0));

      // G10: Projected EPF Corpus = ~84,33,112.51
      expect((results.projectedEPFCorpus - 8433112.51).abs(), lessThan(5.0));

      // G11: TOTAL PROJECTED CORPUS (Pre-Tax) = ~6,23,86,938.99
      expect((results.totalProjectedCorpus - 62386938.99).abs(), lessThan(5.0));

      // G12: Total Corpus in Crores = ~6.2387 Cr
      expect((results.totalCorpusCrores - 6.23869).abs(), lessThan(0.01));

      // G13: FIRE Target — 25x Rule = 1786524 * 25 = 44,663,100
      expect((results.fireTarget25x - 44663100.0).abs(), lessThan(10.0));

      // G14: Surplus vs 25x Target = 62386938.99 - 44663100 = ~1,77,23,838.99
      expect((results.surplus25x - 17723838.99).abs(), lessThan(10.0));

      // G15: FIRE Target — 30x Rule = 1786524 * 30 = 53,595,720
      expect((results.fireTarget30x - 53595720.0).abs(), lessThan(10.0));

      // G16: Surplus vs 30x Target = 62386938.99 - 53595720 = ~87,91,218.99
      expect((results.surplus30x - 8791218.99).abs(), lessThan(10.0));

      // G17: Post-tax corpus check
      // Taxable gain = 53953826.48 - 21000000 - (90000*36) - 125000 = 29588826.48
      // Tax = 29588826.48 * 0.125 = 3698603.31
      // Post-tax = 62386938.99 - 3698603.31 = 58688335.68
      expect((results.taxableEquityGain - 29588826.48).abs(), lessThan(10.0));
      expect((results.ltcgTax - 3698603.31).abs(), lessThan(5.0));
      expect((results.estPostTaxCorpus - 58688335.68).abs(), lessThan(10.0));

      // Section 3: Schedule
      expect(results.yearlyProjections.length, 11);
      // Year 0
      expect(results.yearlyProjections[0].year, 0);
      expect(results.yearlyProjections[0].projectedMF, 35000000.0);
      expect(results.yearlyProjections[0].projectedEPF, 5000000.0);
      expect(results.yearlyProjections[0].totalCorpus, 40000000.0);
      expect(results.yearlyProjections[0].totalCorpusCrores, 4.0);
    });

    test('7-Year Horizon Stress Test matches docx and matrix numbers', () {
      final inputs = FireInputs.sevenYearStressTest();
      final results = FireCalculatorService.calculate(inputs);

      // Docx: Projected Corpus (Year 7): ₹10.47 Crores
      expect((results.totalCorpusCrores - 10.47).abs(), lessThan(0.05));
      // Docx: 25x FIRE Target: ₹9.02 Crores, Surplus: +₹1.45 Crores
      expect((results.fireTarget25x / 10000000.0 - 9.02).abs(), lessThan(0.05));
      expect((results.surplus25x / 10000000.0 - 1.45).abs(), lessThan(0.05));
      // Docx: 30x Target: ₹10.83 Crores, Deficit: -₹0.35 Crores
      expect((results.fireTarget30x / 10000000.0 - 10.83).abs(), lessThan(0.05));
      expect((results.surplus30x / 10000000.0 - (-0.35)).abs(), lessThan(0.05));
    });

    test('Pre-Built Scenarios calculate all 6 rows correctly', () {
      final inputs = FireInputs.excelDefaults();
      final scenarios = FireCalculatorService.calculatePreBuiltScenarios(inputs);

      expect(scenarios.length, 6);
      expect(scenarios[0].horizonYears, 3.0);
      expect(scenarios[0].monthlyExpenseToday, 125000.0);
      expect(scenarios[1].monthlyExpenseToday, 200000.0);
      expect(scenarios[2].horizonYears, 6.0);
      expect(scenarios[4].horizonYears, 7.0);
    });
  });
}
