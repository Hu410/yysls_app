import 'dart:math';
import '../models/equipment.dart';
import '../data/common_data.dart';
import '../data/class_config.dart';
import '../data/rotation_data.dart';
import '../data/skill_data.dart';
import '../data/xinfa_bonus.dart';

class StatModEntry {
  final String type;
  final double value;
  final String operation; // 'add' or 'remove'
  const StatModEntry({required this.type, required this.value, this.operation = 'add'});
}

class StatResult {
  final Map<String, double> stats;
  final double totalMinOuter;
  final double totalMaxOuter;
  final double totalMinEle;
  final double totalMaxEle;

  const StatResult({
    required this.stats,
    this.totalMinOuter = 0,
    this.totalMaxOuter = 0,
    this.totalMinEle = 0,
    this.totalMaxEle = 0,
  });

  double get(String key) => stats[key] ?? 0;
}

class GraduationResult {
  final double graduationRate;
  final int totalDamage;

  const GraduationResult({this.graduationRate = 0, this.totalDamage = 0});
}

class Calculator {
  Calculator._();

  static StatResult calculateTotal(
    Map<String, Equipment?> equipped,
    String? className,
    String bowType,
    List<String?> xinfa,
    String? setBonus,
    bool earlySeasonBonus,
    bool pvpMode, {
    List<StatModEntry>? statModifier,
    bool skipDingyin = false,
    List<double>? loanDingyinValue,
  }) {
    final d = Map<String, double>.from(CommonData.baseStats);
    double baseSensitivity = CommonData.baseStats['敏'] ?? 205;
    final fiveCap = CommonData.seasonStats['五维天赋加成上限'] ?? 325;
    final resistance = CommonData.seasonStats['赛季抗性'] ?? 1.85;
    final basePrecision = CommonData.seasonStats['基础精准率'] ?? 65.065;

    // 1. Class talent: element attack + armory
    if (className != null && className.isNotEmpty) {
      final elePrefix = className.substring(0, 2);
      final minEleKey = '最小$elePrefix攻击';
      final maxEleKey = '最大$elePrefix攻击';
      final eleDmgKey = '$elePrefix伤害加成';
      d[minEleKey] = (d[minEleKey] ?? 0) + (CommonData.seasonStats['天赋最小属攻'] ?? 0);
      d[maxEleKey] = (d[maxEleKey] ?? 0) + (CommonData.seasonStats['天赋最大属攻'] ?? 0);

      // Armory: per-class element or 通用
      final armory = ClassConfig.getArmoryForClass(className);
      if (armory != '通用') {
        final armMinKey = '最小$armory攻击';
        final armMaxKey = '最大$armory攻击';
        d[armMinKey] = (d[armMinKey] ?? 0) + (CommonData.seasonStats['武库最小值'] ?? 0);
        d[armMaxKey] = (d[armMaxKey] ?? 0) + (CommonData.seasonStats['武库最大值'] ?? 0);
      } else {
        d['最小外功攻击'] = (d['最小外功攻击'] ?? 0) + (CommonData.seasonStats['武库最小值'] ?? 0);
        d['最大外功攻击'] = (d['最大外功攻击'] ?? 0) + (CommonData.seasonStats['武库最大值'] ?? 0);
      }

      if (className != '牵丝霖') {
        d[eleDmgKey] = (d[eleDmgKey] ?? 0) + (CommonData.seasonStats['天赋属性增伤'] ?? 0);
      }
    }

    // 2. Equipment stats
    for (final entry in equipped.entries) {
      final equip = entry.value;
      if (equip == null) continue;

      // Slot base values (weapon/ring/pendant white values)
      if (equip.slotId == '1') {
        final isP = equip.isPurple;
        d['最小外功攻击'] = (d['最小外功攻击'] ?? 0) +
            (CommonData.seasonStats[isP ? '紫装武器最小外功' : '金装武器最小外功'] ?? 0);
        d['最大外功攻击'] = (d['最大外功攻击'] ?? 0) +
            (CommonData.seasonStats[isP ? '紫装武器最大外功' : '金装武器最大外功'] ?? 0);
      } else if (equip.slotId == '3') {
        d['最小外功攻击'] = (d['最小外功攻击'] ?? 0) +
            (CommonData.seasonStats[equip.isPurple ? '紫装环最小外功' : '金装环最小外功'] ?? 0);
      } else if (equip.slotId == '4') {
        d['最大外功攻击'] = (d['最大外功攻击'] ?? 0) +
            (CommonData.seasonStats[equip.isPurple ? '紫装佩最大外功' : '金装佩最大外功'] ?? 0);
      }

      // Main stat
      if (equip.mainStat.type != '生存类词条' && equip.mainStat.type != '生存向') {
        _addStat(d, equip.mainStat.type, equip.mainStat.value);
      }

      // Dingyin stat: skip when skipDingyin=true (loan dingyin mode)
      if (equip.dingyinStat != null && !skipDingyin) {
        _addStat(d, equip.dingyinStat!.type, equip.dingyinStat!.value);
      }

      // Sub stats
      for (final sub in equip.subStats) {
        if (sub.type != '生存类词条' && sub.type != '生存向') {
          _addStat(d, sub.type, sub.value);
        }
      }
    }

    // Loan dingyin: override specific stats
    if (skipDingyin && loanDingyinValue != null && loanDingyinValue.length >= 3) {
      d['外功穿透'] = loanDingyinValue[0];
      d['属攻穿透'] = (d['属攻穿透'] ?? 0) + loanDingyinValue[1];
      d['指定武学技能增伤'] = loanDingyinValue[2];
    }

    // 3. Xinfa bonuses
    for (final xf in xinfa) {
      if (xf == null) continue;
      final bonus = XinfaBonus.getBonus(xf);
      if (bonus != null) {
        for (final e in bonus.entries) {
          d[e.key] = (d[e.key] ?? 0) + e.value;
        }
      }
    }

    // 4. Set bonus
    if (setBonus != null && CommonData.setData.containsKey(setBonus)) {
      final setStats = CommonData.setData[setBonus]!;
      for (final e in setStats.entries) {
        d[e.key] = (d[e.key] ?? 0) + e.value;
      }
    }

    // 5. Stat modifier (supports add/remove with 劲/敏/势 floor)
    if (statModifier != null) {
      for (final mod in statModifier) {
        if (mod.type == '生存类词条') continue;
        final val = mod.value;
        if (mod.operation == 'add') {
          d[mod.type] = (d[mod.type] ?? 0) + val;
        } else if (mod.operation == 'remove') {
          d[mod.type] = (d[mod.type] ?? 0) - val;
          if ((d[mod.type] ?? 0) < 0) d[mod.type] = 0;
          if (mod.type == '劲' || mod.type == '敏' || mod.type == '势') {
            if ((d[mod.type] ?? 0) < baseSensitivity) d[mod.type] = baseSensitivity;
          }
        }
      }
    }

    // 6. Early season bonus (only when 当前是上半赛季)
    if (earlySeasonBonus && (CommonData.seasonStats['当前是上半赛季'] ?? 0) > 0) {
      d['劲'] = (d['劲'] ?? 0) + 14;
      d['敏'] = (d['敏'] ?? 0) + 14;
      d['势'] = (d['势'] ?? 0) + 14;
      baseSensitivity += 14;
      d['精准率'] = (d['精准率'] ?? 0) + 1.4;
    }

    // 7. Attribute conversion (劲/敏/势 -> outer/crit/intent)
    final jin = d['劲'] ?? 0;
    final minS = d['敏'] ?? 0;
    final shi = d['势'] ?? 0;

    d['最小外功攻击'] = (d['最小外功攻击'] ?? 0) + 0.22 * jin + 0.9 * minS;
    d['最大外功攻击'] = (d['最大外功攻击'] ?? 0) + 1.36 * jin + 0.9 * shi;
    d['会心率'] = (d['会心率'] ?? 0) + 0.076 * minS;
    d['会意率'] = (d['会意率'] ?? 0) + 0.038 * shi;

    // 8. Class-specific attribute conversion
    if (className == '鸣金虹') {
      final capShi = min(shi, fiveCap);
      d['会意率'] = (d['会意率'] ?? 0) + 0.01523 * capShi;
      d['最大外功攻击'] = (d['最大外功攻击'] ?? 0) + 0.264 * capShi;
    } else if (className == '鸣金影') {
      final capJin = min(jin, fiveCap);
      d['会意率'] = (d['会意率'] ?? 0) + 0.01523 * capJin;
      d['最大外功攻击'] = (d['最大外功攻击'] ?? 0) + 0.264 * capJin;
    } else if (className == '破竹鸢' || className == '破竹尘' ||
        className == '破竹风' || className == '牵丝玉' ||
        className == '牵丝霖' || className == '裂石钧' ||
        className == '裂石钧（纯唐）') {
      final capMin = min(minS, fiveCap);
      d['会心率'] = (d['会心率'] ?? 0) + 0.03046 * capMin;
      d['最小外功攻击'] = (d['最小外功攻击'] ?? 0) + 0.264 * capMin;
    } else if (className == '裂石威') {
      final capJin = min(jin, fiveCap);
      d['会心率'] = (d['会心率'] ?? 0) + 0.03046 * capJin;
    }

    // 9. Bow bonus
    switch (bowType) {
      case 'precision':
        d['精准率'] = (d['精准率'] ?? 0) + (CommonData.seasonStats['精准弓加成'] ?? 4.7);
      case 'crit':
        d['会心率'] = (d['会心率'] ?? 0) + (CommonData.seasonStats['会心弓加成'] ?? 5.2);
      case 'intent':
        d['会意率'] = (d['会意率'] ?? 0) + (CommonData.seasonStats['会意弓加成'] ?? 2.6);
    }

    // 10. Rate conversion via 赛季抗性
    double extraCrit = 0;
    if (className == '裂石威') extraCrit += 24;
    if (setBonus == '浣花') extraCrit += 5;

    double actualCrit = (d['会心率'] ?? 0) / resistance + extraCrit;
    double critOverflow = 0;
    if (actualCrit > 80) {
      critOverflow = (actualCrit - 80) * resistance;
      actualCrit -= extraCrit;
      if (actualCrit > 80) actualCrit = 80;
    } else if (extraCrit != 0) {
      actualCrit -= extraCrit;
    }

    double actualIntent = (d['会意率'] ?? 0) / resistance;
    double intentOverflow = 0;
    if (actualIntent > 40) {
      intentOverflow = (actualIntent - 40) * resistance;
      actualIntent = 40;
    }

    double actualPrecision = ((d['精准率'] ?? 0) - basePrecision) / resistance + basePrecision;
    double precisionOverflow = 0;
    if (actualPrecision > 100) {
      precisionOverflow = (actualPrecision - 100) * resistance;
      actualPrecision = 100;
    }

    // Total crit+intent overflow check (JS uses min(actualCrit+extraCrit, 80))
    double effectiveCrit = (actualCrit + extraCrit > 80) ? 80 : (actualCrit + extraCrit);
    double totalCritIntent = effectiveCrit + actualIntent + (d['直接会心率'] ?? 0) + (d['直接会意率'] ?? 0);
    if (totalCritIntent > 100) {
      critOverflow += (totalCritIntent - 100) * resistance;
    }

    d['实际会心率'] = actualCrit;
    d['会心率溢出'] = critOverflow;
    d['实际会意率'] = actualIntent;
    d['会意率溢出'] = intentOverflow;
    d['实际精准率'] = actualPrecision;
    d['精准率溢出'] = precisionOverflow;

    final resultStats = Map<String, double>.from(d);

    // Remove raw values and handle healing class
    resultStats.remove('劲');
    resultStats.remove('敏');
    resultStats.remove('势');
    resultStats.remove('精准率');
    resultStats.remove('会心率');
    resultStats.remove('会意率');

    if (ClassConfig.isHealingClass(className ?? '', xinfa)) {
      resultStats['属攻治疗加成'] = CommonData.seasonStats['天赋属性增伤'] ?? 12.6;
    } else {
      resultStats.remove('会心治疗加成');
      resultStats.remove('外功治疗加成');
      if (className == '牵丝霖') {
        resultStats.remove('指定武学技能增伤');
      }
    }

    return StatResult(
      stats: resultStats,
      totalMinOuter: resultStats['最小外功攻击'] ?? 0,
      totalMaxOuter: resultStats['最大外功攻击'] ?? 0,
      totalMinEle: resultStats['最小无相攻击'] ?? 0,
      totalMaxEle: resultStats['最大无相攻击'] ?? 0,
    );
  }

