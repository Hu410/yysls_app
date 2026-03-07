import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/equipment.dart';
import '../models/scheme.dart';
import '../data/common_data.dart';
import '../data/class_config.dart';
import '../data/rotation_data.dart';
import '../services/calculator.dart';
import 'equipment_viewmodel.dart';
import 'scheme_viewmodel.dart';
import 'simulator_viewmodel.dart';

class StatPriorityItem {
  final String stat;
  final double maxValue;
  final bool isPercent;
  final double resultRate;
  final double diff;

  const StatPriorityItem({
    required this.stat,
    required this.maxValue,
    required this.isPercent,
    required this.resultRate,
    required this.diff,
  });
}

class CultivationItem {
  final String statType;
  final double playerCount;
  final double optimalCount;

  const CultivationItem({
    required this.statType,
    this.playerCount = 0,
    this.optimalCount = 0,
  });
}

class DingyinUpgradeItem {
  final String slotKey;
  final String slotName;
  final String statType;
  final double currentValue;
  final double maxValue;
  final double rateUpgrade;

  const DingyinUpgradeItem({
    required this.slotKey,
    required this.slotName,
    required this.statType,
    required this.currentValue,
    required this.maxValue,
    required this.rateUpgrade,
  });
}

class CompareItem {
  final Equipment equipment;
  final double resultRate;
  final double diff;

  const CompareItem({
    required this.equipment,
    required this.resultRate,
    required this.diff,
  });
}

class GraduationState {
  final double currentRate;
  final int totalDamage;
  final List<StatPriorityItem> gainPriority;
  final List<StatPriorityItem> lossPriority;
  final List<CultivationItem> cultivationStats;
  final List<DingyinUpgradeItem> dingyinUpgrades;
  final double totalStatRatio;
  final List<CompareItem> compareResults;
  final String? compareSlotKey;
  final bool assumeChengyin;
  final bool freezeDingyin;
  final bool isCalculating;
  final String? rotationVersion;
  final String? rotationAuthor;
  final String? rotationUpdateTime;

  const GraduationState({
    this.currentRate = 0,
    this.totalDamage = 0,
    this.gainPriority = const [],
    this.lossPriority = const [],
    this.cultivationStats = const [],
    this.dingyinUpgrades = const [],
    this.totalStatRatio = 0,
    this.compareResults = const [],
    this.compareSlotKey,
    this.assumeChengyin = true,
    this.freezeDingyin = false,
    this.isCalculating = false,
    this.rotationVersion,
    this.rotationAuthor,
    this.rotationUpdateTime,
  });

  GraduationState copyWith({
    double? currentRate,
    int? totalDamage,
    List<StatPriorityItem>? gainPriority,
    List<StatPriorityItem>? lossPriority,
    List<CultivationItem>? cultivationStats,
    List<DingyinUpgradeItem>? dingyinUpgrades,
    double? totalStatRatio,
    List<CompareItem>? compareResults,
    String? compareSlotKey,
    bool? assumeChengyin,
    bool? freezeDingyin,
    bool? isCalculating,
    String? rotationVersion,
    String? rotationAuthor,
    String? rotationUpdateTime,
    bool clearCompareSlot = false,
  }) {
    return GraduationState(
      currentRate: currentRate ?? this.currentRate,
      totalDamage: totalDamage ?? this.totalDamage,
      gainPriority: gainPriority ?? this.gainPriority,
      lossPriority: lossPriority ?? this.lossPriority,
      cultivationStats: cultivationStats ?? this.cultivationStats,
      dingyinUpgrades: dingyinUpgrades ?? this.dingyinUpgrades,
      totalStatRatio: totalStatRatio ?? this.totalStatRatio,
      compareResults: compareResults ?? this.compareResults,
      compareSlotKey: clearCompareSlot ? null : (compareSlotKey ?? this.compareSlotKey),
      assumeChengyin: assumeChengyin ?? this.assumeChengyin,
      freezeDingyin: freezeDingyin ?? this.freezeDingyin,
      isCalculating: isCalculating ?? this.isCalculating,
      rotationVersion: rotationVersion ?? this.rotationVersion,
      rotationAuthor: rotationAuthor ?? this.rotationAuthor,
      rotationUpdateTime: rotationUpdateTime ?? this.rotationUpdateTime,
    );
  }
}

