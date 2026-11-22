import 'package:flutter_test/flutter_test.dart';
import 'package:fire_calculator/models/swp_sip_models.dart';
import 'package:fire_calculator/services/swp_sip_service.dart';

void main() {
  group('SwpSipService Mathematical Parity Tests', () {
    test('6-Year Default Horizon Baseline and SWP-to-SIP numbers match prompt specs', () {
      final inputs = const SwpSipInputs(
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
      );

      final results = SwpSipService.calculate(inputs);

      // Baseline: Stay Invested @ 12% + ₹90k SIP:
      // ~₹8.11 Cr MF / ~₹9.39 Cr combined at Yr 6
      expect((results.baselineResult.combinedMFCorpus / 10000000.0 - 8.11).abs(), lessThan(0.05));
      expect((results.baselineResult.combinedTotalCorpus / 10000000.0 - 9.39).abs(), lessThan(0.05));

      // EPF at Year 6: ~₹1.28 Cr
      expect((results.baselineResult.projectedEPF / 10000000.0 - 1.28).abs(), lessThan(0.05));

      // Scenarios generated
      expect(results.scenarios.isNotEmpty, true);
      final swp9sip12 = results.scenarios.firstWhere((s) => s.title.contains('9%'));
      expect(swp9sip12.swpRate, 0.09);
      expect(swp9sip12.sipRate, 0.12);

      // Upfront LTCG Cash-Out Tax note check:
      // (3.50 Cr - 2.10 Cr - 1.25L) * 12.5% = ~17.34 Lakhs
      expect((results.upfrontCashoutLtcgTax - 1734375.0).abs(), lessThan(10.0));

      // Trajectory checks
      expect(results.trajectory.isNotEmpty, true);
      expect(results.trajectory.first.month, 0);
      expect(results.trajectory.last.month, 72);
    });
  });
}
