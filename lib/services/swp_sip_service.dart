import 'dart:math';
import '../models/swp_sip_models.dart';

class _ScenarioConfig {
  final String title;
  final double swp;
  final double sip;

  const _ScenarioConfig({
    required this.title,
    required this.swp,
    required this.sip,
  });
}

class SwpSipService {
  static SwpSipComparisonResults calculate(SwpSipInputs inputs) {
    final int months = (inputs.horizonYears * 12).round();
    final double years = inputs.horizonYears;

    // Projected EPF at horizon
    final double rEpfMonthly = inputs.epfReturn / 12.0;
    final double epfFactor = pow(1.0 + rEpfMonthly, months).toDouble();
    final double epfAnnuity = rEpfMonthly > 0 ? (epfFactor - 1.0) / rEpfMonthly : months.toDouble();
    final double projectedEPF = inputs.currentEPF * epfFactor + inputs.monthlyEPF * epfAnnuity;

    // Future Annual Expenses and FIRE targets at horizon
    final double futureMonthlyExpenses = inputs.currentMonthlyExpenses * pow(1.0 + inputs.expectedInflationRate, years);
    final double futureAnnualExpenses = futureMonthlyExpenses * 12.0;
    final double fireTarget25x = futureAnnualExpenses * 25.0;
    final double fireTarget30x = futureAnnualExpenses * 30.0;

    // Upfront LTCG Tax if initial corpus is completely cashed out
    final double initialGain = max(0.0, inputs.initialMFCorpus - inputs.currentCostBasis);
    final double taxableGain = max(0.0, initialGain - 125000.0);
    final double upfrontCashoutLtcgTax = taxableGain * inputs.ltcgTaxRate;

    // 1. Baseline: Stay Invested @ 12% MF + ₹90k Monthly Fresh SIP
    final double rBaseMonthly = inputs.baselineReturn / 12.0;
    final double baseFactor = pow(1.0 + rBaseMonthly, months).toDouble();
    final double baseAnnuity = rBaseMonthly > 0 ? (baseFactor - 1.0) / rBaseMonthly : months.toDouble();
    final double baseRemainingMF = inputs.initialMFCorpus * baseFactor;
    final double baseAccumulatedSIP = inputs.baselineSIP * baseAnnuity;
    final double baseCombinedMF = baseRemainingMF + baseAccumulatedSIP;
    final double baseCombinedTotal = baseCombinedMF + projectedEPF;

    final baselineResult = SwpSipScenarioResult(
      title: 'Stay Invested @ ${(inputs.baselineReturn * 100).toStringAsFixed(0)}% + ₹${(inputs.baselineSIP / 1000).toInt()}k SIP',
      swpRate: inputs.baselineReturn,
      sipRate: inputs.baselineReturn,
      swpRemainingBalance: baseRemainingMF,
      sipAccumulatedBalance: baseAccumulatedSIP,
      combinedMFCorpus: baseCombinedMF,
      projectedEPF: projectedEPF,
      combinedTotalCorpus: baseCombinedTotal,
      deltaVsStayInvested: 0.0,
      surplus25x: baseCombinedTotal - fireTarget25x,
      surplus30x: baseCombinedTotal - fireTarget30x,
      upfrontLTCGTaxNote: 'Zero upfront tax (Unrealized compounding)',
      isBaseline: true,
    );

    // Preset configurations to evaluate
    final scenarioConfigs = <_ScenarioConfig>[
      const _ScenarioConfig(title: 'SWP 12% -> SIP 12%', swp: 0.12, sip: 0.12),
      const _ScenarioConfig(title: 'SWP 9% -> SIP 12%', swp: 0.09, sip: 0.12),
      const _ScenarioConfig(title: 'SWP 8% -> SIP 12%', swp: 0.08, sip: 0.12),
    ];

    // If custom inputs are set differently, add as custom setup
    final bool matchesPreset = scenarioConfigs.any(
      (c) => (c.swp - inputs.swpBucketReturn).abs() < 0.001 && (c.sip - inputs.sipBucketReturn).abs() < 0.001,
    );

    if (!matchesPreset) {
      scenarioConfigs.add(
        _ScenarioConfig(
          title: 'Custom: SWP ${(inputs.swpBucketReturn * 100).toStringAsFixed(1)}% -> SIP ${(inputs.sipBucketReturn * 100).toStringAsFixed(1)}%',
          swp: inputs.swpBucketReturn,
          sip: inputs.sipBucketReturn,
        ),
      );
    }

    final List<SwpSipScenarioResult> evaluatedScenarios = [];

    for (final cfg in scenarioConfigs) {
      final double swpRate = cfg.swp;
      final double sipRate = cfg.sip;

      final double rSwp = swpRate / 12.0;
      final double rSip = sipRate / 12.0;

      // SWP remaining: Initial * (1+r)^n - SWP_Amt * [((1+r)^n - 1)/r]
      final double swpGrowthFactor = pow(1.0 + rSwp, months).toDouble();
      final double swpAnnuityFactor = rSwp > 0 ? (swpGrowthFactor - 1.0) / rSwp : months.toDouble();
      final double swpRemaining = max(0.0, inputs.initialMFCorpus * swpGrowthFactor - inputs.monthlySwpAmount * swpAnnuityFactor);

      // SIP accumulated: SWP_Amt * [((1+r)^n - 1)/r]
      final double sipGrowthFactor = pow(1.0 + rSip, months).toDouble();
      final double sipAnnuityFactor = rSip > 0 ? (sipGrowthFactor - 1.0) / rSip : months.toDouble();
      final double sipAccumulated = inputs.monthlySwpAmount * sipAnnuityFactor;

      final double combinedMF = swpRemaining + sipAccumulated;
      final double combinedTotal = combinedMF + projectedEPF;
      final double delta = combinedTotal - baseCombinedTotal;

      evaluatedScenarios.add(
        SwpSipScenarioResult(
          title: cfg.title,
          swpRate: swpRate,
          sipRate: sipRate,
          swpRemainingBalance: swpRemaining,
          sipAccumulatedBalance: sipAccumulated,
          combinedMFCorpus: combinedMF,
          projectedEPF: projectedEPF,
          combinedTotalCorpus: combinedTotal,
          deltaVsStayInvested: delta,
          surplus25x: combinedTotal - fireTarget25x,
          surplus30x: combinedTotal - fireTarget30x,
          upfrontLTCGTaxNote: 'Full initial cash-out incurs ~₹${(upfrontCashoutLtcgTax / 100000).toStringAsFixed(2)} Lakhs LTCG tax drag',
          isBaseline: false,
        ),
      );
    }

    // Trajectory generation (every 6 or 12 months)
    final List<MonthlyTrajectoryPoint> trajectory = [];
    final int step = months <= 36 ? 3 : (months <= 72 ? 6 : 12);
    for (int m = 0; m <= months; m += step) {
      final double rSwp = inputs.swpBucketReturn / 12.0;
      final double rSip = inputs.sipBucketReturn / 12.0;
      final double rBase = inputs.baselineReturn / 12.0;

      // SWP balance at month m
      final double swpGF = pow(1.0 + rSwp, m).toDouble();
      final double swpAF = rSwp > 0 ? (swpGF - 1.0) / rSwp : m.toDouble();
      final double swpRem = max(0.0, inputs.initialMFCorpus * swpGF - inputs.monthlySwpAmount * swpAF);

      // SIP balance at month m
      final double sipGF = pow(1.0 + rSip, m).toDouble();
      final double sipAF = rSip > 0 ? (sipGF - 1.0) / rSip : m.toDouble();
      final double sipAcc = inputs.monthlySwpAmount * sipAF;

      // Stay invested at month m
      final double baseGF = pow(1.0 + rBase, m).toDouble();
      final double baseAF = rBase > 0 ? (baseGF - 1.0) / rBase : m.toDouble();
      final double baseMF = inputs.initialMFCorpus * baseGF + inputs.baselineSIP * baseAF;

      trajectory.add(
        MonthlyTrajectoryPoint(
          month: m,
          year: (m / 12).floor(),
          swpRemaining: swpRem,
          sipAccumulated: sipAcc,
          combinedMF: swpRem + sipAcc,
          stayInvestedMF: baseMF,
        ),
      );
    }

    return SwpSipComparisonResults(
      inputs: inputs,
      horizonMonths: months,
      fireTarget25x: fireTarget25x,
      fireTarget30x: fireTarget30x,
      upfrontCashoutLtcgTax: upfrontCashoutLtcgTax,
      baselineResult: baselineResult,
      scenarios: evaluatedScenarios,
      trajectory: trajectory,
    );
  }
}
