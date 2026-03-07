class SlotInfo {
  final String id;
  final String name;
  final String icon;

  const SlotInfo({required this.id, required this.name, required this.icon});
}

class WeaponTypeInfo {
  final String id;
  final String name;
  final String icon;
  final String statName;

  const WeaponTypeInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.statName,
  });
}

class CommonData {
  CommonData._();

  static const Map<String, double> baseStats = {
    '最小外功攻击': 701.16,
    '最大外功攻击': 1255.58,
    '最小无相攻击': 39.6,
    '最大无相攻击': 39.6,
    '精准率': 100.7,
    '会心率': 24,
    '会意率': 12,
    '劲': 205,
    '敏': 205,
    '势': 205,
    '直接会心率': 0,
    '直接会意率': 0,
    '会心伤害加成': 50,
    '会意伤害加成': 35,
    '会心治疗加成': 50,
    '外功伤害加成': 0,
    '属攻伤害加成': 0,
    '外功治疗加成': 0,
    '外功穿透': 0,
    '属攻穿透': 25.2,
    '全武学增效': 0,
    '指定武学增效': 0,
    '对首领单位增伤': 0,
    '对玩家单位增效': 0,
    '指定武学技能增伤': 0,
    '单体类奇术增伤': 0,
    '群体类奇术增伤': 0,
  };

  static const Map<String, double> seasonStats = {
    '武库最小值': 148,
    '武库最大值': 297,
    '天赋最小属攻': 228,
    '天赋最大属攻': 456,
    '天赋属性增伤': 12.6,
    '五维天赋加成上限': 325,
    '挑战外功抗性': 26,
    '挑战属性抗性': 28,
    'BOSS防御': 498,
    '食物小外加成': 140,
    '食物大外加成': 280,
    '金装武器最小外功': 75,
    '金装武器最大外功': 175,
    '紫装武器最小外功': 68,
    '紫装武器最大外功': 158,
    '金装环最小外功': 100,
    '紫装环最小外功': 90,
    '金装佩最大外功': 150,
    '紫装佩最大外功': 135,
    '武学常驻属性': 150.7,
    '固伤加成': 0.15,
    '赛季抗性': 1.85,
    '基础精准率': 65.065,
    '精准弓加成': 4.7,
    '会心弓加成': 5.2,
    '会意弓加成': 2.6,
    '当前是上半赛季': 0,
    '天赋属性增伤治疗': 12.6,
    '霖霖治疗outerRatio': 7.6408,
    '霖霖治疗eleRatio': 7.6408,
    '霖霖治疗fixed': 2115,
  };

  static const Map<String, double> maxValues = {
    '劲': 57.4,
    '敏': 57.4,
    '势': 57.4,
    '最大外功攻击': 90.6,
    '最小外功攻击': 90.6,
    '精准率': 9.4,
    '会心率': 10.4,
    '会意率': 5.2,
    '最小鸣金攻击': 51.4,
    '最大鸣金攻击': 51.4,
    '最小裂石攻击': 51.4,
    '最大裂石攻击': 51.4,
    '最小牵丝攻击': 51.4,
    '最大牵丝攻击': 51.4,
    '最小破竹攻击': 51.4,
    '最大破竹攻击': 51.4,
    '最小无相攻击': 51.4,
    '最大无相攻击': 51.4,
    '全武学增效': 3.6,
    '对首领单位增伤': 3.8,
    '对玩家单位增效': 3.8,
    '外功穿透': 12.8,
    '无相穿透': 15.2,
    '属攻穿透': 15.2,
    '指定武学技能增伤': 7,
    '单体类奇术增伤': 11.4,
    '群体类奇术增伤': 11.4,
    '剑武学增效': 7.4,
    '枪武学增效': 7.4,
    '伞武学增效': 7.4,
    '扇武学增效': 7.4,
    '绳标武学增效': 7.4,
    '双刀武学增效': 7.4,
    '陌刀武学增效': 7.4,
    '横刀武学增效': 7.4,
    '拳甲武学增效': 7.4,
  };

  static const List<String> percentStats = [
    '精准率', '会心率', '会意率', '直接会心率', '直接会意率',
    '会心伤害加成', '会意伤害加成',
    '外功伤害加成', '属攻伤害加成', '外功治疗加成', '会心治疗加成',
    '全武学增效', '指定武学增效',
    '对首领单位增伤', '对玩家单位增效',
    '指定武学技能增伤', '单体类奇术增伤', '群体类奇术增伤',
    '剑武学增效', '枪武学增效', '伞武学增效', '扇武学增效',
    '绳标武学增效', '双刀武学增效', '陌刀武学增效', '横刀武学增效', '拳甲武学增效',
    '鸣金伤害加成', '裂石伤害加成', '牵丝伤害加成', '破竹伤害加成',
  ];

  static const List<String> baseSubStats = [
    '最小外功攻击', '最大外功攻击',
    '最小鸣金攻击', '最大鸣金攻击',
    '最小裂石攻击', '最大裂石攻击',
    '最小牵丝攻击', '最大牵丝攻击',
    '最小破竹攻击', '最大破竹攻击',
    '精准率', '会心率', '会意率',
    '劲', '敏', '势',
  ];

