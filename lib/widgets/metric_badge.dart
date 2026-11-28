import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class MetricBadge extends StatelessWidget {
  final double surplus;
  final String labelPrefix;
  final bool compact;

  const MetricBadge({
    super.key,
    required this.surplus,
    this.labelPrefix = '',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = surplus >= 0;
    final Color color = isPositive ? AppTheme.surplusGreen : AppTheme.shortfallRed;
    final Color bgColor = isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final IconData icon = isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    final String text = '${labelPrefix.isNotEmpty ? "$labelPrefix: " : ""}${isPositive ? "+" : ""}${CurrencyFormatter.formatCompactINR(surplus)} ${isPositive ? "Surplus" : "Deficit"}';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: compact ? 13 : 16),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 10 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
