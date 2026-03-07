import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../data/common_data.dart';
import '../../viewmodels/equipment_viewmodel.dart';
import '../../widgets/equip_icon.dart';
import 'equipment_form_page.dart';

class EquipmentListPage extends ConsumerWidget {
  const EquipmentListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipState = ref.watch(equipmentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('装备管理')),
      body: Column(
        children: [
          _buildFilterBar(context, ref, equipState),
          Expanded(
            child: equipState.filteredEquipments.isEmpty
                ? _buildEmpty(context)
                : _buildGrid(context, ref, equipState),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EquipmentFormPage()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('录入装备'),
      ),
    );
  }

  Widget _buildFilterBar(
      BuildContext context, WidgetRef ref, EquipmentState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          FilterChip(
            label: const Text('全部'),
            selected: state.filterSlotId == null,
            onSelected: (_) =>
                ref.read(equipmentProvider.notifier).setFilter(null),
          ),
          const SizedBox(width: 8),
          ...CommonData.slots.map(
            (slot) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(slot.name),
                selected: state.filterSlotId == slot.id,
                onSelected: (_) =>
                    ref.read(equipmentProvider.notifier).setFilter(slot.id),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.inkCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 48, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Text(
            '当前无装备',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '点击右下角按钮录入装备',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context, WidgetRef ref, EquipmentState state) {
    final equips = state.filteredEquipments;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: equips.length,
      itemBuilder: (context, index) {
        final equip = equips[index];
        return _EquipCard(
          equipment: equip,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => EquipmentFormPage(equipment: equip)),
          ),
          onDelete: () =>
              ref.read(equipmentProvider.notifier).deleteEquipment(equip.id),
        );
      },
    );
  }
}

class _EquipCard extends StatelessWidget {
  final dynamic equipment;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EquipCard({
    required this.equipment,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final equip = equipment;
    final slotName = CommonData.getSlotById(equip.slotId)?.name ?? '未知';
    final isPurple = equip.isPurple as bool;
    final qualityColor = isPurple ? AppColors.purpleBright : AppColors.goldBright;
    final qualityGlow = isPurple ? AppColors.purpleGlow : AppColors.goldGlow;
    final qualityDim = isPurple ? AppColors.purpleDim : AppColors.goldDim;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.inkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: qualityColor.withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: qualityGlow.withAlpha(12),
            blurRadius: 10,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: qualityColor.withAlpha(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 0),
                child: Row(
                  children: [
                    EquipIcon(equipment: equip, size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            equip.name,
                            style: tt.titleSmall?.copyWith(
                              color: qualityColor,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: qualityDim,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: qualityColor.withAlpha(30)),
                            ),
                            child: Text(
                              slotName,
                              style: TextStyle(
                                  color: qualityColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded,
                          size: 18, color: AppColors.textMuted),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit', child: Text('编辑')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('删除',
                              style: TextStyle(color: AppColors.danger)),
                        ),
                      ],
                      onSelected: (v) {
                        if (v == 'edit') onTap();
                        if (v == 'delete') onDelete();
                      },
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      qualityColor.withAlpha(40),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatLine(
                        label: '主',
                        type: equip.mainStat.type,
                        value: equip.mainStat.value,
                        isPercent: equip.mainStat.isPercent,
                        isMain: true,
                      ),
                      ...equip.subStats.take(4).map<Widget>(
                            (s) => _StatLine(
                              label: '副',
                              type: s.type,
                              value: s.value,
                              isPercent: s.isPercent,
                            ),
                          ),
                      if (equip.dingyinStat != null)
                        _StatLine(
                          label: '定',
                          type: equip.dingyinStat!.type,
                          value: equip.dingyinStat!.value,
                          isPercent: equip.dingyinStat!.isPercent,
                          isDingyin: true,
                        ),
                    ],
                  ),
                ),
              ),
              if (equip.isChengyin || equip.isConvertible)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: Row(
                    children: [
                      if (equip.isChengyin)
                        _Tag(label: '承音', color: AppColors.goldBright),
                      if (equip.isConvertible) ...[
                        const SizedBox(width: 6),
                        _Tag(label: '可转律', color: AppColors.orange),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String type;
  final double value;
  final bool isPercent;
  final bool isMain;
  final bool isDingyin;

  const _StatLine({
    required this.label,
    required this.type,
    required this.value,
    this.isPercent = false,
    this.isMain = false,
    this.isDingyin = false,
  });

  Color _qualityColor() {
    final q = CommonData.getStatQuality(type, value);
    switch (q) {
      case 'gold':
        return AppColors.goldBright;
      case 'purple':
        return AppColors.purpleBright;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _qualityColor();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              label,
              style: TextStyle(color: color.withAlpha(120), fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(type,
                style: TextStyle(color: color, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            '${value.toStringAsFixed(1)}${isPercent ? '%' : ''}',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
