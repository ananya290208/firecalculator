import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String primaryValue;
  final String? subtitle;
  final String? note;
  final IconData? icon;
  final Color? accentColor;
  final Widget? trailingBadge;
  final bool isHighlighted;

  const StatCard({
    super.key,
    required this.title,
    required this.primaryValue,
    this.subtitle,
    this.note,
    this.icon,
    this.accentColor,
    this.trailingBadge,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? AppTheme.primaryGreen;

    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? color.withValues(alpha: 0.04)
            : theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted
              ? color.withValues(alpha: 0.35)
              : AppTheme.borderLight,
          width: isHighlighted ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ),
              ?trailingBadge,
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              primaryValue,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: isHighlighted ? color : null,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              note!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
