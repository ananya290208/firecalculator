import '../models/physical_assets_models.dart';

class PhysicalAssetsService {
  static PhysicalAssetsResults calculate({
    required PhysicalAssetsInputs inputs,
    required double targetYears,
  }) {
    // 1. Real Estate (Land & Apartments)
    double totalLandValue = 0.0;
    double projectedLandAtRetirement = 0.0;
    double liquidLandAtRetirement = 0.0;
    double landRentalIncomeMonthly = 0.0;

    for (final land in inputs.lands) {
      totalLandValue += land.marketValue;
      final proj = land.projectedValueAt(targetYears);
      projectedLandAtRetirement += proj;
      if (land.monetizeAtRetirement) {
        liquidLandAtRetirement += proj;
      }
      landRentalIncomeMonthly += land.monthlyRentalIncome;
    }

    double totalApartmentValue = 0.0;
    double totalMortgageBalance = 0.0;
    double totalApartmentMonthlyEmi = 0.0;
    double projectedApartmentAtRetirement = 0.0;
    double liquidApartmentAtRetirement = 0.0;
    double apartmentRentalIncomeMonthly = 0.0;

    for (final apt in inputs.apartments) {
      totalApartmentValue += apt.marketValue;
      if (apt.hasMortgage) {
        totalMortgageBalance += apt.mortgageBalance;
        totalApartmentMonthlyEmi += apt.monthlyEmi;
      }
      final proj = apt.projectedValueAt(targetYears);
      projectedApartmentAtRetirement += proj;

      // If monetized at retirement and not self-occupied primary residence
      if (apt.monetizeAtRetirement && !apt.isSelfOccupied) {
        // Equity at retirement = projected value - remaining mortgage (if any)
        liquidApartmentAtRetirement += proj;
      }

      if (!apt.isSelfOccupied) {
        apartmentRentalIncomeMonthly += apt.monthlyRentalIncome;
      }
    }

    final double totalRealEstateValue = totalLandValue + totalApartmentValue;
    final double totalMonthlyRentalIncome =
        landRentalIncomeMonthly + apartmentRentalIncomeMonthly;
    final double totalAnnualRentalIncome = totalMonthlyRentalIncome * 12.0;
    final double projectedRealEstateValueAtRetirement =
        projectedLandAtRetirement + projectedApartmentAtRetirement;
    final double liquidRealEstateAtRetirement =
        liquidLandAtRetirement + liquidApartmentAtRetirement;

    // 2. Gold Holdings
    final double solidGoldValue = inputs.gold.solidGoldValue;
    final double ornamentsGoldValue = inputs.gold.ornamentsGoldValue;
    final double totalGoldValue = solidGoldValue + ornamentsGoldValue;

    final double projectedSolidGoldAtRetirement =
        inputs.gold.projectedSolidGoldAt(targetYears);
    final double projectedOrnamentsAtRetirement =
        inputs.gold.projectedOrnamentsGoldAt(targetYears);

    double liquidGoldAtRetirement = 0.0;
    if (inputs.gold.includeSolidInFireCorpus) {
      liquidGoldAtRetirement += projectedSolidGoldAtRetirement;
    }
    if (inputs.gold.includeOrnamentsInFireCorpus) {
      liquidGoldAtRetirement += projectedOrnamentsAtRetirement;
    }

    // 3. Cash & Equivalents
    final double cashInHand = inputs.cash.cashInHand;
    final double fixedDeposits = inputs.cash.fixedDeposits;
    final double totalCashAndDeposits = cashInHand + fixedDeposits;

    final double projectedCashAtRetirement =
        inputs.cash.projectedCashAt(targetYears);
    final double liquidCashAtRetirement = projectedCashAtRetirement;

    // 4. Aggregate Totals
    final double totalPhysicalAssets =
        totalRealEstateValue + totalGoldValue + totalCashAndDeposits;
    final double totalPhysicalLiabilities = totalMortgageBalance;
    final double netPhysicalEquity = totalPhysicalAssets - totalPhysicalLiabilities;

    final double totalLiquidPhysicalAdditionsAtRetirement =
        liquidRealEstateAtRetirement + liquidGoldAtRetirement + liquidCashAtRetirement;

    return PhysicalAssetsResults(
      totalLandValue: totalLandValue,
      totalApartmentValue: totalApartmentValue,
      totalRealEstateValue: totalRealEstateValue,
      totalMortgageBalance: totalMortgageBalance,
      totalApartmentMonthlyEmi: totalApartmentMonthlyEmi,
      totalMonthlyRentalIncome: totalMonthlyRentalIncome,
      totalAnnualRentalIncome: totalAnnualRentalIncome,
      solidGoldValue: solidGoldValue,
      ornamentsGoldValue: ornamentsGoldValue,
      totalGoldValue: totalGoldValue,
      cashInHand: cashInHand,
      fixedDeposits: fixedDeposits,
      totalCashAndDeposits: totalCashAndDeposits,
      totalPhysicalAssets: totalPhysicalAssets,
      totalPhysicalLiabilities: totalPhysicalLiabilities,
      netPhysicalEquity: netPhysicalEquity,
      projectedRealEstateValueAtRetirement: projectedRealEstateValueAtRetirement,
      projectedSolidGoldAtRetirement: projectedSolidGoldAtRetirement,
      projectedCashAtRetirement: projectedCashAtRetirement,
      liquidRealEstateAtRetirement: liquidRealEstateAtRetirement,
      liquidGoldAtRetirement: liquidGoldAtRetirement,
      liquidCashAtRetirement: liquidCashAtRetirement,
      totalLiquidPhysicalAdditionsAtRetirement:
          totalLiquidPhysicalAdditionsAtRetirement,
    );
  }
}
