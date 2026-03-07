import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class QualityTag extends StatelessWidget {
  final double value;
  final double maxValue;

  const QualityTag({
    super.key,
    required this.value,
    required this.maxValue,
  });

  double get _ratio => maxValue > 0 ? (value / maxValue * 100) : 0;

  Color _color(ColorScheme cs) {
    if (_ratio >= 94) return AppColors.gold;
    if (_ratio >= 80) return AppColors.purple;
    if (_ratio >= 60) return cs.primary;
    return cs.onSurfaceVariant;
  }

  Color _bgColor(ColorScheme cs) {
    if (_ratio >= 94) return AppColors.goldDim;
    if (_ratio >= 80) return AppColors.purpleDim;
    if (_ratio >= 60) return cs.primaryContainer;
    return cs.surfaceContainerHighest;
  }

  String get _label => '${_ratio.toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor(cs),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color(cs),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