class GraduationViewModel extends StateNotifier<GraduationState> {
  final Ref _ref;

  GraduationViewModel(this._ref) : super(const GraduationState());

  Map<String, Equipment?> _getEquipped() {
    final schemeState = _ref.read(schemeProvider);
    final equipNotifier = _ref.read(equipmentProvider.notifier);
    final scheme = schemeState.currentScheme;
    final equipped = <String, Equipment?>{};
    if (scheme != null) {
      for (final key in Scheme.slotKeys) {
        final eid = scheme.getEquipId(key);
        equipped[key] = eid != null ? equipNotifier.getById(eid) : null;
      }
    }
    return equipped;
  }

  String _getClassName() {
    return _ref.read(simulatorProvider).selectedClass ?? '';
  }

  Scheme? _getCurrentScheme() {
    return _ref.read(schemeProvider).currentScheme;
  }

  void calculateCurrentRate() {
    final equipped = _getEquipped();
    final className = _getClassName();
    final scheme = _getCurrentScheme();
    if (className.isEmpty || scheme == null) {
      state = state.copyWith(currentRate: 0, totalDamage: 0);
      return;
    }

    final config = RotationData.getConfig(className);

    final result = Calculator.calcRate(
      equipped,
      className,
      scheme.bowType,
      scheme.xinfa,
      scheme.setBonus,
      scheme.earlySeasonBonus,
    );

    state = state.copyWith(
      currentRate: result.graduationRate,
      totalDamage: result.totalDamage,
      rotationVersion: config?.version,
      rotationAuthor: config?.author,
      rotationUpdateTime: config?.updateTime,
    );
  }

  Future<void> calculateStatPriority() async {
    final equipped = _getEquipped();
    final className = _getClassName();
    final scheme = _getCurrentScheme();
    if (className.isEmpty || scheme == null) return;

    final emptySlots = Scheme.slotKeys.where((k) => equipped[k] == null);
    if (emptySlots.isNotEmpty) {
      state = state.copyWith(gainPriority: [], lossPriority: []);
      return;
    }

    state = state.copyWith(isCalculating: true);
    await Future.delayed(Duration.zero);

    final currentRate = state.currentRate;
    final allStats = _getAllPossibleStats(equipped);

    final gains = <StatPriorityItem>[];
    final losses = <StatPriorityItem>[];

    for (var i = 0; i < allStats.length; i++) {
      final statName = allStats[i];
      final maxVal = CommonData.maxValues[statName];
      if (maxVal == null) continue;
      final isPercent = CommonData.percentStats.contains(statName);

      final gainMod = [StatModEntry(type: statName, value: maxVal, operation: 'add')];
      final gainPanel = Calculator.buildPanelForGraduation(
        equipped, className, scheme.bowType, scheme.xinfa,
        scheme.setBonus, scheme.earlySeasonBonus,
        statModifier: gainMod,
      );
      final gainGrad = Calculator.calculateGraduationRate(
        panelStats: gainPanel,
        className: className,
        xinfaList: scheme.xinfa,
        setName: scheme.setBonus ?? '',
      );
      gains.add(StatPriorityItem(
        stat: statName,
        maxValue: maxVal,
        isPercent: isPercent,
        resultRate: gainGrad.graduationRate,
        diff: gainGrad.graduationRate - currentRate,
      ));

      final lossMod = [StatModEntry(type: statName, value: maxVal, operation: 'remove')];
      final lossPanel = Calculator.buildPanelForGraduation(
        equipped, className, scheme.bowType, scheme.xinfa,
        scheme.setBonus, scheme.earlySeasonBonus,
        statModifier: lossMod,
      );
      final lossGrad = Calculator.calculateGraduationRate(
        panelStats: lossPanel,
        className: className,
        xinfaList: scheme.xinfa,
        setName: scheme.setBonus ?? '',
      );
      losses.add(StatPriorityItem(
        stat: statName,
        maxValue: maxVal,
        isPercent: isPercent,
        resultRate: lossGrad.graduationRate,
        diff: currentRate - lossGrad.graduationRate,
      ));

      if (i % 5 == 0) await Future.delayed(Duration.zero);
    }

    gains.sort((a, b) => b.diff.compareTo(a.diff));
    losses.sort((a, b) => b.diff.compareTo(a.diff));

    state = state.copyWith(
      gainPriority: gains,
      lossPriority: losses,
      isCalculating: false,
    );
  }

