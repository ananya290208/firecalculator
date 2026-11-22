import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrDecimalFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Formats a value as Indian Rupees (e.g., ₹1,25,000 or ₹3,50,00,000)
  static String formatINR(double amount, {bool showDecimals = false}) {
    if (showDecimals) {
      return _inrDecimalFormatter.format(amount);
    }
    return _inrFormatter.format(amount.roundToDouble());
  }

  /// Compact Indian notation:
  /// e.g. 35,000,000 -> ₹3.50 Cr
  ///      5,000,000  -> ₹50.00 L
  ///      1,25,000   -> ₹1.25 L
  static String formatCompactINR(double amount, {int decimals = 2}) {
    final double absVal = amount.abs();
    final String sign = amount < 0 ? '-' : '';

    if (absVal >= 10000000.0) {
      final double cr = absVal / 10000000.0;
      return '$sign₹${cr.toStringAsFixed(decimals)} Cr';
    } else if (absVal >= 100000.0) {
      final double lk = absVal / 100000.0;
      return '$sign₹${lk.toStringAsFixed(decimals)} L';
    } else if (absVal >= 1000.0) {
      final double k = absVal / 1000.0;
      return '$sign₹${k.toStringAsFixed(decimals)} K';
    } else {
      return '$sign₹${absVal.toStringAsFixed(0)}';
    }
  }

  /// Formats Crores directly with suffix (e.g. 6.24 Cr)
  static String formatCrores(double crores, {int decimals = 2}) {
    return '₹${crores.toStringAsFixed(decimals)} Cr';
  }

  /// Formats percentage (e.g. 0.06 -> 6.00%)
  static String formatPercentage(double rate, {int decimals = 2}) {
    return '${(rate * 100).toStringAsFixed(decimals)}%';
  }

  /// Formats a surplus or shortfall badge text and sign:
  /// e.g. +₹1.77 Cr (Surplus) or -₹35.00 L (Deficit)
  static String formatSurplusBadge(double surplus) {
    if (surplus >= 0) {
      return '+${formatCompactINR(surplus)} Surplus';
    } else {
      return '-${formatCompactINR(surplus.abs())} Shortfall';
    }
  }
}
