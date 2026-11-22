import 'package:flutter_test/flutter_test.dart';
import 'package:fire_calculator/models/fire_inputs.dart';
import 'package:fire_calculator/models/liabilities_emi_models.dart';
import 'package:fire_calculator/models/physical_assets_models.dart';
import 'package:fire_calculator/services/dashboard_service.dart';
import 'package:fire_calculator/services/fire_calculator_service.dart';
import 'package:fire_calculator/services/liabilities_emi_service.dart';
import 'package:fire_calculator/services/physical_assets_service.dart';

void main() {
  group('PhysicalAssetsService & DashboardService Tests', () {
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
    const defaultEmiInputs = LiabilitiesEmiInputs();
    final defaultEmiResults = LiabilitiesEmiService.calculate(
      fireInputs: defaultFireInputs,
      fireResults: defaultFireResults,
      emiInputs: defaultEmiInputs,
    );

    test('1. Default empty physical assets results in zero additions and clean baseline Net Worth', () {
      const physicalInputs = PhysicalAssetsInputs();
      final physicalResults = PhysicalAssetsService.calculate(
        inputs: physicalInputs,
        targetYears: 3.0,
      );

      expect(physicalResults.totalRealEstateValue, 0.0);
      expect(physicalResults.totalGoldValue, 0.0);
      expect(physicalResults.totalCashAndDeposits, 0.0);
      expect(physicalResults.totalPhysicalAssets, 0.0);
      expect(physicalResults.totalLiquidPhysicalAdditionsAtRetirement, 0.0);

      final summary = DashboardService.calculate(
        fireInputs: defaultFireInputs,
        fireResults: defaultFireResults,
        emiInputs: defaultEmiInputs,
        emiResults: defaultEmiResults,
        physicalInputs: physicalInputs,
        physicalResults: physicalResults,
      );

      // Baseline Net Worth = MF (3.50 Cr) + EPF (50L) = 4.00 Cr
      expect(summary.totalGrossAssets, 40000000.0);
      expect(summary.totalOutstandingLiabilities, 0.0);
      expect(summary.totalNetWorth, 40000000.0);
      expect(summary.totalProjectedFireCorpus, defaultFireResults.totalProjectedCorpus);
      expect(summary.lifestyleFire25x, defaultFireResults.fireTarget25x);
      expect(summary.lifestyleFire30x, defaultFireResults.fireTarget30x);
    });

    test('2. Real estate (Land & Apartments with/without mortgage) and rental income offsets', () {
      final physicalInputs = PhysicalAssetsInputs(
        lands: [
          const LandProperty(
            id: 'land_1',
            name: 'Plot in Bengaluru',
            marketValue: 8000000.0, // 80 Lakhs
            expectedAppreciationRate: 0.06,
            monetizeAtRetirement: true, // sell at retirement
          ),
        ],
        apartments: [
          // Self-occupied apartment with mortgage
          const ApartmentProperty(
            id: 'apt_primary',
            name: 'Primary Residence (3BHK)',
            marketValue: 15000000.0, // 1.50 Cr
            hasMortgage: true,
            mortgageBalance: 6000000.0, // 60 Lakhs
            monthlyEmi: 55000.0,
            remainingEmiMonths: 180,
            isSelfOccupied: true, // primary home, not sold
            monetizeAtRetirement: false,
          ),
          // Investment apartment generating rent, without mortgage
          const ApartmentProperty(
            id: 'apt_rental',
            name: 'Rental Flat',
            marketValue: 7000000.0, // 70 Lakhs
            hasMortgage: false,
            monthlyRentalIncome: 25000.0, // 25k/mo rent
            isSelfOccupied: false,
            monetizeAtRetirement: false, // hold for rent
          ),
        ],
        gold: const GoldAssets(
          solidGoldValue: 2000000.0, // 20 Lakhs SGB/bullion
          ornamentsGoldValue: 1500000.0, // 15 Lakhs jewellery
          expectedReturn: 0.08,
          includeSolidInFireCorpus: true,
          includeOrnamentsInFireCorpus: false, // keep ornaments outside liquid corpus
        ),
        cash: const CashAssets(
          cashInHand: 500000.0, // 5 Lakhs
          fixedDeposits: 2500000.0, // 25 Lakhs
          expectedReturn: 0.065,
        ),
      );

      final physicalResults = PhysicalAssetsService.calculate(
        inputs: physicalInputs,
        targetYears: 3.0,
      );

      // Real estate totals: 80L + 1.5Cr + 70L = 3.00 Cr
      expect(physicalResults.totalLandValue, 8000000.0);
      expect(physicalResults.totalApartmentValue, 22000000.0);
      expect(physicalResults.totalRealEstateValue, 30000000.0);
      expect(physicalResults.totalMortgageBalance, 6000000.0);
      expect(physicalResults.totalMonthlyRentalIncome, 25000.0);
      expect(physicalResults.totalAnnualRentalIncome, 300000.0);

      // Gold: 20L solid + 15L ornaments = 35 Lakhs
      expect(physicalResults.solidGoldValue, 2000000.0);
      expect(physicalResults.ornamentsGoldValue, 1500000.0);
      expect(physicalResults.totalGoldValue, 3500000.0);

      // Cash: 5L + 25L = 30 Lakhs
      expect(physicalResults.totalCashAndDeposits, 3000000.0);

      // Total physical assets = 3.00 Cr (RE) + 35L (Gold) + 30L (Cash) = 3.65 Cr
      expect(physicalResults.totalPhysicalAssets, 36500000.0);

      // Net physical equity = 3.65 Cr - 60L mortgage = 3.05 Cr
      expect(physicalResults.netPhysicalEquity, 30500000.0);

      // Liquid additions at retirement:
      // Monetized land: 80L * (1.06)^3 = ~95.28 Lakhs
      // Solid gold: 20L * (1.08)^3 = ~25.19 Lakhs
      // Cash/FDs: 30L * (1.065)^3 = ~36.24 Lakhs
      // Total additions = ~1.567 Cr
      expect(physicalResults.liquidRealEstateAtRetirement, greaterThan(9500000.0));
      expect(physicalResults.liquidGoldAtRetirement, greaterThan(2500000.0));
      expect(physicalResults.liquidCashAtRetirement, greaterThan(3600000.0));

      final summary = DashboardService.calculate(
        fireInputs: defaultFireInputs,
        fireResults: defaultFireResults,
        emiInputs: defaultEmiInputs,
        emiResults: defaultEmiResults,
        physicalInputs: physicalInputs,
        physicalResults: physicalResults,
      );

      // Total Gross Assets = MF (3.5Cr) + EPF (50L) + RE (3Cr) + Gold (35L) + Cash (30L) = 7.65 Cr
      expect(summary.totalGrossAssets, 76500000.0);
      expect(summary.totalOutstandingLiabilities, 6000000.0); // mortgage
      expect(summary.totalNetWorth, 70500000.0); // 7.05 Cr Net Worth

      // Rental income (₹3 Lakhs/year) offsets future annual living expenses
      expect(summary.annualRentalIncome, 300000.0);
      expect(summary.netAnnualExpenseDrawdown, defaultFireResults.futureAnnualExpenses - 300000.0);
      // Because expenses are lower, lifestyle FIRE target is lower than un-offset baseline!
      expect(summary.lifestyleFire25x, lessThan(defaultFireResults.fireTarget25x));
    });
  });
}