  static void _addStat(Map<String, double> stats, String type, double value) {
    stats[type] = (stats[type] ?? 0) + value;
  }

  static List<MapEntry<String, String>> getDisplayStats(StatResult result) {
    return [
      MapEntry('最小外功攻击', result.get('最小外功攻击').toStringAsFixed(1)),
      MapEntry('最大外功攻击', result.get('最大外功攻击').toStringAsFixed(1)),
      MapEntry('最小无相攻击', result.get('最小无相攻击').toStringAsFixed(1)),
      MapEntry('最大无相攻击', result.get('最大无相攻击').toStringAsFixed(1)),
      MapEntry('实际精准率', '${result.get('实际精准率').toStringAsFixed(1)}%'),
      MapEntry('实际会心率', '${result.get('实际会心率').toStringAsFixed(1)}%'),
      MapEntry('实际会意率', '${result.get('实际会意率').toStringAsFixed(1)}%'),
      MapEntry('会心伤害加成', '${result.get('会心伤害加成').toStringAsFixed(1)}%'),
      MapEntry('会意伤害加成', '${result.get('会意伤害加成').toStringAsFixed(1)}%'),
      MapEntry('外功穿透', '${result.get('外功穿透').toStringAsFixed(1)}%'),
      MapEntry('属攻穿透', '${result.get('属攻穿透').toStringAsFixed(1)}%'),
      MapEntry('外功伤害加成', '${result.get('外功伤害加成').toStringAsFixed(1)}%'),
      MapEntry('属攻伤害加成', '${result.get('属攻伤害加成').toStringAsFixed(1)}%'),
      MapEntry('直接会心率', '${result.get('直接会心率').toStringAsFixed(1)}%'),
      MapEntry('直接会意率', '${result.get('直接会意率').toStringAsFixed(1)}%'),
      MapEntry('全武学增效', '${result.get('全武学增效').toStringAsFixed(1)}%'),
      MapEntry('对首领单位增伤', '${result.get('对首领单位增伤').toStringAsFixed(1)}%'),
    ];
  }

