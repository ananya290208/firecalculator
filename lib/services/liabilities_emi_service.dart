import 'dart:math';
import '../models/fire_inputs.dart';
import '../models/fire_results.dart';
import '../models/liabilities_emi_models.dart';

class LiabilitiesEmiService {
  static LiabilitiesEmiResults calculate({
    required FireInputs fireInputs,
    required FireResults fireResults,
    required LiabilitiesEmiInputs emiInputs,
  }) {
    final int retirementMonths = (fireInputs.targetYears * 12).round();
    final int remainingEmiMonths = emiInputs.remainingEmiMonths;
    final double totalMonthlyEmi = emiInputs.totalMonthlyEmi;

    final int emiMonthsBeforeRetirement =
        min(remainingEmiMonths, retirementMonths);
    final int postRetirementEmiMonths =
        max(0, remainingEmiMonths - retirementMonths);

    // 1. Post-Retirement EMI Present Value at Retirement Date
    double postRetirementEmiPv = 0.0;
    if (postRetirementEmiMonths > 0 && totalMonthlyEmi > 0) {
      final double discountAnnualRate =
          emiInputs.discountPostRetirementEmiAtInflation
              ? fireInputs.expectedInflationRate
              : emiInputs.loanInterestRate;
      final double r = discountAnnualRate / 12.0;

      if (r == 0.0) {
        postRetirementEmiPv = totalMonthlyEmi * postRetirementEmiMonths;
      } else {
        postRetirementEmiPv = totalMonthlyEmi *
            ((1.0 - pow(1.0 + r, -postRetirementEmiMonths)) / r);
      }
    }

    // 2. Separate Lifestyle FIRE targets from Post-Retirement EMI
    final double lifestyleFire25x = fireResults.fireTarget25x;
    final double lifestyleFire30x = fireResults.fireTarget30x;

    final double adjustedFire25x = lifestyleFire25x + postRetirementEmiPv;
    final double adjustedFire30x = lifestyleFire30x + postRetirementEmiPv;

    // 3. SIP Squeeze Modeling
    final double unsqueezedMFCorpus = fireResults.projectedMFCorpus;
    double squeezedMFCorpus = unsqueezedMFCorpus;
    double sipSqueezeCorpusDelta = 0.0;

    final bool isSipSqueezed = emiInputs.enableSipSqueeze &&
        emiMonthsBeforeRetirement > 0 &&
        (emiInputs.reducedMonthlyMfSipDuringEmi - fireInputs.monthlyMFSIP).abs() > 0.01;

    if (isSipSqueezed) {
      final double rMf = fireInputs.expectedMFReturn / 12.0;
      final double p0 = fireResults.netReinvestedMFPrincipal;

      // Phase 1: During pre-retirement EMI months with reduced SIP
      final int k = emiMonthsBeforeRetirement;
      final double factor1 = pow(1.0 + rMf, k).toDouble();
      final double annuity1 =
          rMf > 0.0 ? (factor1 - 1.0) / rMf : k.toDouble();
      final double balanceAfterPhase1 =
          p0 * factor1 + emiInputs.reducedMonthlyMfSipDuringEmi * annuity1;

      // Phase 2: After EMI ends until retirement with full normal SIP
      final int m = retirementMonths - k;
      if (m > 0) {
        final double factor2 = pow(1.0 + rMf, m).toDouble();
        final double annuity2 =
            rMf > 0.0 ? (factor2 - 1.0) / rMf : m.toDouble();
        squeezedMFCorpus =
            balanceAfterPhase1 * factor2 + fireInputs.monthlyMFSIP * annuity2;
      } else {
        squeezedMFCorpus = balanceAfterPhase1;
      }

      sipSqueezeCorpusDelta = squeezedMFCorpus - unsqueezedMFCorpus;
    }

    // Total available corpus at retirement:
    // If SIP is squeezed, MF portion is squeezedMFCorpus; EPF remains unchanged.
    final double effectiveTotalCorpus = isSipSqueezed
        ? squeezedMFCorpus + fireResults.projectedEPFCorpus
        : fireResults.totalProjectedCorpus;

    final double surplus25xAdjusted =
        effectiveTotalCorpus - adjustedFire25x;
    final double surplus30xAdjusted =
        effectiveTotalCorpus - adjustedFire30x;

    return LiabilitiesEmiResults(
      retirementMonths: retirementMonths,
      emiMonthsBeforeRetirement: emiMonthsBeforeRetirement,
      postRetirementEmiMonths: postRetirementEmiMonths,
      totalMonthlyEmi: totalMonthlyEmi,
      postRetirementEmiPv: postRetirementEmiPv,
      lifestyleFire25x: lifestyleFire25x,
      lifestyleFire30x: lifestyleFire30x,
      adjustedFire25x: adjustedFire25x,
      adjustedFire30x: adjustedFire30x,
      totalCorpus: effectiveTotalCorpus,
      surplus25xAdjusted: surplus25xAdjusted,
      surplus30xAdjusted: surplus30xAdjusted,
      unsqueezedMFCorpus: unsqueezedMFCorpus,
      squeezedMFCorpus: squeezedMFCorpus,
      sipSqueezeCorpusDelta: sipSqueezeCorpusDelta,
      hasPostRetirementEmi: postRetirementEmiMonths > 0 && postRetirementEmiPv > 0,
      isSipSqueezed: isSipSqueezed,
    );
  }
}
