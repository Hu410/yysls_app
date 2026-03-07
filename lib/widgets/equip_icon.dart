import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../data/common_data.dart';
import '../theme/app_colors.dart';

class EquipIcon extends StatelessWidget {
  final Equipment? equipment;
  final String? slotId;
  final double size;

  const EquipIcon({
    super.key,
    this.equipment,
    this.slotId,
    this.size = 48,
  });

  String _getIconPath() {
    if (equipment != null) {
      String icon;
      if (equipment!.slotId == '1' && equipment!.weaponTypeId != null) {
        final wt = CommonData.getWeaponTypeById(equipment!.weaponTypeId!);
        icon = wt?.icon ?? 'icon1.jpg';
      } else {
        final slot = CommonData.getSlotById(equipment!.slotId);
        icon = slot?.icon ?? 'icon1.jpg';
      }
      if (equipment!.isPurple && !equipment!.isChengyin) {
        icon = icon.replaceAll('.jpg', 'p.jpg');
      }
      return 'assets/icon/$icon';
    }
    if (slotId != null) {
      final slot = CommonData.getSlotById(slotId!);
      return 'assets/icon/${slot?.icon ?? 'icon1.jpg'}';
    }
    return 'assets/icon/icon1.jpg';
  }

  Color get _glowColor {
    if (equipment == null) return Colors.transparent;
    return equipment!.isPurple ? AppColors.purpleBorder : AppColors.goldBorder;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: equipment != null
            ? [
                BoxShadow(
                  color: _glowColor.withAlpha(50),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          _getIconPath(),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.help_outline,
              size: size * 0.4,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
