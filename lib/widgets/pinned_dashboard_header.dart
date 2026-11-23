import 'dart:math';
import 'package:flutter/material.dart';
import '../controllers/fire_calculator_controller.dart';
import '../models/dashboard_models.dart';
import '../utils/currency_formatter.dart';

/// Fixed sticky top banner that displays the Comprehensive FIRE Dashboard metrics
/// across all tabs and sections, updating in real time as the user edits any input field.
class PinnedDashboardHeader extends StatefulWidget {
  final FireCalculatorController controller;

  const PinnedDashboardHeader({
    super.key,
    required this.controller,
  });

  @override
  State<PinnedDashboardHeader> createState() => _PinnedDashboardHeaderState();
}

class _PinnedDashboardHeaderState extends State<PinnedDashboardHeader> {
  bool _isExpandedOnMobile = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final summary = widget.controller.dashboardSummary;

        return LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final bool isMobile = width < 600;
            final bool isTablet = width >= 600 && width < 1024;

            if (isMobile) {
              return _buildMobileBanner(summary);
            } else if (isTablet) {
              return _buildTabletBanner(summary);
            } else {
              return _buildDesktopBanner(summary);
            }
          },
        );
      },
    );
  }

  /// Desktop View (width >= 1024): Premium executive 3-column banner with instant horizon selector
  Widget _buildDesktopBanner(ComprehensiveFireSummary summary) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: const Border(
          bottom: BorderSide(color: Color(0xFF14B8A6), width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar: Title + Horizon Pills + Readiness Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.insights_rounded, color: Color(0xFF2DD4BF), size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'COMPREHENSIVE FIRE EXECUTIVE DASHBOARD',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FIXED LIVE TRACKER',
                          style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHorizonChips(summary.targetYears),
                      const SizedBox(width: 14),
                      _buildReadinessBadge(summary),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Bottom Row: 3 Primary Metrics
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Total Net Worth Today
                  Expanded(
                    flex: 30,
                    child: _buildMetricTile(
                      label: 'TOTAL NET WORTH TODAY',
                      primaryValue: CurrencyFormatter.formatCrores(summary.totalNetWorth / 10000000.0),
                      secondaryValue: CurrencyFormatter.formatINR(summary.totalNetWorth),
                      color: Colors.white,
                    ),
                  ),

                  Container(width: 1, height: 42, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 16)),

                  // 2. Projected FIRE Corpus at Target Year
                  Expanded(
                    flex: 32,
                    child: _buildMetricTile(
                      label: 'PROJECTED CORPUS (YR ${summary.targetYears.toInt()})',
                      primaryValue: CurrencyFormatter.formatCrores(summary.totalProjectedFireCorpus / 10000000.0),
                      secondaryValue: CurrencyFormatter.formatINR(summary.totalProjectedFireCorpus),
                      color: const Color(0xFF34D399),
                    ),
                  ),

                  Container(width: 1, height: 42, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 16)),

                  // 3. 30x Target & Funding Progress
                  Expanded(
                    flex: 38,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '30x Target: ${CurrencyFormatter.formatCrores(summary.adjustedFire30x / 10000000.0)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Funded: ${summary.fundingPercentage30x.toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              summary.surplus30x >= 0
                                  ? 'Surplus: +${CurrencyFormatter.formatCompactINR(summary.surplus30x)}'
                                  : 'Gap: ${CurrencyFormatter.formatCompactINR(summary.surplus30x)}',
                              style: TextStyle(
                                color: summary.surplus30x >= 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: min(1.0, summary.fundingPercentage30x / 100.0),
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              summary.isFireReady ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tablet View (600 <= width < 1024)
  Widget _buildTabletBanner(ComprehensiveFireSummary summary) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: const Border(
          bottom: BorderSide(color: Color(0xFF14B8A6), width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Row: Title + Horizon Pills + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insights_rounded, color: Color(0xFF2DD4BF), size: 15),
                  SizedBox(width: 6),
                  Text(
                    'COMPREHENSIVE FIRE DASHBOARD',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHorizonChips(summary.targetYears),
                  const SizedBox(width: 8),
                  _buildReadinessBadge(summary),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'NET WORTH TODAY',
                  primaryValue: CurrencyFormatter.formatCrores(summary.totalNetWorth / 10000000.0),
                  secondaryValue: CurrencyFormatter.formatINR(summary.totalNetWorth),
                  color: Colors.white,
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 10)),
              Expanded(
                child: _buildMetricTile(
                  label: 'PROJ. CORPUS (YR ${summary.targetYears.toInt()})',
                  primaryValue: CurrencyFormatter.formatCrores(summary.totalProjectedFireCorpus / 10000000.0),
                  secondaryValue: CurrencyFormatter.formatINR(summary.totalProjectedFireCorpus),
                  color: const Color(0xFF34D399),
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 10)),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '30x: ${summary.fundingPercentage30x.toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          summary.surplus30x >= 0
                              ? '+${CurrencyFormatter.formatCompactINR(summary.surplus30x)}'
                              : CurrencyFormatter.formatCompactINR(summary.surplus30x),
                          style: TextStyle(
                            color: summary.surplus30x >= 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: min(1.0, summary.fundingPercentage30x / 100.0),
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          summary.isFireReady ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mobile View (width < 600): Sleek, space-efficient sticky header with expand/collapse toggle
  Widget _buildMobileBanner(ComprehensiveFireSummary summary) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: const Border(
          bottom: BorderSide(color: Color(0xFF14B8A6), width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Compact Title + Readiness + Horizon + Expand Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insights_rounded, color: Color(0xFF2DD4BF), size: 14),
                  const SizedBox(width: 5),
                  const Text(
                    'FIRE DASHBOARD',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _buildReadinessBadge(summary, compact: true),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMobileHorizonDropdown(summary.targetYears),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isExpandedOnMobile = !_isExpandedOnMobile;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        _isExpandedOnMobile ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Primary Figures Row (Always visible)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NET WORTH', style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.w600)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.formatCrores(summary.totalNetWorth / 10000000.0),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 26, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CORPUS (YR ${summary.targetYears.toInt()})', style: const TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.w600)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.formatCrores(summary.totalProjectedFireCorpus / 10000000.0),
                        style: const TextStyle(color: Color(0xFF34D399), fontSize: 15, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 26, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '30x: ${summary.fundingPercentage30x.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      summary.surplus30x >= 0
                          ? '+${CurrencyFormatter.formatCompactINR(summary.surplus30x)}'
                          : CurrencyFormatter.formatCompactINR(summary.surplus30x),
                      style: TextStyle(
                        color: summary.surplus30x >= 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // If Expanded on Mobile: Show additional details
          if (_isExpandedOnMobile) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '30x Target: ${CurrencyFormatter.formatCrores(summary.adjustedFire30x / 10000000.0)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                Text(
                  'Total Net Worth: ${CurrencyFormatter.formatINR(summary.totalNetWorth)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ],

          const SizedBox(height: 5),
          // Slim Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: min(1.0, summary.fundingPercentage30x / 100.0),
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                summary.isFireReady ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String primaryValue,
    required String secondaryValue,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            primaryValue,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            secondaryValue,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildReadinessBadge(ComprehensiveFireSummary summary, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
      decoration: BoxDecoration(
        color: summary.isFireReady
            ? const Color(0xFF10B981).withOpacity(0.9)
            : const Color(0xFFF59E0B).withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        summary.readinessStatus,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 9 : 10,
        ),
      ),
    );
  }

  Widget _buildHorizonChips(double currentYears) {
    final horizons = [1.0, 3.0, 5.0, 7.0, 10.0];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Horizon: ',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white60),
        ),
        ...horizons.map((yr) {
          final isSelected = (currentYears - yr).abs() < 0.1;
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: InkWell(
              onTap: () {
                widget.controller.updateField(targetYears: yr);
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF14B8A6) : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${yr.toInt()}Y',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMobileHorizonDropdown(double currentYears) {
    final horizons = [1.0, 3.0, 5.0, 7.0, 10.0, 15.0];
    final selectedYear = horizons.firstWhere(
      (h) => (h - currentYears).abs() < 0.1,
      orElse: () => currentYears,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: horizons.contains(selectedYear) ? selectedYear : horizons[1],
          isDense: true,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
          items: horizons.map((yr) {
            return DropdownMenuItem<double>(
              value: yr,
              child: Text('${yr.toInt()} Yrs', style: const TextStyle(fontSize: 10)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              widget.controller.updateField(targetYears: val);
            }
          },
        ),
      ),
    );
  }
}
