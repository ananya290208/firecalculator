import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

enum InputType { currency, percentage, years }

class CurrencyInputField extends StatefulWidget {
  final String label;
  final String guidance;
  final double initialValue;
  final InputType type;
  final ValueChanged<double> onChanged;
  final double? step;
  final double? min;
  final double? max;
  final List<double>? quickChips;

  const CurrencyInputField({
    super.key,
    required this.label,
    required this.guidance,
    required this.initialValue,
    required this.type,
    required this.onChanged,
    this.step,
    this.min,
    this.max,
    this.quickChips,
  });

  @override
  State<CurrencyInputField> createState() => _CurrencyInputFieldState();
}

class _CurrencyInputFieldState extends State<CurrencyInputField> {
  late TextEditingController _controller;
  late double _currentVal;

  @override
  void initState() {
    super.initState();
    _currentVal = widget.initialValue;
    _controller = TextEditingController(text: _formatValueForInput(_currentVal));
  }

  @override
  void didUpdateWidget(covariant CurrencyInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.initialValue - widget.initialValue).abs() > 0.0001 &&
        (widget.initialValue - _currentVal).abs() > 0.0001) {
      _currentVal = widget.initialValue;
      _controller.text = _formatValueForInput(_currentVal);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatValueForInput(double val) {
    if (val == 0.0) return '';
    if (widget.type == InputType.percentage) {
      return (val * 100).toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    } else if (widget.type == InputType.years) {
      return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);
    } else {
      return val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(2);
    }
  }

  void _onSubmitted(String text) {
    if (text.trim().isEmpty) {
      setState(() {
        _currentVal = 0.0;
        _controller.text = '';
      });
      widget.onChanged(0.0);
      return;
    }
    final parsed = double.tryParse(text.replaceAll(',', '').trim());
    if (parsed != null) {
      double finalVal = parsed;
      if (widget.type == InputType.percentage) {
        finalVal = parsed / 100.0;
      }
      if (widget.min != null && finalVal < widget.min!) finalVal = widget.min!;
      if (widget.max != null && finalVal > widget.max!) finalVal = widget.max!;
      setState(() {
        _currentVal = finalVal;
        _controller.text = _formatValueForInput(_currentVal);
      });
      widget.onChanged(finalVal);
    }
  }

  void _adjust(double delta) {
    double newVal = _currentVal + delta;
    if (widget.min != null && newVal < widget.min!) newVal = widget.min!;
    if (widget.max != null && newVal > widget.max!) newVal = widget.max!;
    setState(() {
      _currentVal = newVal;
      _controller.text = _formatValueForInput(_currentVal);
    });
    widget.onChanged(newVal);
  }

  String _getConvertedSubtitle() {
    if (_currentVal == 0.0) {
      if (widget.type == InputType.currency) return '= ₹0';
      if (widget.type == InputType.percentage) return '= 0.00%';
      return '= 0 Yrs';
    }
    if (widget.type == InputType.currency) {
      return '= ${CurrencyFormatter.formatCompactINR(_currentVal)}';
    } else if (widget.type == InputType.percentage) {
      return '= ${CurrencyFormatter.formatPercentage(_currentVal)}';
    } else {
      return '= ${_currentVal % 1 == 0 ? _currentVal.toInt() : _currentVal.toStringAsFixed(1)} Yrs';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefixText = widget.type == InputType.currency
        ? '₹ '
        : widget.type == InputType.percentage
            ? '% '
            : '';
    final suffixText = widget.type == InputType.years ? ' Yrs' : '';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.guidance,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton.filledTonal(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                      icon: const Icon(Icons.remove, size: 14),
                      onPressed: () {
                        final step = widget.step ??
                            (widget.type == InputType.percentage
                                ? 0.005
                                : widget.type == InputType.years
                                    ? 1.0
                                    : 10000.0);
                        _adjust(-step);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 32),
                      child: TextField(
                        controller: _controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: widget.type == InputType.currency
                              ? '0'
                              : widget.type == InputType.percentage
                                  ? '0%'
                                  : '0',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey.shade400,
                          ),
                          prefixText: prefixText,
                          suffixText: suffixText,
                          prefixStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          suffixStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.borderLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.primaryNavy, width: 1.5),
                          ),
                        ),
                        onSubmitted: _onSubmitted,
                        onChanged: (text) {
                          if (text.trim().isEmpty) {
                            _currentVal = 0.0;
                            widget.onChanged(0.0);
                            return;
                          }
                          final parsed = double.tryParse(text.replaceAll(',', '').trim());
                          if (parsed != null) {
                            double finalVal = parsed;
                            if (widget.type == InputType.percentage) {
                              finalVal = parsed / 100.0;
                            }
                            _currentVal = finalVal;
                            widget.onChanged(finalVal);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton.filledTonal(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                      icon: const Icon(Icons.add, size: 14),
                      onPressed: () {
                        final step = widget.step ??
                            (widget.type == InputType.percentage
                                ? 0.005
                                : widget.type == InputType.years
                                    ? 1.0
                                    : 10000.0);
                        _adjust(step);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _getConvertedSubtitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          if (widget.quickChips != null && widget.quickChips!.isNotEmpty) ...[
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.quickChips!.map((val) {
                  final bool isSelected = (_currentVal - val).abs() < 0.0001;
                  String chipLabel;
                  if (widget.type == InputType.currency) {
                    chipLabel = CurrencyFormatter.formatCompactINR(val);
                  } else if (widget.type == InputType.percentage) {
                    chipLabel = CurrencyFormatter.formatPercentage(val);
                  } else {
                    chipLabel = '${val.toInt()}Y';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ChoiceChip(
                      label: Text(chipLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryNavy.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryNavy : AppTheme.borderLight,
                          width: 1,
                        ),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _currentVal = val;
                            _controller.text = _formatValueForInput(_currentVal);
                          });
                          widget.onChanged(val);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
