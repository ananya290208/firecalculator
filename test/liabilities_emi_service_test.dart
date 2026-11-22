import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:fire_calculator/models/fire_inputs.dart';
import 'package:fire_calculator/models/liabilities_emi_models.dart';
import 'package:fire_calculator/services/fire_calculator_service.dart';
import 'package:fire_calculator/services/liabilities_emi_service.dart';

void main() {
  group('LiabilitiesEmiService Tests', () {
    const defaultFireInputs = FireInputs(
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

    final defaultFireResults = FireCalculatorService.calculate(defaultFireInputs);

    test('1. Default inputs (0 EMI) preserves baseline FIRE calculations completely', () {
      const emiInputs = LiabilitiesEmiInputs();
      final results = LiabilitiesEmiService.calculate(
        fireInputs: defaultFireInputs,
        fireResults: defaultFireResults,
        emiInputs: emiInputs,
      );

      expect(results.totalMonthlyEmi, 0.0);
      expect(results.postRetirementEmiMonths, 0);
      expect(results.postRetirementEmiPv, 0.0);
      expect(results.hasPostRetirementEmi, false);
      expect(results.isSipSqueezed, false);
      expect(results.sipSqueezeCorpusDelta, 0.0);

      // Lifestyle targets match Adjusted targets exactly
      expect(results.lifestyleFire25x, defaultFireResults.fireTarget25x);
      expect(results.lifestyleFire30x, defaultFireResults.fireTarget30x);
      expect(results.adjustedFire25x, defaultFireResults.fireTarget25x);
      expect(results.adjustedFire30x, defaultFireResults.fireTarget30x);

      // Corpus unchanged
      expect(results.unsqueezedMFCorpus, defaultFireResults.projectedMFCorpus);
      expect(results.squeezedMFCorpus, defaultFireResults.projectedMFCorpus);
      expect(results.totalCorpus, defaultFireResults.totalProjectedCorpus);
      expect(results.surplus25xAdjusted, defaultFireResults.surplus25x);
      expect(results.surplus30xAdjusted, defaultFireResults.surplus30x);
    });

    test('2. Post-retirement EMI overhang with inflation vs loan interest rate discounting', () {
      // 3 years target = 36 months retirement
      // 96 months total remaining tenure -> 36 pre-retirement, 60 post-retirement overhang
      const emiInputs = LiabilitiesEmiInputs(
        homeLoanEmi: 50000.0,
        remainingEmiMonths: 96,
        loanInterestRate: 0.085,
        discountPostRetirementEmiAtInflation: true,
      );

      final resultsInflation = LiabilitiesEmiService.calculate(
        fireInputs: defaultFireInputs,
        fireResults: defaultFireResults,
        emiInputs: emiInputs,
      );

      expect(resultsInflation.retirementMonths, 36);
      expect(resultsInflation.emiMonthsBeforeRetirement, 36);
      expect(resultsInflation.postRetirementEmiMonths, 60);
      expect(resultsInflation.hasPostRetirementEmi, true);

      // Analytical check with inflation r = 0.06 / 12 = 0.005
      // PV = 50,000 * ((1 - (1 + 0.005)^(-60)) / 0.005)
      final rInf = 0.06 / 12.0;
      final expectedPvInflation = 50000.0 * ((1.0 - pow(1.0 + rInf, -60)) / rInf);
      expect((resultsInflation.postRetirementEmiPv - expectedPvInflation).abs(), lessThan(1.0));

      // Adjusted FIRE target = lifestyle FIRE target + postRetirementEmiPv
      expect(resultsInflation.adjustedFire25x, resultsInflation.lifestyleFire25x + resultsInflation.postRetirementEmiPv);
      expect(resultsInflation.adjustedFire30x, resultsInflation.lifestyleFire30x + resultsInflation.postRetirementEmiPv);

      // Discounting at loan interest rate (8.5% p.a.)
      final resultsLoanRate = LiabilitiesEmiService.calculate(
        fireInputs: defaultFireInputs,
        fireResults: defaultFireResults,
        emiInputs: emiInputs.copyWith(discountPostRetirementEmiAtInflation: false),
      );

      final rLoan = 0.085 / 12.0;
      final expectedPvLoan = 50000.0 * ((1.0 - pow(1.0 + rLoan, -60)) / rLoan);
      expect((resultsLoanRate.postRetirementEmiPv - expectedPvLoan).abs(), lessThan(1.0));
      // Higher discount rate (8.5% > 6.0%) gives lower present value
      expect(resultsLoanRate.postRetirementEmiPv, lessThan(resultsInflation.postRetirementEmiPv));
    });

    test('3. SIP Squeeze modeling calculates two-phase MF compounding penalty', () {
      // 3 target years = 36 months
      // 24 months EMI, reducing SIP from 90k to 40k during those 24 months
      const emiInputs = LiabilitiesEmiInputs(
        homeLoanEmi: 45000.0,
        remainingEmiMonths: 24,
        enableSipSqueeze: true,
        reducedMonthlyMfSipDuringEmi: 40000.0,
      );

      final results = LiabilitiesEmiService.calculate(
        fireInputs: defaultFireInputs,
        fireResults: defaultFireResults,
        emiInputs: emiInputs,
      );

      expect(results.isSipSqueezed, true);
      expect(results.emiMonthsBeforeRetirement, 24);
      expect(results.postRetirementEmiMonths, 0);
      expect(results.postRetirementEmiPv, 0.0);

      // Verify that squeezed MF corpus is strictly lower than unsqueezed
      expect(results.squeezedMFCorpus, lessThan(results.unsqueezedMFCorpus));
      expect(results.sipSqueezeCorpusDelta, lessThan(0.0));
      expect(results.sipSqueezeCorpusDelta, results.squeezedMFCorpus - results.unsqueezedMFCorpus);

      // Effective total corpus incorporates squeezed MF corpus
      expect(results.totalCorpus, results.squeezedMFCorpus + defaultFireResults.projectedEPFCorpus);
    });

    test('4. Itemized EMIs and Tenure Formatter work correctly', () {
      const emiInputs = LiabilitiesEmiInputs(
        homeLoanEmi: 40000.0,
        carLoanEmi: 15000.0,
        personalLoanEmi: 5000.0,
        otherLoanEmi: 2000.0,
        remainingEmiMonths: 84, // 7 years exactly
      );

      expect(emiInputs.totalMonthlyEmi, 62000.0);
      expect(emiInputs.tenureFormatted, '7 Years (84 Mo)');

      // Custom override
      final overrideInputs = emiInputs.copyWith(customTotalMonthlyEmi: 70000.0);
      expect(overrideInputs.totalMonthlyEmi, 70000.0);

      // Partial years formatter
      final partialTenure = emiInputs.copyWith(remainingEmiMonths: 26);
      expect(partialTenure.tenureFormatted, '2 Yrs 2 Mo (26 Mo)');

      // Zero tenure
      final zeroTenure = emiInputs.copyWith(remainingEmiMonths: 0);
      expect(zeroTenure.tenureFormatted, '0 Months (No Debt)');
    });
  });
}