  List<String> _getAllPossibleStats(Map<String, Equipment?> equipped) {
    const excluded = [
      '剑武学增效', '枪武学增效', '伞武学增效',
      '扇武学增效', '绳标武学增效', '双刀武学增效', '陌刀武学增效',
      '横刀武学增效', '拳甲武学增效',
      '外功穿透', '属攻穿透', '无相穿透',
      '最大无相攻击', '最小无相攻击', '对玩家单位增效',
      '最小鸣金攻击', '最大鸣金攻击',
      '最小裂石攻击', '最大裂石攻击',
      '最小牵丝攻击', '最大牵丝攻击',
      '最小破竹攻击', '最大破竹攻击',
    ];

    final result = <String>[];
    for (final key in CommonData.maxValues.keys) {
      if (!excluded.contains(key)) result.add(key);
    }

    final w1 = equipped['weapon1'];
    final w2 = equipped['weapon2'];
    if (w1 != null && w1.weaponTypeId != null) {
      final wt = CommonData.getWeaponTypeById(w1.weaponTypeId!);
      if (wt != null) result.add(wt.statName);
    }
    if (w2 != null && w2.weaponTypeId != null) {
      final wt = CommonData.getWeaponTypeById(w2.weaponTypeId!);
      if (wt != null && !result.contains(wt.statName)) result.add(wt.statName);
    }

    return result;
  }

  void calculateCultivation() {
    final equipped = _getEquipped();
    final className = _getClassName();
    final scheme = _getCurrentScheme();

    final statCounts = <String, double>{};
    double totalRatio = 0;
    final dingyinItems = <DingyinUpgradeItem>[];

    for (final slotKey in Scheme.slotKeys) {
      final equip = equipped[slotKey];
      if (equip == null) continue;

      void countStat(String type, double value) {
        if (type == '生存类词条' || type == '生存向') return;
        final maxVal = CommonData.maxValues[type];
        if (maxVal == null || maxVal == 0) return;
        final ratio = value / maxVal;
        statCounts[type] = (statCounts[type] ?? 0) + ratio;
        totalRatio += ratio;
      }

      countStat(equip.mainStat.type, equip.mainStat.value);
      for (final sub in equip.subStats) {
        countStat(sub.type, sub.value);
      }

      if (equip.dingyinStat != null) {
        final ds = equip.dingyinStat!;
        final maxVal = CommonData.maxValues[ds.type];
        if (maxVal != null && maxVal > 0) {
          dingyinItems.add(DingyinUpgradeItem(
            slotKey: slotKey,
            slotName: CommonData.slotKeyToName[slotKey] ?? slotKey,
            statType: ds.type,
            currentValue: ds.value,
            maxValue: maxVal,
            rateUpgrade: 0,
          ));
        }
      }
    }

    // Calculate dingyin upgrade benefit
    if (className.isNotEmpty && scheme != null && dingyinItems.isNotEmpty) {
      final baseRate = state.currentRate;
      final upgraded = <DingyinUpgradeItem>[];

      for (final item in dingyinItems) {
        final equip = equipped[item.slotKey];
        if (equip == null) continue;

        final maxedEquip = Equipment(
          id: equip.id,
          slotId: equip.slotId,
          weaponTypeId: equip.weaponTypeId,
          name: equip.name,
          isChengyin: equip.isChengyin,
          isPurple: equip.isPurple,
          isConvertible: equip.isConvertible,
          mainStat: equip.mainStat,
          subStats: equip.subStats,
          dingyinStat: StatEntry(
            type: item.statType,
            value: item.maxValue,
            isPercent: equip.dingyinStat?.isPercent ?? false,
          ),
        );

        final testEquipped = Map<String, Equipment?>.from(equipped);
        testEquipped[item.slotKey] = maxedEquip;

        final result = Calculator.calcRate(
          testEquipped, className, scheme.bowType, scheme.xinfa,
          scheme.setBonus, scheme.earlySeasonBonus,
        );

        upgraded.add(DingyinUpgradeItem(
          slotKey: item.slotKey,
          slotName: item.slotName,
          statType: item.statType,
          currentValue: item.currentValue,
          maxValue: item.maxValue,
          rateUpgrade: result.graduationRate - baseRate,
        ));
      }

      upgraded.sort((a, b) => b.rateUpgrade.compareTo(a.rateUpgrade));
      dingyinItems
        ..clear()
        ..addAll(upgraded);
    }

    final cultStats = statCounts.entries
        .map((e) => CultivationItem(statType: e.key, playerCount: e.value))
        .toList()
      ..sort((a, b) => b.playerCount.compareTo(a.playerCount));

    state = state.copyWith(
      cultivationStats: cultStats,
      dingyinUpgrades: dingyinItems,
      totalStatRatio: totalRatio,
    );
  }

