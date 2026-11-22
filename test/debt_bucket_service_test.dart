import 'package:flutter_test/flutter_test.dart';
import 'package:fire_calculator/models/debt_bucket_models.dart';
import 'package:fire_calculator/services/debt_bucket_service.dart';

void main() {
  group('DebtBucketService Mathematical Parity Tests', () {
    test('3-Year Horizon Shift of ₹90k SIP to 7% Debt matches exact prompt figures', () {
      final inputs = const DebtBucketInputs(
        initialEquityMF: 35000000.0,
        redirectedMonthlySIP: 90000.0,
        horizonYears: 3.0,
        equityReturnRate: 0.12,
        debtReturnRate: 0.07,
        currentEPF: 5000000.0,
        monthlyEPF: 50000.0,
        epfReturnRate: 0.0825,
      );

      final results = DebtBucketService.calculate(inputs);

      // 1. Existing Equity MF (No New SIP): ~₹5.01 Cr at 12% over 3 yrs
      expect((results.existingEquityCorpus / 10000000.0 - 5.01).abs(), lessThan(0.05));

      // 2. Debt / Arbitrage Bucket (Redirected SIP): ~₹35.94 Lakhs (~₹0.36 Cr) at 7% over 3 yrs
      expect((results.accumulatedDebtBucket / 100000.0 - 35.94).abs(), lessThan(0.1));
      expect((results.accumulatedDebtCrores - 0.36).abs(), lessThan(0.02));

      // 3. Projected EPF: ~₹0.84 Cr at 8.25% over 3 yrs
      expect((results.projectedEPFCrores - 0.84).abs(), lessThan(0.02));

      // 4. Total Combined Corpus: ~₹6.21 Cr
      expect((results.totalCombinedCrores - 6.21).abs(), lessThan(0.05));

      // 5. Delta vs Full All-Equity SIP (~₹6.24 Cr): -₹2.83 Lakhs
      expect((results.allEquitySIPCrores - 6.24).abs(), lessThan(0.05));
      expect((results.deltaVsAllEquity / 100000.0 - (-2.83)).abs(), lessThan(0.1));

      // 6. Trade-off options generated
      expect(results.tradeoffOptions.length, 4);
    });
  });
}