  static const List<SlotInfo> slots = [
    SlotInfo(id: '1', name: '武器', icon: 'icon1.jpg'),
    SlotInfo(id: '3', name: '环', icon: 'icon3.jpg'),
    SlotInfo(id: '4', name: '佩', icon: 'icon4.jpg'),
    SlotInfo(id: '5', name: '冠胄', icon: 'icon5.jpg'),
    SlotInfo(id: '6', name: '胸甲', icon: 'icon6.jpg'),
    SlotInfo(id: '7', name: '胫甲', icon: 'icon7.jpg'),
    SlotInfo(id: '8', name: '腕甲', icon: 'icon8.jpg'),
  ];

  static const List<WeaponTypeInfo> weaponTypes = [
    WeaponTypeInfo(id: '1', name: '剑', icon: 'icon1_1.jpg', statName: '剑武学增效'),
    WeaponTypeInfo(id: '2', name: '枪', icon: 'icon1_2.jpg', statName: '枪武学增效'),
    WeaponTypeInfo(id: '3', name: '伞', icon: 'icon1_3.jpg', statName: '伞武学增效'),
    WeaponTypeInfo(id: '4', name: '扇', icon: 'icon1_4.jpg', statName: '扇武学增效'),
    WeaponTypeInfo(id: '5', name: '绳标', icon: 'icon1_5.jpg', statName: '绳标武学增效'),
    WeaponTypeInfo(id: '6', name: '双刀', icon: 'icon1_6.jpg', statName: '双刀武学增效'),
    WeaponTypeInfo(id: '7', name: '陌刀', icon: 'icon1_7.jpg', statName: '陌刀武学增效'),
    WeaponTypeInfo(id: '8', name: '横刀', icon: 'icon1_8.jpg', statName: '横刀武学增效'),
    WeaponTypeInfo(id: '9', name: '拳甲', icon: 'icon1_9.jpg', statName: '拳甲武学增效'),
  ];

  static const Map<String, String> slotKeyToId = {
    'weapon1': '1',
    'weapon2': '1',
    'head': '5',
    'chest': '6',
    'ring': '3',
    'pendant': '4',
    'legs': '7',
    'hands': '8',
  };

  static const Map<String, String> slotKeyToName = {
    'weapon1': '武器1',
    'weapon2': '武器2',
    'head': '冠胄',
    'chest': '胸甲',
    'ring': '环',
    'pendant': '佩',
    'legs': '胫甲',
    'hands': '腕甲',
  };

  static const Map<String, Map<String, double>> setData = {
    '玉斗': {'最大外功攻击': 91},
    '飞隼': {'会意率': 5.2},
    '时雨': {'精准率': 9.3},
    '断岳': {'最小外功攻击': 91},
    '烟柳': {'精准率': 9.3},
    '浣花': {'会心率': 10.4},
    '燕归': {'最小外功攻击': 91},
    '连星': {'最小外功攻击': 91},
    '撼天': {'最小外功攻击': 91},
  };

  static const Map<String, List<String>> dingyinRules = {
    '1': ['无', '外功穿透', '属攻穿透'],
    '3': ['无', '外功穿透', '属攻穿透'],
    '4': ['无', '外功穿透', '属攻穿透'],
    '5': ['无', '指定武学技能增伤'],
    '6': ['无', '指定武学技能增伤'],
    '7': ['无', '指定武学技能增伤'],
    '8': ['无', '指定武学技能增伤'],
  };

  static SlotInfo? getSlotById(String id) {
    try {
      return slots.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static WeaponTypeInfo? getWeaponTypeById(String id) {
    try {
      return weaponTypes.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  static bool isPercentStat(String statName) => percentStats.contains(statName);

  /// Stat quality threshold (same as source site: 87.55%)
  static const double _qualityGoldThreshold = 87.55;

  /// Returns the ratio of the stat value to its max value (0.0 ~ 1.0+).
  /// Returns null if max value is not defined for this stat type.
  static double? getStatRatio(String statType, double value) {
    final maxVal = maxValues[statType];
    if (maxVal == null || maxVal <= 0) return null;
    return value / maxVal;
  }

  /// Returns 'gold', 'purple', or 'gray' based on source site rules.
  /// - value/maxValue > 87.55% => gold
  /// - otherwise => purple
  /// - unknown stat type or survival stat => gray
  static String getStatQuality(String statType, double value) {
    if (statType == '\u751F\u5B58\u7C7B\u8BCD\u6761') return 'gray';
    final ratio = getStatRatio(statType, value);
    if (ratio == null) return 'gray';
    return (ratio * 100 > _qualityGoldThreshold) ? 'gold' : 'purple';
  }

  static List<String> getAvailableSubStats(String? slotId, String? weaponTypeId) {
    var stats = [...baseSubStats];
    if (slotId == '1') {
      stats = stats.where((e) =>
        !e.contains('鸣金') && !e.contains('裂石') &&
        !e.contains('破竹') && !e.contains('牵丝')
      ).toList();
      final wt = weaponTypeId != null ? getWeaponTypeById(weaponTypeId) : null;
      if (wt != null) stats.add(wt.statName);
      stats.addAll(['最大无相攻击', '最小无相攻击']);
    }
    if (slotId == '3' || slotId == '4') {
      stats.add('全武学增效');
    }
    if (slotId == '5' || slotId == '6') {
      stats.addAll(['单体类奇术增伤', '群体类奇术增伤']);
    }
    if (slotId == '7' || slotId == '8') {
      stats.addAll(['对首领单位增伤', '对玩家单位增效']);
    }
    stats.add('生存类词条');
    stats.sort((a, b) {
      final diff = a.length - b.length;
      return diff != 0 ? diff : a.compareTo(b);
    });
    return stats;
  }
}
