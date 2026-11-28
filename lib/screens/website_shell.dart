import 'package:flutter/material.dart';
import '../controllers/fire_calculator_controller.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'main_navigation_screen.dart';

enum WebsiteTab {
  fireCalculator,
  financialPlanning,
  patentFiling,
  aboutUs,
}

extension WebsiteTabDetails on WebsiteTab {
  String get title {
    switch (this) {
      case WebsiteTab.fireCalculator:
        return 'FIRE Calculator';
      case WebsiteTab.financialPlanning:
        return 'Financial Planning';
      case WebsiteTab.patentFiling:
        return 'Patent Filing';
      case WebsiteTab.aboutUs:
        return 'About Us';
    }
  }

  IconData get icon {
    switch (this) {
      case WebsiteTab.fireCalculator:
        return Icons.calculate_rounded;
      case WebsiteTab.financialPlanning:
        return Icons.trending_up_rounded;
      case WebsiteTab.patentFiling:
        return Icons.verified_rounded;
      case WebsiteTab.aboutUs:
        return Icons.info_outline_rounded;
    }
  }

  String get description {
    switch (this) {
      case WebsiteTab.fireCalculator:
        return 'Institutional financial independence and early retirement simulator for Indian HNIs and professionals.';
      case WebsiteTab.financialPlanning:
        return 'Comprehensive cashflow projections, multi-goal wealth allocation, estate planning, and tax optimization.';
      case WebsiteTab.patentFiling:
        return 'End-to-end intellectual property protection, automated provisional drafting, prior art search, and portfolio docketing.';
      case WebsiteTab.aboutUs:
        return 'Learn about Ananya’s mission, technological architecture, engineering principles, and wealth advisory framework.';
    }
  }

  List<String> get upcomingFeatures {
    switch (this) {
      case WebsiteTab.fireCalculator:
        return [];
      case WebsiteTab.financialPlanning:
        return [
          'Dynamic multi-scenario cashflow & liquidity stress testing',
          'Tax-efficient asset location & harvesting strategies',
          'Automated rebalancing thresholds across equities and fixed income',
          'Custom estate distribution & trust modeling',
        ];
      case WebsiteTab.patentFiling:
        return [
          'AI-assisted provisional patent specification drafting',
          'Automated global prior art & citation search engine',
          'Indian Patent Office (IPO) & PCT filing status docketing',
          'IP portfolio valuation and annuity renewal tracker',
        ];
      case WebsiteTab.aboutUs:
        return [
          'Founding story & executive team credentials',
          'Core investment philosophy & mathematical models',
          'Security, privacy, and local-first data architecture',
          'Client advisory services & institutional partnerships',
        ];
    }
  }
}

class WebsiteShell extends StatefulWidget {
  final FireCalculatorController controller;
  final AuthService? authService;

  const WebsiteShell({
    super.key,
    required this.controller,
    this.authService,
  });

  @override
  State<WebsiteShell> createState() => _WebsiteShellState();
}

class _WebsiteShellState extends State<WebsiteShell> {
  WebsiteTab _activeTab = WebsiteTab.fireCalculator;

  void _onTabSelected(WebsiteTab tab) {
    if (tab == WebsiteTab.fireCalculator) {
      setState(() {
        _activeTab = tab;
      });
      return;
    }

    setState(() {
      _activeTab = tab;
    });

    // Prompt requested: "On clicking other tags it should popup under construction."
    _showUnderConstructionDialog(context, tab);
  }

  void _showUnderConstructionDialog(BuildContext context, WebsiteTab tab) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.construction_rounded,
                color: Color(0xFFD97706),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Under Construction',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  Text(
                    tab.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The ${tab.title} module is currently under active construction and will launch in an upcoming release.',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textDark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PLANNED CAPABILITIES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...tab.upcomingFeatures.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textDark,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Stay on this Page',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.calculate_rounded, size: 16),
            label: const Text(
              'Back to FIRE Calculator',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _activeTab = WebsiteTab.fireCalculator;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBanner(context),
            Expanded(
              child: _buildActiveTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isCompact = width < 920;

        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.primaryNavy,
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF1E293B),
                width: 1,
              ),
            ),
          ),
          child: isCompact ? _buildCompactBanner() : _buildDesktopBanner(),
        );
      },
    );
  }

  Widget _buildDesktopBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Brand Logo & Title
          _buildBrandHeader(),
          const SizedBox(width: 16),
          // Four Navigation Tabs (never overflows horizontally)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: false,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: WebsiteTab.values.map((tab) => _buildTabItem(tab)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBanner() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Row(
            children: [
              _buildBrandHeader(),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: WebsiteTab.values.map((tab) => _buildTabItem(tab)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandHeader() {
    return InkWell(
      onTap: () => _onTabSelected(WebsiteTab.fireCalculator),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Ananya's",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PORTAL',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(WebsiteTab tab) {
    final bool isSelected = _activeTab == tab;

    return InkWell(
      onTap: () => _onTabSelected(tab),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icon,
              size: 15,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 7),
            Text(
              tab.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case WebsiteTab.fireCalculator:
        return _buildFireCalculatorContent();
      case WebsiteTab.financialPlanning:
      case WebsiteTab.patentFiling:
      case WebsiteTab.aboutUs:
        return _buildUnderConstructionContent(_activeTab);
    }
  }

  Widget _buildFireCalculatorContent() {
    final effectiveAuth = widget.authService;

    if (effectiveAuth != null) {
      return ListenableBuilder(
        listenable: effectiveAuth,
        builder: (context, _) {
          return (effectiveAuth.isLoggedIn || effectiveAuth.isDemoMode)
              ? MainNavigationScreen(
                  controller: widget.controller,
                  authService: effectiveAuth,
                )
              : AuthScreen(authService: effectiveAuth);
        },
      );
    }

    return MainNavigationScreen(controller: widget.controller);
  }

  Widget _buildUnderConstructionContent(WebsiteTab tab) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.construction_rounded,
                      color: Color(0xFFD97706),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'MODULE IN DEVELOPMENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tab.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                tab.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'WHAT IS COMING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryNavy,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              ...tab.upcomingFeatures.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreenLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.calculate_rounded, size: 18),
                    label: const Text(
                      'Return to FIRE Calculator',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _activeTab = WebsiteTab.fireCalculator;
                      });
                    },
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textDark,
                      side: const BorderSide(color: AppTheme.borderLight),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(
                      'Check Status',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      _showUnderConstructionDialog(context, tab);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