  // ============ Graduation Rate ============

  static double getBaseLineByClass(String className, List<String?> xinfaList) {
    final config = RotationData.getConfig(className);
    if (config == null) return 1;
    double baseline = config.baseline;
    if (xinfaList.any((x) => x == '断石之构' || x == '大唐歌') && className == '破竹尘') {
      baseline = config.baseline2;
    }
    if (ClassConfig.isHealingClass(className, xinfaList)) {
      baseline = config.baseline2;
    }
    return baseline == 0 ? 1 : baseline;
  }

  static GraduationResult calculateGraduationRate({
    required Map<String, double> panelStats,
    required String className,
    required List<String?> xinfaList,
    required String setName,
    bool pvpMode = false,
  }) {
    final config = RotationData.getConfig(className);
    if (config == null) return const GraduationResult();

    final skillDb = SkillDatabase.getSkillDb(config.skillDatabaseKey);
    if (skillDb == null || skillDb.isEmpty) return const GraduationResult();

    final rotation = config.rotation;
    if (rotation.isEmpty) return const GraduationResult();

    final baseline = getBaseLineByClass(className, xinfaList);

    double ps(String key) => panelStats[key] ?? 0;
    bool hasXinfa(String name) => xinfaList.contains(name);

    if (ClassConfig.isHealingClass(className, xinfaList)) {
      return _calculateHealingGraduation(
        panelStats: panelStats,
        xinfaList: xinfaList,
        setName: setName,
        baseline: baseline,
      );
    }

    // Determine primary element
    final eleMap = {
      '破竹': ps('最大破竹攻击'),
      '鸣金': ps('最大鸣金攻击'),
      '裂石': ps('最大裂石攻击'),
      '牵丝': ps('最大牵丝攻击'),
      '无相': ps('最大无相攻击'),
    };
    String primaryEle = '无';
    double maxEle = -1;
    for (final e in eleMap.entries) {
      if (e.value > maxEle) { maxEle = e.value; primaryEle = e.key; }
    }

    final double elePen = ps('属攻穿透');
    final double eleDmgBonus = ps('属攻伤害加成');

    // Build combat stats
    final r = _CombatStats(
      minOuter: ps('最小外功攻击'),
      maxOuter: ps('最大外功攻击'),
      outerPen: ps('外功穿透'),
      minPoZhu: ps('最小破竹攻击'), maxPoZhu: ps('最大破竹攻击'),
      poZhuPen: ps('破竹穿透') + (primaryEle == '破竹' ? elePen : 0),
      minMingJin: ps('最小鸣金攻击'), maxMingJin: ps('最大鸣金攻击'),
      mingJinPen: ps('鸣金穿透') + (primaryEle == '鸣金' ? elePen : 0),
      minLieShi: ps('最小裂石攻击'), maxLieShi: ps('最大裂石攻击'),
      lieShiPen: ps('裂石穿透') + (primaryEle == '裂石' ? elePen : 0),
      minQianSi: ps('最小牵丝攻击'), maxQianSi: ps('最大牵丝攻击'),
      qianSiPen: ps('牵丝穿透') + (primaryEle == '牵丝' ? elePen : 0),
      minWuXiang: ps('最小无相攻击'), maxWuXiang: ps('最大无相攻击'),
      wuXiangPen: ps('无相穿透') + (primaryEle == '无相' ? elePen : 0),
      outerDmgBonus: ps('外功伤害加成'),
      poZhuDmgBonus: ps('破竹伤害加成') + eleDmgBonus,
      mingJinDmgBonus: ps('鸣金伤害加成') + eleDmgBonus,
      lieShiDmgBonus: ps('裂石伤害加成') + eleDmgBonus,
      qianSiDmgBonus: ps('牵丝伤害加成') + eleDmgBonus,
      critRate: ps('实际会心率'),
      intentRate: ps('实际会意率'),
      precision: ps('实际精准率'),
      directCrit: ps('直接会心率'),
      directIntent: ps('直接会意率'),
      critDmgBonus: ps('会心伤害加成'),
      intentDmgBonus: ps('会意伤害加成'),
      bossDmgBonus: ps('对首领单位增伤'),
      playerDmgBonus: ps('对玩家单位增效'),
      allArtsDmgBonus: ps('全武学增效'),
      singleMagicBonus: ps('单体类奇术增伤'),
      groupMagicBonus: ps('群体类奇术增伤'),
      specificSkillBonus: ps('指定武学技能增伤'),
      fixedDmgBonus: ps('固伤加成'),
    );

    // Weapon bonus map
    final weaponBonusMap = <String, double>{
      '剑': ps('剑武学增效'), '枪': ps('枪武学增效'),
      '伞': ps('伞武学增效'), '扇': ps('扇武学增效'),
      '绳标': ps('绳标武学增效'), '双刀': ps('双刀武学增效'),
      '陌刀': ps('陌刀武学增效'), '横刀': ps('横刀武学增效'),
      '拳甲': ps('拳甲武学增效'),
    };

    // BOSS defense (牵丝霖 automatically gets 所恨年年 effect)
    double bossDef = CommonData.seasonStats['BOSS防御'] ?? 498;
    final hasSuoHen = hasXinfa('所恨年年') || className == '牵丝霖';
    if (hasSuoHen) bossDef *= 0.94;

    // Challenge resistances
    double challengeOuterRes = CommonData.seasonStats['挑战外功抗性'] ?? 26;

    double totalK = 0;
    double includedR = 0;

    for (final entry in rotation) {
      final skill = skillDb[entry.name];
      if (skill == null) continue;

      double challengeMul = entry.tiaozhan ?? 1;

      // Per-skill element conversion from wuxiang
      double sMinPoZhu = r.minPoZhu, sMaxPoZhu = r.maxPoZhu, sPoZhuPen = r.poZhuPen;
      double sMinMingJin = r.minMingJin, sMaxMingJin = r.maxMingJin, sMingJinPen = r.mingJinPen;
      double sMinLieShi = r.minLieShi, sMaxLieShi = r.maxLieShi, sLieShiPen = r.lieShiPen;
      double sMinQianSi = r.minQianSi, sMaxQianSi = r.maxQianSi, sQianSiPen = r.qianSiPen;

      if (skill.element.isNotEmpty && skill.element != '无' && skill.element != 'N/A') {
        switch (skill.element) {
          case '破竹':
            sMinPoZhu += r.minWuXiang; sMaxPoZhu += r.maxWuXiang; sPoZhuPen += r.wuXiangPen;
          case '鸣金':
            sMinMingJin += r.minWuXiang; sMaxMingJin += r.maxWuXiang; sMingJinPen += r.wuXiangPen;
          case '裂石':
            sMinLieShi += r.minWuXiang; sMaxLieShi += r.maxWuXiang; sLieShiPen += r.wuXiangPen;
          case '牵丝':
            sMinQianSi += r.minWuXiang; sMaxQianSi += r.maxWuXiang; sQianSiPen += r.wuXiangPen;
        }
      }

      // Crit/Intent rates
      double dCrit = r.critRate / 100 + skill.exCrit;
      if (setName == '浣花') dCrit += 0.05;
      double dIntent = r.intentRate / 100 + skill.exIntent;

      // 长风: +3% intent rate (by skill.modifiers['长风'])
      final hasChangFeng = skill.modifiers['长风'] != null && skill.modifiers['长风'] != false;
      if (hasChangFeng) dIntent += 0.03;
      // 玉斗 set: +7.5% intent rate with 长风
      if (setName == '玉斗' && hasChangFeng) dIntent += 0.075;

      double precisionRate = r.precision / 100;
      if (precisionRate > 1) precisionRate = 1;

      if (skill.force == '会心') { dCrit = 1; dIntent = 0; precisionRate = 1; }
      else if (skill.force == '会意') { dCrit = 0; dIntent = 1; precisionRate = 1; }

      if (dCrit > 0.8) dCrit = 0.8;
      dCrit += r.directCrit / 100;
      if (dIntent > 0.4) dIntent = 0.4;
      dIntent += r.directIntent / 100;

      // Hit distribution
      double mGlance = (1 - precisionRate) * (1 - dIntent);
      if (skill.force == '不擦伤') mGlance = 0;
      double xIntent = dIntent;
      double gCrit = (dCrit + dIntent <= 1) ? dCrit * precisionRate : precisionRate * (1 - dIntent);
      double yNormal = max(0, 1 - mGlance - gCrit - xIntent);

      // Crit/Intent damage multipliers
      double critMul = 1 + r.critDmgBonus / 100 + skill.exCritDmg;
      double intentMul = 1 + r.intentDmgBonus / 100 + skill.exIntentDmg;

      // 断石之构: only for skills with modifiers['断石']
      final hasSkillDuanShi = skill.modifiers['断石'] != null && skill.modifiers['断石'] != false;
      if (hasSkillDuanShi && hasXinfa('断石之构')) {
        critMul += 25 / 100;
      }

      // Set-specific crit/intent bonuses
      if (setName == '时雨') critMul += 0.1;
      if (setName == '浣花') critMul += 0.15;
      if (entry.name.contains('Q') && hasXinfa('大唐歌')) critMul += 0.15;
      if (setName == '玉斗' && skill.modifiers['玉斗'] != null) intentMul += 0.1;
      if (hasXinfa('凝神章')) intentMul += 0.1;
      if (skill.modifiers['移经'] != null && hasXinfa('移经易武')) critMul += 0.2;

      // 抗造盾+时雨: crit damage +15% (only for skills with 抗造盾 in name)
      if (entry.name.contains('抗造盾') && hasXinfa('抗造大法') && setName == '时雨') critMul += 0.15;

      // 穿喉决: crit damage from skill modifier
      final chouHou = skill.modifiers['穿喉'];
      if (chouHou != null && chouHou is num && chouHou > 0 && hasXinfa('穿喉决')) {
        critMul += chouHou.toDouble() / 100;
      }

      // BOSS defense per skill (恶身, 涌泉)
      double skillBossDef = bossDef;
      if (skill.modifiers['恶身'] != null) skillBossDef *= 0.9;
      if (entry.yongquan == true) skillBossDef *= 0.95;

      // Outer attack: A multiplier (飞隼/撼天/exATK) + 陌刀天赋
      double outerAtkMul = 1.0;
      if (setName == '飞隼') {
        outerAtkMul = 1.1;
      } else if (setName == '撼天') {
        outerAtkMul = 1.05;
      }
      outerAtkMul += skill.exATK;

      double outerMin = max(0, r.minOuter * outerAtkMul - skillBossDef + (CommonData.seasonStats['食物小外加成'] ?? 140));
      double outerMax = max(0, r.maxOuter * outerAtkMul - skillBossDef + (CommonData.seasonStats['食物大外加成'] ?? 280));

      // 陌刀天赋
      if (skill.special == '陌刀天赋') outerMax += 120;

      if (outerMax < outerMin) outerMax = outerMin;
      double outerAvg = (outerMin + outerMax) / 2;

      // Outer penetration build-up (z in JS)
      double zOuterPen = r.outerPen;

      // exPen from skill
      zOuterPen += skill.exPen;

      // 断石之构: +25 to outer pen for matching skills
      if (hasSkillDuanShi && hasXinfa('断石之构')) zOuterPen += 25;

      // 所恨年年: +10
      if (hasSuoHen) zOuterPen += 10;

      // 易水歌
      if (hasXinfa('易水歌') && entry.yishui > 0) zOuterPen += entry.yishui;

      // 三穷致知: +20 when skill.modifiers['三穷']==2
      final sanQiong = skill.modifiers['三穷'];
      if (sanQiong != null && sanQiong == 2 && hasXinfa('三穷致知')) zOuterPen += 20;

      // 穿喉决: modifiers['穿喉'] adds to outer pen
      if (chouHou != null && chouHou is num && chouHou > 0 && hasXinfa('穿喉决')) {
        zOuterPen += chouHou.toDouble();
      }

      // 牵丝霖 challenge resistance reduction on outer pen (unconditional)
      if (className == '牵丝霖') {
        zOuterPen -= challengeOuterRes;
      }

      // z < 0 doubles the effect
      double outerPenRate = zOuterPen < 0 ? zOuterPen * 2 / 200 : zOuterPen / 200;

      double outerDmgBonusVal = r.outerDmgBonus;

      // 鼠鼠: outer damage +24% (by skill.special)
      if (skill.special == '鼠鼠') outerDmgBonusVal += 24;
      // 回旋伞: outer damage +15% (by skill.special)
      if (skill.special == '回旋伞') outerDmgBonusVal += 15;
      // 破竹鸢 +9% outer AND element damage (when skill name doesn't contain 无返豆)
      double pozhuDmgExtra = 0;
      if (className == '破竹鸢' && !entry.name.contains('无返豆')) {
        outerDmgBonusVal += 9;
        pozhuDmgExtra = 9;
      }

      // Single damage function
      double dmg(double atk, double ratio, double pen, double bonus, double critF) {
        return atk * ratio * (1 + pen) * (1 + bonus / 100) * critF;
      }

      // Outer damage template
      double outerH = dmg(outerMin, skill.outerRatio, outerPenRate, outerDmgBonusVal, 1);
      double outerX = dmg(outerAvg, skill.outerRatio, outerPenRate, outerDmgBonusVal, critMul);
      double outerG = dmg(outerMax, skill.outerRatio, outerPenRate, outerDmgBonusVal, intentMul);
      double outerY = dmg(outerAvg, skill.outerRatio, outerPenRate, outerDmgBonusVal, 1);
      double outerExp = outerH * mGlance + outerX * gCrit + outerG * xIntent + outerY * yNormal;

      // Fixed damage
      double fixedBase = skill.fixed.toDouble();
      if (skill.type == '武器') fixedBase *= (1 + r.fixedDmgBonus);
      double fixedH = dmg(fixedBase, 1, outerPenRate, outerDmgBonusVal, 1);
      double fixedX = dmg(fixedBase, 1, outerPenRate, outerDmgBonusVal, critMul);
      double fixedG = dmg(fixedBase, 1, outerPenRate, outerDmgBonusVal, intentMul);
      double fixedExp = fixedH * (mGlance + yNormal) + fixedX * gCrit + fixedG * xIntent;

      // Shared element pen modifiers (computed once per skill)
      double sharedElePen = 0;
      if (sanQiong != null && (sanQiong == 1 || (sanQiong == 2 && hasXinfa('三穷致知')))) sharedElePen += 20;
      if ((skill.special == '撼天' || skill.special == '鼠鼠') && setName == '撼天') sharedElePen += 4;
      if (skill.special == '额外全属性穿透') sharedElePen += 8;
      if (className == '牵丝霖') sharedElePen -= CommonData.seasonStats['挑战属性抗性'] ?? 28;

      // Per-element extra pen (JS: ce=苦果→破竹, me=额外鸣金穿透→鸣金, xe=裂石钧→裂石)
      double kuGuoPen = 0;
      final kuGuo = skill.modifiers['苦果'];
      if (kuGuo != null && kuGuo != false) kuGuoPen = 10;

      double extraMingJinPen = 0;
      if (skill.special == '额外鸣金穿透') extraMingJinPen = 15;

      double extraLieShiPen = 0;
      if (className == '裂石钧' || className == '裂石钧（纯唐）') extraLieShiPen = 12;

      // Build per-element total pen (matches JS: ge, ye, he, fe)
      double poZhuTotalPen = sPoZhuPen + sharedElePen + kuGuoPen;
      double mingJinTotalPen = sMingJinPen + sharedElePen + extraMingJinPen;
      double lieShiTotalPen = sLieShiPen + sharedElePen + extraLieShiPen;
      double qianSiTotalPen = sQianSiPen + sharedElePen;

      // Element damage helper — JS: se(e,t,i,s,l)
      double calcEle(String eleName, double eMin, double eMax, double totalPen, double bonus) {
        double setMul = setName == '撼天' ? 1.05 : 1;
        double wuXueConst = (skill.type == '武器' && skill.element == eleName)
            ? (CommonData.seasonStats['武学常驻属性'] ?? 150.7) * (1 + r.fixedDmgBonus)
            : 0;
        double aMin = eMin * setMul + wuXueConst;
        double aMax = eMax * setMul + wuXueConst;
        if (aMax < aMin) aMax = aMin;
        double avg = (aMin + aMax) / 2;

        double penRate = totalPen < 0 ? totalPen * 2 / 200 : totalPen / 200;
        double ratio = (skill.element == eleName) ? skill.eleRatio : skill.outerRatio;

        double eH = dmg(aMin, ratio, penRate, bonus, 1);
        double eS = dmg(avg, ratio, penRate, bonus, 1);
        double eI = dmg(avg, ratio, penRate, bonus, critMul);
        double eV = dmg(aMax, ratio, penRate, bonus, intentMul);
        return eH * mGlance + eS * yNormal + eI * gCrit + eV * xIntent;
      }

      // Element damages — JS calls se() for all 4 elements unconditionally
      double elePoZhu = calcEle('破竹', sMinPoZhu, sMaxPoZhu, poZhuTotalPen, r.poZhuDmgBonus + pozhuDmgExtra);
      double eleMingJin = calcEle('鸣金', sMinMingJin, sMaxMingJin, mingJinTotalPen, r.mingJinDmgBonus);
      double eleLieShi = calcEle('裂石', sMinLieShi, sMaxLieShi, lieShiTotalPen, r.lieShiDmgBonus);
      double eleQianSi = calcEle('牵丝', sMinQianSi, sMaxQianSi, qianSiTotalPen, r.qianSiDmgBonus);

      // Global multiplier f (additive)
      double globalH = 0;
      if (skill.type == '武器' || skill.type == '心法') {
        if (skill.weaponType != 'N/A' && skill.weaponType.isNotEmpty) {
          globalH += r.allArtsDmgBonus / 100;
        }
      }
      final wb = weaponBonusMap[skill.weaponType] ?? 0;
      if (wb != 0) globalH += wb / 100;
      if (skill.weaponType == '单体奇术') globalH += r.singleMagicBonus / 100;
      if (skill.weaponType == '群体奇术') globalH += r.groupMagicBonus / 100;

      double globalF = 1 + entry.generalBonus;
      // Boss or PVP damage bonus
      globalF += pvpMode ? r.playerDmgBonus / 100 : r.bossDmgBonus / 100;
      globalF += globalH;

      // Set-specific global bonuses
      if (setName == '连星') globalF += (skill.modifiers['连星'] as num?)?.toDouble() ?? 0;
      double duanYueBonus = 0;
      if (setName == '断岳') {
        duanYueBonus = 0.05;
        if (skill.modifiers['断岳'] != null) duanYueBonus += 0.05;
      }
      globalF += duanYueBonus;
      if (skill.modifiers['烟柳'] != null && setName == '烟柳') globalF += 0.12;

      // Xinfa-specific global bonuses
      if (skill.isCharge == 1 && hasXinfa('威猛歌')) globalF += 0.15;
      if (hasXinfa('抗造大法')) globalF += 0.1;
      if (hasXinfa('征人归')) globalF += 0.08;
      if (hasXinfa('明晦同尘')) globalF += 0.05;
      if (entry.chunlei != null && entry.chunlei!.trim().isNotEmpty && hasXinfa('春雷篇')) {
        globalF += 0.15;
      }

      // Total single skill
      double singleExp = (outerExp + fixedExp + elePoZhu + eleMingJin + eleLieShi + eleQianSi) * globalF;

      if (entry.isDingyin) singleExp *= 1 + r.specificSkillBonus / 100;

      double skillTotal = singleExp * entry.count * challengeMul;
      totalK += skillTotal;
      if (entry.included) includedR += skillTotal;
    }

    // Settlement bonus (破竹 classes)
    double settlementRate = 0;
    if (className == '破竹尘') settlementRate = 0.1;
    if (className == '破竹风') settlementRate = 0.3;
    if (settlementRate > 0) totalK += includedR * settlementRate;

    final rate = totalK / baseline * 100;
    return GraduationResult(graduationRate: rate, totalDamage: totalK.round());
  }

