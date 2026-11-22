# FIRE Readiness & Scenario Simulator (Flutter App)

A cross-platform Flutter application (iOS & Android) that replicates the functionality, mathematical formulas, and scenario modeling of the **Interactive FIRE Readiness & Scenario Simulator (`Interactive_FIRE_Calculator.xlsx`)**.

---

## 🚀 Key Features

### 1. Section 1: Inputs & Assumptions (Editable Yellow Cells)
- **Target Years to Retirement**: e.g., 3, 5, 6, 7 years
- **Current Monthly Expenses (Today)**: e.g., ₹1,25,000 or ₹2,00,000
- **Expected Inflation Rate (% p.a.)**: Default 6.00%
- **Current Mutual Fund Value (₹)**: Default ₹3.50 Cr (or ₹3.40 Cr)
- **Current MF Cost Basis (₹)**: Used for LTCG tax estimate (₹2.10 Cr)
- **Monthly Mutual Fund SIP (₹)**: Ongoing monthly SIP (₹90,000)
- **Expected MF Return (% p.a.)**: Default 12.00% (or 14.00%)
- **Current EPF Balance (₹)**: Current EPF balance (₹50 Lakhs)
- **Monthly EPF Contribution (₹)**: Employee + Employer total (₹50,000)
- **Expected EPF Return (% p.a.)**: EPF statutory rate (8.25%)
- **Upfront MF Cash-Out / Withdrawal (%)**: Optional (e.g., 0% or 6%)
- **LTCG Tax Rate on Equity Gains (%)**: Standard 12.5% on gains > ₹1.25L/yr

### 2. Section 2: Live Retirement Readiness Outputs
- **Net Reinvested MF Principal (₹)**: `Current MF * (1 - Cash-Out %)`
- **Future Monthly Expenses at Retirement**: `Monthly Exp * (1 + Inflation)^Years`
- **Future Annual Expenses at Retirement**: `Future Monthly * 12`
- **Projected Mutual Fund Corpus (₹)**: `FV(MF_Return / 12, Years * 12, -MF_SIP, -Net_MF_Principal, 0)`
- **Projected EPF Corpus (₹)**: `FV(EPF_Return / 12, Years * 12, -EPF_SIP, -Current_EPF, 0)`
- **TOTAL PROJECTED CORPUS (Pre-Tax)**: `Projected MF + Projected EPF`
- **Total Corpus in ₹ Crores**: `Total Corpus / 1,00,00,000`
- **FIRE Target — 25x Rule (4.0% SWR)**: `Future Annual Exp * 25`
- **Surplus / (Shortfall) vs. 25x Target**: `Total Corpus - 25x Target`
- **FIRE Target — 30x Rule (3.33% SWR)**: `Future Annual Exp * 30`
- **Surplus / (Shortfall) vs. 30x Target**: `Total Corpus - 30x Target`
- **Est. Post-Tax Corpus (Full MF Exit)**:
  `Total Corpus - MAX(0, (Projected MF - Cost Basis - Total SIPs - 1,25,000) * 12.5%)`

### 3. Section 3: Year-by-Year Projection Schedule (Years 0 to 10)
- Table and interactive chart showing year-by-year accumulation from Year 0 to 10.
- Tracks Projected MF, Projected EPF, Total Corpus, Annual Inflated Expenses, 25x Target line, and 30x Target line.
- Highlights the user's selected retirement horizon milestone.

### 4. Sheet 2: Pre-Built Horizon & Expense Scenario Matrix
- Replicates the 6 pre-built stress-test scenarios from Sheet 2 of the Excel workbook:
  1. 3-Year Horizon — Base Expense (₹1.25L/mo)
  2. 3-Year Horizon — Upper Expense (₹2.00L/mo)
  3. 6-Year Horizon — Base Expense (₹1.25L/mo)
  4. 6-Year Horizon — Upper Expense (₹2.00L/mo)
  5. 7-Year Horizon — Base Expense (₹1.25L/mo)
  6. 7-Year Horizon — Upper Expense (₹2.00L/mo)
- Direct **"Load Into Live Simulator"** button on each scenario card.

### 5. Last 5 Combinations Comparison Dashboard
- Automatically retains the **last 5 unique combinations** attempted by the user.
- Persisted locally using `shared_preferences` across app restarts.
- Side-by-side comparison table across all 5 combinations (Horizon, Expenses, SIPs, Projected Corpus, 25x Gap, 30x Gap, Post-tax Corpus).
- One-click **"Restore"** button to load any past combination back into the live simulator.

---

## 🛠️ Getting Started

### Prerequisites
- Flutter SDK (3.13+ or higher)
- Android Studio / Xcode (for running on Android & iOS devices/emulators)

### Running on Android
```bash
flutter run -d android
```

### Running on iOS
```bash
flutter run -d ios
```

### Running on Desktop (Windows) or Web
```bash
flutter run -d windows
# or
flutter run -d chrome
```

### Running Unit & Widget Tests
```bash
flutter test
```
All 7 unit and widget tests verify 100% calculation accuracy against the Excel model.
