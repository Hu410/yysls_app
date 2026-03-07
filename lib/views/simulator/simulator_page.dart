import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../data/common_data.dart';
import '../../data/class_config.dart';
import '../../data/xinfa_data.dart';
import '../../models/equipment.dart';
import '../../models/scheme.dart';
import '../../services/calculator.dart';
import '../../viewmodels/equipment_viewmodel.dart';
import '../../viewmodels/scheme_viewmodel.dart';
import '../../viewmodels/simulator_viewmodel.dart';
import '../../viewmodels/graduation_viewmodel.dart';
import '../../widgets/equip_icon.dart';
import '../../widgets/graduation_banner.dart';

class SimulatorPage extends ConsumerWidget {
  const SimulatorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schemeState = ref.watch(schemeProvider);
    final simState = ref.watch(simulatorProvider);
    final equipState = ref.watch(equipmentProvider);
    final scheme = schemeState.currentScheme;

    final equipped = <String, Equipment?>{};
    if (scheme != null) {
      for (final key in Scheme.slotKeys) {
        final eid = scheme.getEquipId(key);
        equipped[key] = eid != null
            ? ref.read(equipmentProvider.notifier).getById(eid)
            : null;
      }
    }

    final statResult = Calculator.calculateTotal(
      equipped,
      simState.selectedClass,
      scheme?.bowType ?? 'precision',
      scheme?.xinfa ?? [null, null, null, null],
      scheme?.setBonus,
      scheme?.earlySeasonBonus ?? false,
      scheme?.pvpMode ?? false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('面板模拟')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildSchemeSelector(context, ref, schemeState),
          const SizedBox(height: 12),
          _buildClassSelector(context, ref, simState, scheme),
          const SizedBox(height: 12),
          _buildSlotGrid(context, ref, scheme, equipped, equipState),
          const SizedBox(height: 12),
          _buildXinfaSection(context, ref, scheme),
          const SizedBox(height: 12),
          _buildOptions(context, ref, scheme),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            final gradState = ref.watch(graduationProvider);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (simState.selectedClass != null &&
                  simState.selectedClass!.isNotEmpty) {
                ref.read(graduationProvider.notifier).calculateCurrentRate();
              }
            });
            return GraduationBanner(
              rate: gradState.currentRate,
              totalDamage: gradState.totalDamage,
              onTap: () => Navigator.pop(context),
            );
          }),
          const SizedBox(height: 12),
          _buildStatsPanel(context, statResult),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required Widget child, EdgeInsetsGeometry? padding}) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withAlpha(40)),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildSchemeSelector(BuildContext context, WidgetRef ref, SchemeState schemeState) {
    final cs = Theme.of(context).colorScheme;
    return _sectionCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.folder_outlined, size: 18, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              value: schemeState.currentSchemeId,
              isExpanded: true,
              underline: const SizedBox(),
              icon: Icon(Icons.expand_more_rounded, color: cs.onSurfaceVariant),
              items: schemeState.schemes
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name,
                            style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
              onChanged: (id) {
                if (id != null) {
                  ref.read(schemeProvider.notifier).selectScheme(id);
                }
              },
            ),
          ),
          _MiniAction(icon: Icons.edit_rounded, onTap: () => _renameScheme(ref, context)),
          _MiniAction(icon: Icons.add_rounded, onTap: () => _createScheme(ref)),
          if (schemeState.schemes.length > 1)
            _MiniAction(
                icon: Icons.delete_outline_rounded,
                color: AppColors.danger,
                onTap: () {
                  if (schemeState.currentSchemeId != null) {
                    ref.read(schemeProvider.notifier).deleteScheme(schemeState.currentSchemeId!);
                  }
                }),
        ],
      ),
    );
  }

  void _createScheme(WidgetRef ref) {
    final count = ref.read(schemeProvider).schemes.length + 1;
    ref.read(schemeProvider.notifier).createScheme('方案$count');
  }

  void _renameScheme(WidgetRef ref, BuildContext context) {
    final scheme = ref.read(schemeProvider).currentScheme;
    if (scheme == null) return;
    final controller = TextEditingController(text: scheme.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重命名方案', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入方案名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(schemeProvider.notifier).renameScheme(scheme.id, controller.text);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSelector(BuildContext context, WidgetRef ref, SimulatorState simState, Scheme? scheme) {
    return _sectionCard(
      context,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: simState.selectedClass,
                  decoration: const InputDecoration(
                    labelText: '流派',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: ClassConfig.classes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    ref.read(simulatorProvider.notifier).selectClass(v);
                    if (v != null) {
                      final defaultSet = ClassConfig.defaultSets[v];
                      ref.read(schemeProvider.notifier).setSetBonus(defaultSet);
                      final rules = ClassConfig.xinfaRules[v];
                      if (rules != null) {
                        final defaults = rules['default'] ?? [];
                        for (int i = 0; i < 4; i++) {
                          ref.read(schemeProvider.notifier)
                              .setXinfa(i, i < defaults.length ? defaults[i] : null);
                        }
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: scheme?.bowType ?? 'precision',
                  decoration: const InputDecoration(
                    labelText: '弓诀',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'precision', child: Text('精准弓')),
                    DropdownMenuItem(value: 'crit', child: Text('会心弓')),
                    DropdownMenuItem(value: 'intent', child: Text('会意弓')),
                  ],
                  onChanged: (v) {
                    if (v != null) ref.read(schemeProvider.notifier).setBowType(v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: scheme?.setBonus,
            decoration: const InputDecoration(
              labelText: '套装效果',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('无套装')),
              ...CommonData.setData.keys.map((s) => DropdownMenuItem(value: s, child: Text(s))),
            ],
            onChanged: (v) => ref.read(schemeProvider.notifier).setSetBonus(v),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotGrid(BuildContext context, WidgetRef ref, Scheme? scheme,
      Map<String, Equipment?> equipped, EquipmentState equipState) {
    final tt = Theme.of(context).textTheme;
    return _sectionCard(
      context,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('装备配置', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.72,
            children: CommonData.slotKeyToName.entries.map((entry) {
              final equip = equipped[entry.key];
              return _SlotTile(
                slotKey: entry.key,
                slotName: entry.value,
                equipment: equip,
                onTap: () => _showEquipPicker(context, ref, entry.key, equipState),
                onLongPress: () {
                  if (equip != null) {
                    ref.read(schemeProvider.notifier).unequipItem(entry.key);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showEquipPicker(BuildContext context, WidgetRef ref, String slotKey, EquipmentState equipState) {
    final cs = Theme.of(context).colorScheme;
    final slotId = CommonData.slotKeyToId[slotKey];
    if (slotId == null) return;
    final available = equipState.equipments.where((e) => e.slotId == slotId).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text('选择${CommonData.slotKeyToName[slotKey] ?? "装备"}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.read(schemeProvider.notifier).unequipItem(slotKey);
                      Navigator.pop(ctx);
                    },
                    child: Text('卸下', style: TextStyle(color: AppColors.danger)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: available.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: cs.onSurfaceVariant.withAlpha(80)),
                          const SizedBox(height: 12),
                          Text('没有可用装备', style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: available.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final eq = available[i];
                        return Card(
                          elevation: 0,
                          color: cs.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            leading: EquipIcon(equipment: eq, size: 42),
                            title: Text(
                              eq.name,
                              style: TextStyle(
                                color: eq.isPurple ? AppColors.purple : AppColors.gold,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              '${eq.mainStat.type} ${eq.mainStat.value.toStringAsFixed(1)}',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                            ),
                            onTap: () {
                              ref.read(schemeProvider.notifier).equipItem(slotKey, eq.id);
                              Navigator.pop(ctx);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXinfaSection(BuildContext context, WidgetRef ref, Scheme? scheme) {
    final tt = Theme.of(context).textTheme;
    return _sectionCard(
      context,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('心法配置', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(4, (i) {
              final name = scheme?.xinfa[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 10 : 0),
                  child: _XinfaSlot(
                    index: i,
                    xinfaName: name,
                    onTap: () => _showXinfaPicker(context, ref, i, scheme),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showXinfaPicker(BuildContext context, WidgetRef ref, int index, Scheme? scheme) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text('选择心法', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.read(schemeProvider.notifier).setXinfa(index, null);
                      Navigator.pop(ctx);
                    },
                    child: Text('清除', style: TextStyle(color: AppColors.danger)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: XinfaData.xinfaList.length,
                itemBuilder: (_, i) {
                  final name = XinfaData.xinfaList[i];
                  final isSelected = scheme?.xinfa.contains(name) ?? false;
                  return GestureDetector(
                    onTap: () {
                      ref.read(schemeProvider.notifier).setXinfa(index, name);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? cs.primaryContainer : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected ? Border.all(color: cs.primary, width: 2) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              XinfaData.getIconPath(name),
                              width: 50, height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (_, e, s) => Container(
                                width: 50, height: 60,
                                color: cs.surfaceContainerHighest,
                                child: Icon(Icons.help_outline, color: cs.onSurfaceVariant),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? cs.primary : cs.onSurface,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(BuildContext context, WidgetRef ref, Scheme? scheme) {
    return _sectionCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        children: [
          _OptionRow(
            label: '提前获得下半赛季属性',
            value: scheme?.earlySeasonBonus ?? false,
            onChanged: (v) => ref.read(schemeProvider.notifier).setEarlySeasonBonus(v ?? false),
          ),
          _OptionRow(
            label: '首领视为玩家',
            value: scheme?.pvpMode ?? false,
            onChanged: (v) => ref.read(schemeProvider.notifier).setPvpMode(v ?? false),
          ),
          _OptionRow(
            label: '贷款满定音',
            value: scheme?.loanDingyin ?? false,
            onChanged: (v) => ref.read(schemeProvider.notifier).setLoanDingyin(v ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel(BuildContext context, StatResult result) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final displayStats = Calculator.getDisplayStats(result);
    return _sectionCard(
      context,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.bar_chart_rounded, size: 16, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 10),
              Text('属性面板', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          ...displayStats.map((e) => _StatRow(label: e.key, value: e.value)),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _MiniAction({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color ?? cs.onSurfaceVariant),
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final String slotKey;
  final String slotName;
  final Equipment? equipment;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SlotTile({
    required this.slotKey,
    required this.slotName,
    this.equipment,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasEquip = equipment != null;
    final isPurple = equipment?.isPurple ?? false;
    final qualityColor = isPurple ? AppColors.purple : AppColors.gold;
    final qualityBg = isPurple ? AppColors.purpleDim : AppColors.goldDim;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: hasEquip ? qualityBg.withAlpha(120) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasEquip ? qualityColor.withAlpha(40) : cs.outlineVariant.withAlpha(60),
            width: hasEquip ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasEquip) ...[
              EquipIcon(equipment: equipment, size: 36),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  equipment!.name,
                  style: TextStyle(color: qualityColor, fontSize: 9, fontWeight: FontWeight.w700),
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: cs.onSurfaceVariant.withAlpha(40), width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.add_rounded, size: 20, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              slotName,
              style: TextStyle(
                color: hasEquip ? cs.onSurfaceVariant : cs.onSurfaceVariant.withAlpha(150),
                fontSize: 10,
                fontWeight: hasEquip ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XinfaSlot extends StatelessWidget {
  final int index;
  final String? xinfaName;
  final VoidCallback onTap;

  const _XinfaSlot({required this.index, this.xinfaName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 86,
        decoration: BoxDecoration(
          color: xinfaName != null ? cs.primaryContainer.withAlpha(140) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: xinfaName != null ? cs.primary.withAlpha(40) : cs.outlineVariant.withAlpha(60),
          ),
        ),
        child: xinfaName != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      XinfaData.getIconPath(xinfaName!),
                      width: 40, height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (_, e, s) => Container(
                        width: 40, height: 48,
                        color: cs.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    xinfaName!,
                    style: TextStyle(color: cs.onSurface, fontSize: 9, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 20, color: cs.onSurfaceVariant.withAlpha(120)),
                  const SizedBox(height: 2),
                  Text('选择心法', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
                ],
              ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _OptionRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        Expanded(child: Text(label, style: TextStyle(color: cs.onSurface, fontSize: 13))),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          Text(value, style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