  /// Healing calculation for 牵丝霖 (奶扇) — matches JS isHealingClass() branch
  static GraduationResult _calculateHealingGraduation({
    required Map<String, double> panelStats,
    required List<String?> xinfaList,
    required String setName,
    required double baseline,
  }) {
    double ps(String key) => panelStats[key] ?? 0;
    bool hasXinfa(String name) => xinfaList.contains(name);

    final healRatio = CommonData.seasonStats['霖霖治疗outerRatio'] ?? 7.6408;
    final eleHealRatio = CommonData.seasonStats['霖霖治疗eleRatio'] ?? 7.6408;

    // Crit rate
    double critRate = ps('实际会心率') / 100;
    if (setName == '浣花') critRate += 0.05;
    if (critRate > 0.8) critRate = 0.8;
    critRate += ps('直接会心率') / 100;

    // Crit heal multiplier
    double critHealMul = 1 + ps('会心治疗加成') / 100;
    if (setName == '浣花') critHealMul += 0.15;
    if (setName == '时雨') critHealMul += 0.1;

    // Global heal bonus (f in JS)
    double globalHeal = ps('全武学增效') / 100;
    globalHeal += ps('扇武学增效') / 100;
    double totalGlobalHeal = 1 + globalHeal + (hasXinfa('杏花不见') ? 0.24 : 0);
    totalGlobalHeal += 0.3; // 天赋
    totalGlobalHeal += 0.05; // 易水歌 (always present for 牵丝霖)
    if (hasXinfa('明晦同尘')) totalGlobalHeal += 0.075;
    if (hasXinfa('征人归')) totalGlobalHeal += 0.09;
    totalGlobalHeal += ps('对玩家单位增效') / 100;

    // 无相 → 牵丝 conversion
    double minQianSi = ps('最小牵丝攻击') + ps('最小无相攻击');
    double maxQianSi = ps('最大牵丝攻击') + ps('最大无相攻击');
    double qianSiPen = ps('牵丝穿透') + ps('无相穿透');

    // 易水歌 outer pen bonus
    double outerPen = ps('外功穿透') + 10;

    // Outer healing
    double outerAvg = (ps('最小外功攻击') + ps('最大外功攻击')) / 2;
    double outerBase = outerAvg * healRatio * (1 + outerPen / 200) * totalGlobalHeal;
    double outerCrit = outerBase * critHealMul;
    double outerNormal = outerBase;
    double outerHeal = outerCrit * critRate + outerNormal * (1 - critRate);
    outerHeal *= 1 + ps('外功治疗加成') / 100;

    // Element healing
    double eleAvg = (minQianSi + maxQianSi) / 2;
    double eleBase = eleAvg * eleHealRatio * (1 + qianSiPen / 200) * totalGlobalHeal;
    double eleCrit = eleBase * critHealMul;
    double eleNormal = eleBase;
    double eleHeal = eleCrit * critRate + eleNormal * (1 - critRate);
    eleHeal *= 1 + ps('属攻治疗加成') / 100;

    double totalK = (outerHeal + eleHeal) * (1 + ps('指定武学技能增伤') / 100);

    final rate = totalK / baseline * 100;
    return GraduationResult(graduationRate: rate, totalDamage: totalK.round());
  }

