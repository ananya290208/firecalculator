import 'dart:math';
import '../models/dashboard_models.dart';
import '../models/fire_inputs.dart';
import '../models/fire_results.dart';
import '../models/liabilities_emi_models.dart';
import '../models/physical_assets_models.dart';

class DashboardService {
  static ComprehensiveFireSummary calculate({
    required FireInputs fireInputs,
    required FireResults fireResults,
    required LiabilitiesEmiInputs emiInputs,
    required LiabilitiesEmiResults emiResults,
    required PhysicalAssetsInputs physicalInputs,
    required PhysicalAssetsResults physicalResults,
  }) {
    // 1. Assets Today
    final double financialAssets = fireInputs.currentMFValue +
        fireInputs.currentEPFBalance +
        physicalResults.totalCashAndDeposits;
    final double realEstateAssets = physicalResults.totalRealEstateValue;
    final double goldAssets = physicalResults.totalGoldValue;
    final double cashAssets = physicalResults.totalCashAndDeposits;

    final double totalGrossAssets =
        fireInputs.currentMFValue +
        fireInputs.currentEPFBalance +
        realEstateAssets +
        goldAssets +
        cashAssets;

    // 2. Liabilities Today
    final double totalOutstandingLiabilities =
        emiInputs.outstandingLoanPrincipal + physicalResults.totalMortgageBalance;
    final double totalNetWorth = totalGrossAssets - totalOutstandingLiabilities;

    // 3. Projected Retirement Horizon
    final double targetYears = fireInputs.targetYears;
    final double projectedMF = emiResults.isSipSqueezed
        ? emiResults.squeezedMFCorpus
        : fireResults.projectedMFCorpus;
    final double projectedEPF = fireResults.projectedEPFCorpus;
    final double baselineFinancialCorpus = projectedMF + projectedEPF;

    final double additionalLiquidAssets =
        physicalResults.totalLiquidPhysicalAdditionsAtRetirement;
    final double totalProjectedFireCorpus =
        baselineFinancialCorpus + additionalLiquidAssets;

    // 4. Living Expenses & Rental Cashflow
    final double futureMonthlyExpenses = fireResults.futureMonthlyExpenses;
    final double futureGrossAnnualExpenses = fireResults.futureAnnualExpenses;
    final double annualRentalIncome = physicalResults.totalAnnualRentalIncome;
    final double netAnnualExpenseDrawdown =
        max(0.0, futureGrossAnnualExpenses - annualRentalIncome);

    // 5. FIRE Targets (Offset by rental cashflow, increased by post-retirement debt PV)
    final double postRetirementEmiPv = emiResults.postRetirementEmiPv;
    final double lifestyleFire25x = netAnnualExpenseDrawdown * 25.0;
    final double lifestyleFire30x = netAnnualExpenseDrawdown * 30.0;
    final double adjustedFire25x = lifestyleFire25x + postRetirementEmiPv;
    final double adjustedFire30x = lifestyleFire30x + postRetirementEmiPv;

    // 6. Surplus / Shortfall & Status
    final double surplus25x = totalProjectedFireCorpus - adjustedFire25x;
    final double surplus30x = totalProjectedFireCorpus - adjustedFire30x;

    final double fundingPercentage25x = adjustedFire25x > 0
        ? (totalProjectedFireCorpus / adjustedFire25x) * 100.0
        : (totalProjectedFireCorpus > 0 ? 100.0 : 0.0);
    final double fundingPercentage30x = adjustedFire30x > 0
        ? (totalProjectedFireCorpus / adjustedFire30x) * 100.0
        : (totalProjectedFireCorpus > 0 ? 100.0 : 0.0);

    String readinessStatus;
    if (totalProjectedFireCorpus <= 0.0 && adjustedFire30x <= 0.0) {
      readinessStatus = 'Awaiting Inputs';
    } else if (fundingPercentage30x >= 100.0) {
      readinessStatus = 'FIRE Ready (Fully Funded)';
    } else if (fundingPercentage25x >= 100.0) {
      readinessStatus = 'Lean FIRE Ready (25x Met)';
    } else if (fundingPercentage25x >= 75.0) {
      readinessStatus = 'Within Reach';
    } else {
      readinessStatus = 'Accumulation Phase';
    }

    // 7. Asset Allocation Breakdown
    final List<AssetAllocationSlice> slices = [];
    if (totalGrossAssets > 0) {
      if (fireInputs.currentMFValue > 0) {
        slices.add(AssetAllocationSlice(
          label: 'Mutual Funds (Equity)',
          amount: fireInputs.currentMFValue,
          percentage: (fireInputs.currentMFValue / totalGrossAssets) * 100.0,
          colorValue: 0xFF0284C7, // Sky Blue
        ));
      }
      if (fireInputs.currentEPFBalance > 0) {
        slices.add(AssetAllocationSlice(
          label: 'EPF / PF Balance',
          amount: fireInputs.currentEPFBalance,
          percentage: (fireInputs.currentEPFBalance / totalGrossAssets) * 100.0,
          colorValue: 0xFFD97706, // Amber
        ));
      }
      if (realEstateAssets > 0) {
        slices.add(AssetAllocationSlice(
          label: 'Real Estate & Properties',
          amount: realEstateAssets,
          percentage: (realEstateAssets / totalGrossAssets) * 100.0,
          colorValue: 0xFF059669, // Emerald
        ));
      }
      if (goldAssets > 0) {
        slices.add(AssetAllocationSlice(
          label: 'Gold (Solid & Ornaments)',
          amount: goldAssets,
          percentage: (goldAssets / totalGrossAssets) * 100.0,
          colorValue: 0xFFEAB308, // Gold Yellow
        ));
      }
      if (cashAssets > 0) {
        slices.add(AssetAllocationSlice(
          label: 'Cash in Hand & FDs',
          amount: cashAssets,
          percentage: (cashAssets / totalGrossAssets) * 100.0,
          colorValue: 0xFF6366F1, // Indigo
        ));
      }
    }

    return ComprehensiveFireSummary(
      totalFinancialAssets: financialAssets,
      totalRealEstateAssets: realEstateAssets,
      totalGoldAssets: goldAssets,
      totalCashAssets: cashAssets,
      totalGrossAssets: totalGrossAssets,
      totalOutstandingLiabilities: totalOutstandingLiabilities,
      totalNetWorth: totalNetWorth,
      targetYears: targetYears,
      projectedMFCorpus: projectedMF,
      projectedEPFCorpus: projectedEPF,
      baselineFinancialCorpus: baselineFinancialCorpus,
      additionalLiquidAssets: additionalLiquidAssets,
      totalProjectedFireCorpus: totalProjectedFireCorpus,
      futureMonthlyExpenses: futureMonthlyExpenses,
      futureGrossAnnualExpenses: futureGrossAnnualExpenses,
      annualRentalIncome: annualRentalIncome,
      netAnnualExpenseDrawdown: netAnnualExpenseDrawdown,
      postRetirementEmiPv: postRetirementEmiPv,
      lifestyleFire25x: lifestyleFire25x,
      lifestyleFire30x: lifestyleFire30x,
      adjustedFire25x: adjustedFire25x,
      adjustedFire30x: adjustedFire30x,
      surplus25x: surplus25x,
      surplus30x: surplus30x,
      fundingPercentage25x: fundingPercentage25x,
      fundingPercentage30x: fundingPercentage30x,
      readinessStatus: readinessStatus,
      allocationSlices: slices,
    );
  }
}
