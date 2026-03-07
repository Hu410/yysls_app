import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../data/common_data.dart';
import '../../models/scheme.dart';
import '../../viewmodels/graduation_viewmodel.dart';
import '../../viewmodels/scheme_viewmodel.dart';
import '../../viewmodels/equipment_viewmodel.dart';
import '../../viewmodels/simulator_viewmodel.dart';
import '../../widgets/equip_icon.dart';

class GraduationPage extends ConsumerStatefulWidget {
  const GraduationPage({super.key});

  @override
  ConsumerState<GraduationPage> createState() => _GraduationPageState();
}

class _GraduationPageState extends ConsumerState<GraduationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _compareSlotKey;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) _recalculate();
  }

  void _recalculate() {
    final gradVM = ref.read(graduationProvider.notifier);
    gradVM.calculateCurrentRate();
    switch (_tabController.index) {
      case 1:
        gradVM.calculateStatPriority();
        break;
      case 2:
        gradVM.calculateCultivation();
        break;
      case 3:
        if (_compareSlotKey != null) gradVM.calculateComparison(_compareSlotKey!);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradState = ref.watch(graduationProvider);
    final scheme = ref.watch(schemeProvider).currentScheme;
    final className = ref.watch(simulatorProvider).selectedClass ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scheme != null && className.isNotEmpty) {
        ref.read(graduationProvider.notifier).calculateCurrentRate();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('毕业分析')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: '毕业率总览'),
                Tab(text: '词条优先级'),
                Tab(text: '培养建议'),
                Tab(text: '单件对比'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverview(gradState, scheme, className),
                _buildPriority(gradState),
                _buildCultivation(gradState),
                _buildCompare(gradState, scheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(Widget child, {EdgeInsetsGeometry? padding}) {
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

  // ── Tab 0: Overview ──

  Widget _buildOverview(GraduationState gs, Scheme? scheme, String className) {
    final cs = Theme.of(context).colorScheme;
    if (scheme == null || className.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 56, color: cs.onSurfaceVariant.withAlpha(80)),
            const SizedBox(height: 16),
            Text('请先在「面板」页选择流派并配置装备',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _buildRateCircle(gs),
        const SizedBox(height: 16),
        _buildRotationInfo(gs),
        const SizedBox(height: 12),
        _buildEquipSlotSummary(scheme),
      ],
    );
  }

  Widget _buildRateCircle(GraduationState gs) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final rate = gs.currentRate;
    return _sectionCard(
      Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CustomPaint(
              painter: _GradientRingPainter(
                progress: rate / 100,
                trackColor: cs.surfaceContainerHighest,
                progressColor: cs.primary,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${rate.toStringAsFixed(2)}%',
                      style: tt.headlineMedium?.copyWith(
                        color: _rateColor(rate),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text('当前毕业率',
                        style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flash_on_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  '轴期望伤害: ${gs.totalDamage}',
                  style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
    );
  }

  Color _rateColor(double rate) {
    if (rate >= 95) return AppColors.success;
    if (rate >= 80) return AppColors.gold;
    if (rate >= 60) return AppColors.orange;
    return AppColors.danger;
  }

  Widget _buildRotationInfo(GraduationState gs) {
    final tt = Theme.of(context).textTheme;
    if (gs.rotationVersion == null) return const SizedBox.shrink();
    return _sectionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.goldDim,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.info_outline, size: 16, color: AppColors.gold),
              ),
              const SizedBox(width: 10),
              Text('技能轴信息', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('版本', gs.rotationVersion ?? '--'),
          _infoRow('作者', gs.rotationAuthor ?? '--'),
          _infoRow('更新', gs.rotationUpdateTime ?? '--'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12))),
          Expanded(child: Text(value, style: TextStyle(color: cs.onSurface, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildEquipSlotSummary(Scheme scheme) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final equipNotifier = ref.read(equipmentProvider.notifier);
    return _sectionCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('已装备概览', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: Scheme.slotKeys.map((key) {
              final eid = scheme.getEquipId(key);
              final equip = eid != null ? equipNotifier.getById(eid) : null;
              final slotName = CommonData.slotKeyToName[key] ?? key;
              return SizedBox(
                width: 68,
                child: Column(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: equip != null
                            ? (equip.isPurple ? AppColors.purpleDim : AppColors.goldDim)
                            : cs.surfaceContainerHighest,
                        border: Border.all(
                            color: equip != null
                                ? (equip.isPurple ? AppColors.purple : AppColors.gold).withAlpha(40)
                                : cs.outlineVariant.withAlpha(60)),
                      ),
                      child: equip != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: EquipIcon(equipment: equip, size: 48),
                            )
                          : Icon(Icons.add_rounded, color: cs.onSurfaceVariant.withAlpha(80), size: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      equip?.name ?? slotName,
                      style: TextStyle(
                        color: equip != null ? cs.onSurface : cs.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: equip != null ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Priority ──

  Widget _buildPriority(GraduationState gs) {
    final cs = Theme.of(context).colorScheme;
    final equipped = _countEquippedSlots();
    if (equipped < 8) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.orange.withAlpha(160)),
              const SizedBox(height: 16),
              Text(
                '请先穿戴满8件装备后再计算词条优先级\n当前已穿戴：$equipped/8件装备',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14, height: 1.8),
              ),
            ],
          ),
        ),
      );
    }

    if (gs.isCalculating) return const Center(child: CircularProgressIndicator());

    if (gs.gainPriority.isEmpty && gs.lossPriority.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('点击下方按钮开始计算', style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.read(graduationProvider.notifier).calculateStatPriority(),
              icon: const Icon(Icons.calculate_rounded),
              label: const Text('计算词条优先级'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _sectionTitle('增加收益排名（+一条满值）'),
        ...gs.gainPriority.take(15).map((p) => _priorityTile(p, true)),
        const SizedBox(height: 20),
        _sectionTitle('减少损失排名（-一条满值）'),
        ...gs.lossPriority.take(15).map((p) => _priorityTile(p, false)),
      ],
    );
  }

  Widget _priorityTile(StatPriorityItem item, bool isGain) {
    final cs = Theme.of(context).colorScheme;
    final color = isGain
        ? (item.diff > 0 ? AppColors.danger : AppColors.success)
        : (item.diff > 0 ? AppColors.success : AppColors.danger);
    final sign = item.diff > 0 ? '+' : '';

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(vertical: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(item.stat,
                  style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$sign${item.diff.toStringAsFixed(3)}%',
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Cultivation ──

  Widget _buildCultivation(GraduationState gs) {
    final cs = Theme.of(context).colorScheme;
    if (gs.cultivationStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up_rounded, size: 48, color: cs.onSurfaceVariant.withAlpha(100)),
            const SizedBox(height: 16),
            Text('点击按钮分析培养方向', style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.read(graduationProvider.notifier).calculateCultivation(),
              icon: const Icon(Icons.trending_up_rounded),
              label: const Text('分析培养建议'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _sectionCard(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('全词条统计（按满值比）',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${gs.totalStatRatio.toStringAsFixed(1)}/40条',
                      style: TextStyle(color: cs.onPrimaryContainer, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...gs.cultivationStats.take(20).map(_cultivationTile),
            ],
          ),
        ),
        if (gs.dingyinUpgrades.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle('定音升级优先级'),
          ...gs.dingyinUpgrades.map(_dingyinTile),
        ],
      ],
    );
  }

  Widget _cultivationTile(CultivationItem item) {
    final cs = Theme.of(context).colorScheme;
    final ratio = item.playerCount;
    final barWidth = (ratio / 5).clamp(0.0, 1.0);
    final color = ratio >= 4 ? AppColors.success : (ratio >= 2 ? AppColors.orange : AppColors.danger);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(item.statType, style: TextStyle(color: cs.onSurface, fontSize: 12))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: barWidth,
                minHeight: 10,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 50,
            child: Text(
              '${ratio.toStringAsFixed(2)}条',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dingyinTile(DingyinUpgradeItem item) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(vertical: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${item.slotName} - ${item.statType}',
                      style: TextStyle(color: cs.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${item.currentValue.toStringAsFixed(1)} → ${item.maxValue.toStringAsFixed(1)}',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.successDim,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${item.rateUpgrade.toStringAsFixed(3)}%',
                style: const TextStyle(color: AppColors.success, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 3: Compare ──

  Widget _buildCompare(GraduationState gs, Scheme? scheme) {
    final cs = Theme.of(context).colorScheme;
    if (scheme == null) {
      return Center(child: Text('请先配置方案', style: TextStyle(color: cs.onSurfaceVariant)));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              _buildSlotChips(scheme),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilterChip(
                      label: const Text('假设承音(94%)'),
                      selected: gs.assumeChengyin,
                      onSelected: (v) => ref.read(graduationProvider.notifier).setAssumeChengyin(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilterChip(
                      label: const Text('冻结定音'),
                      selected: gs.freezeDingyin,
                      onSelected: (v) => ref.read(graduationProvider.notifier).setFreezeDingyin(v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildCompareList(gs)),
      ],
    );
  }

  Widget _buildSlotChips(Scheme scheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: Scheme.slotKeys.map((key) {
          final name = CommonData.slotKeyToName[key] ?? key;
          final isSelected = _compareSlotKey == key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _compareSlotKey = key);
                ref.read(graduationProvider.notifier).calculateComparison(key);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompareList(GraduationState gs) {
    final cs = Theme.of(context).colorScheme;
    if (_compareSlotKey == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows_rounded, size: 48, color: cs.onSurfaceVariant.withAlpha(80)),
            const SizedBox(height: 12),
            Text('请选择要对比的装备槽位', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
          ],
        ),
      );
    }

    if (gs.isCalculating) return const Center(child: CircularProgressIndicator());

    if (gs.compareResults.isEmpty) {
      return Center(
        child: Text('库中没有符合条件的同类装备可供对比',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: gs.compareResults.length,
      itemBuilder: (context, index) => _compareCard(gs.compareResults[index]),
    );
  }

  Widget _compareCard(CompareItem item) {
    final cs = Theme.of(context).colorScheme;
    final diff = item.diff;
    final Color diffColor;
    final String diffSign;
    if (diff > 0.001) {
      diffColor = AppColors.success;
      diffSign = '+';
    } else if (diff < -0.001) {
      diffColor = AppColors.danger;
      diffSign = '';
    } else {
      diffColor = cs.onSurfaceVariant;
      diffSign = '';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _sectionCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EquipIcon(equipment: item.equipment, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.equipment.name,
                          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(
                        '${item.equipment.mainStat.type}: +${item.equipment.mainStat.value}',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 4,
              children: item.equipment.subStats.map((sub) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('${sub.type}+${sub.value}',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: diffColor.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('毕业率: ${item.resultRate.toStringAsFixed(2)}%',
                      style: TextStyle(color: cs.onSurface, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: diffColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$diffSign${diff.toStringAsFixed(2)}%',
                      style: TextStyle(color: diffColor, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _sectionTitle(String text) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
    );
  }

  int _countEquippedSlots() {
    final scheme = ref.read(schemeProvider).currentScheme;
    if (scheme == null) return 0;
    final equipNotifier = ref.read(equipmentProvider.notifier);
    int count = 0;
    for (final key in Scheme.slotKeys) {
      final eid = scheme.getEquipId(key);
      if (eid != null && equipNotifier.getById(eid) != null) count++;
    }
    return count;
  }
}

class _GradientRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _GradientRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const strokeWidth = 8.0;

    final bgPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, -pi / 2, 2 * pi * progress.clamp(0.0, 1.0), false, fgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter old) =>
      old.progress != progress || old.trackColor != trackColor || old.progressColor != progressColor;
}