  // ============ Helper methods ============

  static Map<String, double> buildPanelForGraduation(
    Map<String, Equipment?> equipped,
    String className,
    String bowType,
    List<String?> xinfaList,
    String? setBonus,
    bool earlySeasonBonus, {
    List<StatModEntry>? statModifier,
    bool skipDingyin = false,
    List<double>? loanDingyinValue,
  }) {
    final result = calculateTotal(
      equipped, className, bowType, xinfaList, setBonus, earlySeasonBonus, false,
      statModifier: statModifier,
      skipDingyin: skipDingyin,
      loanDingyinValue: loanDingyinValue,
    );
    final panel = Map<String, double>.from(result.stats);

    // fixedDmgBonus from season stats into panel for graduation rate
    panel['固伤加成'] = CommonData.seasonStats['固伤加成'] ?? 0.15;

    return panel;
  }

  static GraduationResult calcRate(
    Map<String, Equipment?> equipped,
    String className,
    String bowType,
    List<String?> xinfaList,
    String? setBonus,
    bool earlySeasonBonus,
  ) {
    final panel = buildPanelForGraduation(equipped, className, bowType, xinfaList, setBonus, earlySeasonBonus);
    return calculateGraduationRate(panelStats: panel, className: className, xinfaList: xinfaList, setName: setBonus ?? '');
  }

