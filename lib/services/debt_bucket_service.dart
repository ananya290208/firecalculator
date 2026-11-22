import 'dart:math';
import '../models/debt_bucket_models.dart';

class DebtBucketService {
  static DebtBucketResults calculate(DebtBucketInputs inputs) {
    final int months = (inputs.horizonYears * 12).round();
    final double years = inputs.horizonYears;

    final double rEq = inputs.equityReturnRate / 12.0;
    final double rDebt = inputs.debtReturnRate / 12.0;
    final double rEpf = inputs.epfReturnRate / 12.0;

    // 1. Existing Equity MF Compounding (Zero new SIP into equity)
    final double eqFactor = pow(1.0 + rEq, months).toDouble();
    final double existingEquityCorpus = inputs.initialEquityMF * eqFactor;

    // 2. Debt / Arbitrage Bucket Accumulation (Redirected SIP)
    final double debtFactor = pow(1.0 + rDebt, months).toDouble();
    final double debtAnnuity = rDebt > 0 ? (debtFactor - 1.0) / rDebt : months.toDouble();
    final double accumulatedDebtBucket = inputs.redirectedMonthlySIP * debtAnnuity;

    // 3. Projected EPF
    final double epfFactor = pow(1.0 + rEpf, months).toDouble();
    final double epfAnnuity = rEpf > 0 ? (epfFactor - 1.0) / rEpf : months.toDouble();
    final double projectedEPF = inputs.currentEPF * epfFactor + inputs.monthlyEPF * epfAnnuity;

    // 4. Combined Total Corpus
    final double totalCombinedCorpus = existingEquityCorpus + accumulatedDebtBucket + projectedEPF;

    // 5. Full All-Equity SIP Reference (12% SIP in Equity)
    final double eqAnnuity = rEq > 0 ? (eqFactor - 1.0) / rEq : months.toDouble();
    final double allEquityMF = inputs.initialEquityMF * eqFactor + inputs.redirectedMonthlySIP * eqAnnuity;
    final double allEquitySIPTotal = allEquityMF + projectedEPF;
    final double deltaVsAllEquity = totalCombinedCorpus - allEquitySIPTotal;

    // FIRE Targets at Horizon
    final double futureMonthlyExpenses = inputs.currentMonthlyExpenses * pow(1.0 + inputs.expectedInflationRate, years);
    final double futureAnnualExpenses = futureMonthlyExpenses * 12.0;
    final double fireTarget25x = futureAnnualExpenses * 25.0;
    final double fireTarget30x = futureAnnualExpenses * 30.0;

    // Trade-off Options:
    // Option 1: Redirect ₹90k SIP to 7% Debt Bucket
    final option1 = DebtShiftTradeoffOption(
      title: '1. Redirect Fresh ₹${(inputs.redirectedMonthlySIP / 1000).toInt()}k SIP to Debt/Arbitrage',
      description: 'Keep existing ₹${(inputs.initialEquityMF / 10000000).toStringAsFixed(2)} Cr fully invested in Equity. Flow monthly SIP into 7% low-volatility Debt.',
      equityMFValue: existingEquityCorpus,
      debtBucketValue: accumulatedDebtBucket,
      epfValue: projectedEPF,
      totalCorpus: totalCombinedCorpus,
      deltaVsAllEquity: deltaVsAllEquity,
      taxImplication: 'Zero upfront tax on existing MF; gains in debt taxed only on redemption.',
      riskProfile: 'Balanced: Builds ₹${(accumulatedDebtBucket / 100000).toStringAsFixed(1)}L liquid debt reserve while equities compound undisturbed.',
    );

    // Option 2: Full 100% Equity SIP (All-In Equity)
    final option2 = DebtShiftTradeoffOption(
      title: '2. All-In 100% Equity SIP @ ${(inputs.equityReturnRate * 100).toStringAsFixed(0)}%',
      description: 'Keep entire portfolio and fresh SIP exposed to equity market compounding.',
      equityMFValue: allEquityMF,
      debtBucketValue: 0.0,
      epfValue: projectedEPF,
      totalCorpus: allEquitySIPTotal,
      deltaVsAllEquity: 0.0,
      taxImplication: 'Zero immediate tax; 12.5% LTCG on all equity gains at retirement.',
      riskProfile: 'Aggressive: Maximum corpus (+₹${(-deltaVsAllEquity / 100000).toStringAsFixed(2)}L vs Debt SIP), but zero safe debt buffer outside EPF.',
    );

    // Option 3: Immediate ₹50L Lumpsum Shift to Debt
    final double shiftedMFPrincipal = max(0.0, inputs.initialEquityMF - inputs.capitalShiftAmount);
    final double option3Equity = shiftedMFPrincipal * eqFactor;
    final double option3Debt = inputs.capitalShiftAmount * debtFactor + accumulatedDebtBucket;
    final double option3Total = option3Equity + option3Debt + projectedEPF;
    final double option3Delta = option3Total - allEquitySIPTotal;

    final option3 = DebtShiftTradeoffOption(
      title: '3. Immediate Lumpsum Shift of ₹${(inputs.capitalShiftAmount / 100000).toInt()}L to Debt',
      description: 'Redeem ₹${(inputs.capitalShiftAmount / 100000).toInt()}L from MF today into Debt, and continue ₹${(inputs.redirectedMonthlySIP / 1000).toInt()}k/mo into Debt.',
      equityMFValue: option3Equity,
      debtBucketValue: option3Debt,
      epfValue: projectedEPF,
      totalCorpus: option3Total,
      deltaVsAllEquity: option3Delta,
      taxImplication: 'Triggers immediate LTCG tax drag today on the ₹${(inputs.capitalShiftAmount / 100000).toInt()}L withdrawal.',
      riskProfile: 'Defensive: Substantial safe cushion (~₹${(option3Debt / 10000000).toStringAsFixed(2)} Cr in debt), but surrenders ~₹${(-option3Delta / 100000).toStringAsFixed(1)}L in equity compounding.',
    );

    // Option 4: Systematic Transfer Plan (STP) of ₹50L over 36 Months
    final double monthlySTPAmount = inputs.capitalShiftAmount / months;
    // MF has initialMF, compounding at rEq, paying out monthlySTP
    final double stpEquity = max(0.0, inputs.initialEquityMF * eqFactor - monthlySTPAmount * eqAnnuity);
    // Debt bucket receives monthlySTP + redirectedSIP
    final double totalMonthlyToDebt = monthlySTPAmount + inputs.redirectedMonthlySIP;
    final double stpDebt = totalMonthlyToDebt * debtAnnuity;
    final double option4Total = stpEquity + stpDebt + projectedEPF;
    final double option4Delta = option4Total - allEquitySIPTotal;

    final option4 = DebtShiftTradeoffOption(
      title: '4. Gradual STP Shift of ₹${(inputs.capitalShiftAmount / 100000).toInt()}L over $months Months',
      description: 'Systematically transfer ₹${(monthlySTPAmount / 1000).toStringAsFixed(0)}k/mo from MF into Debt along with fresh SIP.',
      equityMFValue: stpEquity,
      debtBucketValue: stpDebt,
      epfValue: projectedEPF,
      totalCorpus: option4Total,
      deltaVsAllEquity: option4Delta,
      taxImplication: 'Spreads capital gains tax evenly over 3 financial years, optimizing exemption brackets.',
      riskProfile: 'Optimal DCA: Smooths volatility, avoids timing errors, and yields ~₹${(option4Total / 10000000).toStringAsFixed(2)} Cr total corpus.',
    );

    return DebtBucketResults(
      inputs: inputs,
      horizonMonths: months,
      existingEquityCorpus: existingEquityCorpus,
      accumulatedDebtBucket: accumulatedDebtBucket,
      projectedEPF: projectedEPF,
      totalCombinedCorpus: totalCombinedCorpus,
      allEquitySIPTotal: allEquitySIPTotal,
      deltaVsAllEquity: deltaVsAllEquity,
      fireTarget25x: fireTarget25x,
      fireTarget30x: fireTarget30x,
      tradeoffOptions: [option1, option2, option3, option4],
    );
  }
}