  Future<void> calculateComparison(String slotKey) async {
    final equipped = _getEquipped();
    final className = _getClassName();
    final scheme = _getCurrentScheme();
    if (className.isEmpty || scheme == null) return;

    state = state.copyWith(
      compareSlotKey: slotKey,
      compareResults: [],
      isCalculating: true,
    );
    await Future.delayed(Duration.zero);

    final allEquipment = _ref.read(equipmentProvider).equipments;
    final slotId = CommonData.slotKeyToId[slotKey];
    final currentEquip = equipped[slotKey];

    var candidates = allEquipment.where((e) => e.slotId == slotId).toList();

    if (slotId == '1' && currentEquip != null) {
      candidates = candidates
          .where((e) => e.weaponTypeId == currentEquip.weaponTypeId)
          .toList();
    } else if (slotId == '1') {
      final rules = ClassConfig.weaponRules[className] ?? [];
      candidates = candidates
          .where((e) => rules.contains(e.weaponTypeId))
          .toList();
    }

    if (currentEquip != null) {
      candidates = candidates.where((e) => e.id != currentEquip.id).toList();
    }

    final currentRate = state.currentRate;
    final results = <CompareItem>[];

    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      Equipment testEquip = candidate;
      if (state.assumeChengyin) {
        testEquip = Calculator.mockChengyin(candidate);
      }
      if (state.freezeDingyin && currentEquip?.dingyinStat != null) {
        testEquip = Equipment(
          id: testEquip.id,
          slotId: testEquip.slotId,
          weaponTypeId: testEquip.weaponTypeId,
          name: testEquip.name,
          isChengyin: testEquip.isChengyin,
          isPurple: testEquip.isPurple,
          isConvertible: testEquip.isConvertible,
          mainStat: testEquip.mainStat,
          subStats: testEquip.subStats,
          dingyinStat: currentEquip!.dingyinStat,
        );
      }

      final testEquipped = Map<String, Equipment?>.from(equipped);
      testEquipped[slotKey] = testEquip;

      final result = Calculator.calcRate(
        testEquipped, className, scheme.bowType, scheme.xinfa,
        scheme.setBonus, scheme.earlySeasonBonus,
      );

      results.add(CompareItem(
        equipment: candidate,
        resultRate: result.graduationRate,
        diff: result.graduationRate - currentRate,
      ));

      if (i % 3 == 0) await Future.delayed(Duration.zero);
    }

    results.sort((a, b) => b.diff.compareTo(a.diff));
    state = state.copyWith(compareResults: results, isCalculating: false);
  }

  void setAssumeChengyin(bool value) {
    state = state.copyWith(assumeChengyin: value);
    if (state.compareSlotKey != null) {
      calculateComparison(state.compareSlotKey!);
    }
  }

  void setFreezeDingyin(bool value) {
    state = state.copyWith(freezeDingyin: value);
    if (state.compareSlotKey != null) {
      calculateComparison(state.compareSlotKey!);
    }
  }
}

final graduationProvider =
    StateNotifierProvider<GraduationViewModel, GraduationState>((ref) {
  return GraduationViewModel(ref);
});