  static Equipment mockChengyin(Equipment equip) {
    StatEntry? newMain;
    if (equip.mainStat.type != '生存类词条' && equip.mainStat.type != '生存向') {
      final maxVal = CommonData.maxValues[equip.mainStat.type];
      if (maxVal != null) {
        newMain = StatEntry(type: equip.mainStat.type, value: double.parse((0.94 * maxVal).toStringAsFixed(1)), isPercent: equip.mainStat.isPercent);
      }
    }
    final newSubs = equip.subStats.map((sub) {
      if (sub.type != '生存类词条' && sub.type != '生存向') {
        final maxVal = CommonData.maxValues[sub.type];
        if (maxVal != null) {
          return StatEntry(type: sub.type, value: double.parse((0.94 * maxVal).toStringAsFixed(1)), isPercent: sub.isPercent);
        }
      }
      return sub;
    }).toList();
    return Equipment(id: equip.id, slotId: equip.slotId, weaponTypeId: equip.weaponTypeId, name: equip.name, isChengyin: true, isPurple: equip.isPurple, isConvertible: equip.isConvertible, mainStat: newMain ?? equip.mainStat, subStats: newSubs, dingyinStat: equip.dingyinStat);
  }
}

class _CombatStats {
  final double minOuter, maxOuter, outerPen;
  final double minPoZhu, maxPoZhu, poZhuPen;
  final double minMingJin, maxMingJin, mingJinPen;
  final double minLieShi, maxLieShi, lieShiPen;
  final double minQianSi, maxQianSi, qianSiPen;
  final double minWuXiang, maxWuXiang, wuXiangPen;
  final double outerDmgBonus;
  final double poZhuDmgBonus, mingJinDmgBonus, lieShiDmgBonus, qianSiDmgBonus;
  final double critRate, intentRate, precision;
  final double directCrit, directIntent;
  final double critDmgBonus, intentDmgBonus;
  final double bossDmgBonus, playerDmgBonus;
  final double allArtsDmgBonus, singleMagicBonus, groupMagicBonus;
  final double specificSkillBonus, fixedDmgBonus;

  const _CombatStats({
    this.minOuter = 0, this.maxOuter = 0, this.outerPen = 0,
    this.minPoZhu = 0, this.maxPoZhu = 0, this.poZhuPen = 0,
    this.minMingJin = 0, this.maxMingJin = 0, this.mingJinPen = 0,
    this.minLieShi = 0, this.maxLieShi = 0, this.lieShiPen = 0,
    this.minQianSi = 0, this.maxQianSi = 0, this.qianSiPen = 0,
    this.minWuXiang = 0, this.maxWuXiang = 0, this.wuXiangPen = 0,
    this.outerDmgBonus = 0,
    this.poZhuDmgBonus = 0, this.mingJinDmgBonus = 0, this.lieShiDmgBonus = 0, this.qianSiDmgBonus = 0,
    this.critRate = 0, this.intentRate = 0, this.precision = 0,
    this.directCrit = 0, this.directIntent = 0,
    this.critDmgBonus = 0, this.intentDmgBonus = 0,
    this.bossDmgBonus = 0, this.playerDmgBonus = 0,
    this.allArtsDmgBonus = 0, this.singleMagicBonus = 0, this.groupMagicBonus = 0,
    this.specificSkillBonus = 0, this.fixedDmgBonus = 0,
  });
}
