import '../data/common_data.dart';
import '../models/equipment.dart';

class OcrStatResult {
  final String name;
  final String? value;
  final bool isDingyin;

  const OcrStatResult({required this.name, this.value, this.isDingyin = false});
}

/// Metadata extracted from the top portion of the equipment screenshot.
class OcrMetadata {
  final String? equipName;
  final String? slotName;
  final String? weaponTypeId;
  final bool isChengyin;
  final bool isPurple;

  const OcrMetadata({
    this.equipName,
    this.slotName,
    this.weaponTypeId,
    this.isChengyin = false,
    this.isPurple = false,
  });
}

/// Full OCR parse result including metadata + stats.
class OcrFullResult {
  final OcrMetadata metadata;
  final List<OcrStatResult> stats;

  const OcrFullResult({required this.metadata, required this.stats});
}

class OcrParser {
  OcrParser._();

  static const Map<String, String> _knownStats = {
    '劲': '劲',
    '敏': '敏',
    '势': '势',
    '最大外功攻击': '最大外功攻击',
    '最小外功攻击': '最小外功攻击',
    '最大鸣金攻击': '最大鸣金攻击',
    '最小鸣金攻击': '最小鸣金攻击',
    '最大裂石攻击': '最大裂石攻击',
    '最小裂石攻击': '最小裂石攻击',
    '最大牵丝攻击': '最大牵丝攻击',
    '最小牵丝攻击': '最小牵丝攻击',
    '最大破竹攻击': '最大破竹攻击',
    '最小破竹攻击': '最小破竹攻击',
    '最大无相攻击': '最大无相攻击',
    '最小无相攻击': '最小无相攻击',
    '精准率': '精准率',
    '会心率': '会心率',
    '会意率': '会意率',
    '外功穿透': '外功穿透',
    '属攻穿透': '属攻穿透',
    '无相穿透': '属攻穿透',
    '全武学增效': '全武学增效',
    '对首领单位增伤': '对首领单位增伤',
    '对玩家单位增效': '对玩家单位增效',
    '指定武学技能增伤': '指定武学技能增伤',
    '单体类奇术增伤': '单体类奇术增伤',
    '群体类奇术增伤': '群体类奇术增伤',
    '剑武学增效': '剑武学增效',
    '枪武学增效': '枪武学增效',
    '伞武学增效': '伞武学增效',
    '扇武学增效': '扇武学增效',
    '绳标武学增效': '绳标武学增效',
    '双刀武学增效': '双刀武学增效',
    '陌刀武学增效': '陌刀武学增效',
    '横刀武学增效': '横刀武学增效',
    '拳甲武学增效': '拳甲武学增效',
  };

  static const List<String> _ocrGarbage = [
    '莽', '荐', '满', '蓄', '蒙', '!', '！', 'E', 'e',
  ];

  /// Lines to skip entirely (equipment header / irrelevant base stats / UI noise)
  static const List<String> _skipKeywords = [
    '造诣', '造谐', '造诸',
    '装备等阶', '品级', '评分',
    '气血最大值', '气血最大', '气血',
    '外功防御', '内功防御', '防御',
    '外功攻击',
  ];

  /// Slot name mapping from OCR text
  static const Map<String, String> _slotNameToId = {
    '武器': '1',
    '环': '3',
    '佩': '4',
    '冠胄': '5',
    '冠': '5',
    '胸甲': '6',
    '胫甲': '7',
    '腕甲': '8',
  };

  static const List<String> _dingyinSkillNames = [
    '栗子游尘', '鼠鼠增伤',
    '积矩九剑', '流血增伤',
    '无名剑法', '蓄力技增伤',
    '醉梦游春', '武学技增伤',
    '斩雪刀法', '轻重击派生技增伤',
    '十方破阵',
    '九重春色', '特殊技增伤',
    '嗟夫刀法',
    '天志垂象',
    '明川药典', '治疗技增疗',
  ];

  /// Full parse: extracts metadata (name, slot, chengyin) + stat entries.
  static OcrFullResult parseFull(String rawText) {
    final lines = rawText.split('\n');

    String? equipName;
    String? slotName;
    bool isChengyin = false;

    final statResults = <OcrStatResult>[];
    final nameOnlyResults = <_Pending>[];
    final orphanValues = <String>[];

    // Bullet/prefix characters that mark affix stat lines
    final affixPrefixPattern = RegExp(r'^[\s]*[•·◆◇❖※▪▫●○♦⬥☆★+,，\|｜\[\(]');

    for (final rawLine in lines) {
      var line = rawLine.trim();
      if (line.isEmpty) continue;

      // Detect affix marker (bullet point or +/, prefix at start)
      final hasAffixMarker = affixPrefixPattern.hasMatch(rawLine);

      // Detect 承音 marker
      if (line.contains('承音') || line.contains('承首')) {
        isChengyin = true;
      }

      // Detect slot name with fuzzy matching for OCR errors
      // Also strip common OCR prefixes before slot detection
      var cleanForSlot = line.replaceAll(RegExp(r'\s+'), '');
      cleanForSlot = cleanForSlot.replaceAll(RegExp(r'^[|｜\[\]·•\-]+'), '');
      if (cleanForSlot.length <= 6 && cleanForSlot.isNotEmpty) {
        final matched = _fuzzyMatchSlot(cleanForSlot);
        if (matched != null) slotName = matched;
      }

      // Skip non-stat lines, but NEVER skip lines with affix markers
      if (_shouldSkipLine(line, hasAffixMarker: hasAffixMarker)) continue;

      // Clean up the line: remove prefixes, bullets, garbage
      var cleaned = line.replaceAll(RegExp(r'\s+'), '');
      cleaned = cleaned.replaceAll(RegExp(r'\[转\d*\]?'), '');
      cleaned = cleaned.replaceAll(RegExp(r'[\[回\]]+'), '');
      cleaned = cleaned.replaceAll(RegExp(r'^[+,，\|｜]+'), '');
      // OCR corrections
      cleaned = cleaned.replaceAll('玫击', '攻击');
      cleaned = cleaned.replaceAll('政击', '攻击');
      cleaned = cleaned.replaceAll('領', '领');
      cleaned = cleaned.replaceAll('太', '大');
      cleaned = cleaned.replaceAll('式学', '武学');
      cleaned = cleaned.replaceAll('绳镖', '绳标');
      cleaned = cleaned.replaceAll('绳鏢', '绳标');
      cleaned = cleaned.replaceAll(RegExp(r'[•·◆◇❖※▪▫●○♦⬥☆★\-–]'), '');
      for (final g in _ocrGarbage) {
        cleaned = cleaned.replaceAll(g, '');
      }
      cleaned = cleaned.replaceAll(RegExp(r'\*+'), '');
      cleaned = cleaned.replaceAll(RegExp(r'[E]$'), '');
      // Remove leading noise characters (e.g. "令" before "外功穿透")
      cleaned = cleaned.replaceAll(RegExp(r'^[令个]+'), '');
      if (cleaned.isEmpty) continue;

      // Try to extract stat name + value
      final numMatch = RegExp(r'(\d+\.?\d*)%?').firstMatch(cleaned);
      final rawValue = numMatch?.group(0);
      final value = rawValue?.replaceAll('%', '');
      final textPart = numMatch != null
          ? cleaned.substring(0, numMatch.start) + cleaned.substring(numMatch.end)
          : cleaned;

      String? statName = _tryExactMatch(textPart);
      statName ??= _tryFuzzyMatch(textPart);

      bool isDingyin = false;
      if (statName == null) {
        statName = _tryDingyinMatch(textPart);
        if (statName != null) isDingyin = true;
      } else if (_isDingyinStat(statName, textPart)) {
        isDingyin = true;
      }

      if (statName != null && value != null) {
        statResults.add(OcrStatResult(name: statName, value: value, isDingyin: isDingyin));
      } else if (statName != null) {
        nameOnlyResults.add(_Pending(name: statName, isDingyin: isDingyin));
      } else if (value != null && textPart.replaceAll(RegExp(r'[^a-zA-Z\u4e00-\u9fff]'), '').isEmpty) {
        orphanValues.add(value);
      } else if (statResults.isEmpty && nameOnlyResults.isEmpty &&
          equipName == null && textPart.length >= 2) {
        final chineseOnly = textPart.replaceAll(RegExp(r'[^\u4e00-\u9fff]'), '');
        if (chineseOnly.length >= 2 && !_isKnownSlotName(chineseOnly)) {
          equipName = chineseOnly;
        }
      }
    }

    // Pair up: names without values + orphan values
    // Only keep decimal values (54.0, 85.2, 3.6) as valid stat values;
    // pure integers are almost always header noise (6192, 23, 2)
    if (nameOnlyResults.isNotEmpty && orphanValues.isNotEmpty) {
      final validValues = orphanValues.where((v) => v.contains('.')).toList();

      final normalPending = <_Pending>[];
      final dingyinPending = <_Pending>[];
      for (final p in nameOnlyResults) {
        (p.isDingyin ? dingyinPending : normalPending).add(p);
      }

      // Separate values into "likely percent" (<=15.2) and "likely flat" (>15.2)
      // based on maxValues: percent stats max at 15.2, flat stats start at ~48
      final percentValues = <String>[];
      final flatValues = <String>[];
      for (final v in validValues) {
        final num = double.tryParse(v);
        if (num != null && num <= 15.2) {
          percentValues.add(v);
        } else {
          flatValues.add(v);
        }
      }

      // For each normal pending stat, pick the best matching value
      final usedFlat = <int>{};
      final usedPct = <int>{};
      for (final p in normalPending) {
        final isPercent = _isPercentLikeStat(p.name);
        String? bestVal;
        if (isPercent && percentValues.isNotEmpty) {
          for (var i = 0; i < percentValues.length; i++) {
            if (!usedPct.contains(i)) {
              bestVal = percentValues[i];
              usedPct.add(i);
              break;
            }
          }
        }
        if (bestVal == null && !isPercent && flatValues.isNotEmpty) {
          for (var i = 0; i < flatValues.length; i++) {
            if (!usedFlat.contains(i)) {
              bestVal = flatValues[i];
              usedFlat.add(i);
              break;
            }
          }
        }
        // Fallback: take any remaining value
        if (bestVal == null) {
          for (var i = 0; i < flatValues.length; i++) {
            if (!usedFlat.contains(i)) { bestVal = flatValues[i]; usedFlat.add(i); break; }
          }
        }
        if (bestVal == null) {
          for (var i = 0; i < percentValues.length; i++) {
            if (!usedPct.contains(i)) { bestVal = percentValues[i]; usedPct.add(i); break; }
          }
        }
        statResults.add(OcrStatResult(name: p.name, value: bestVal, isDingyin: false));
      }

      // Dingyin stats: always percent-like, pick from remaining percent values first
      for (final p in dingyinPending) {
        String? bestVal;
        for (var i = 0; i < percentValues.length; i++) {
          if (!usedPct.contains(i)) { bestVal = percentValues[i]; usedPct.add(i); break; }
        }
        if (bestVal == null) {
          for (var i = 0; i < flatValues.length; i++) {
            if (!usedFlat.contains(i)) { bestVal = flatValues[i]; usedFlat.add(i); break; }
          }
        }
        statResults.add(OcrStatResult(name: p.name, value: bestVal, isDingyin: true));
      }
    } else {
      for (final p in nameOnlyResults) {
        statResults.add(OcrStatResult(name: p.name, isDingyin: p.isDingyin));
      }
    }

    // If slot was not detected from text, try to infer from recognized stats
    if (slotName == null) {
      slotName = _inferSlotFromStats(statResults, nameOnlyResults);
    }

    // If slot is weapon, try to infer weapon type from stats
    final weaponTypeId = (slotName == '武器' || _slotNameToId[slotName] == '1')
        ? _inferWeaponTypeFromStats(statResults, nameOnlyResults)
        : null;

    return OcrFullResult(
      metadata: OcrMetadata(
        equipName: equipName,
        slotName: slotName,
        weaponTypeId: weaponTypeId,
        isChengyin: isChengyin,
      ),
      stats: statResults,
    );
  }

  /// Infer slot name from recognized stat types when OCR fails to detect slot text.
  static String? _inferSlotFromStats(
    List<OcrStatResult> stats,
    List<_Pending> pending,
  ) {
    final allNames = [
      ...stats.map((s) => s.name),
      ...pending.map((p) => p.name),
    ];

    bool has(String name) => allNames.contains(name);

    // Slot 7/8: 对首领单位增伤 / 对玩家单位增效
    if (has('对首领单位增伤') || has('对玩家单位增效')) return '腕甲';
    // Slot 5/6: 单体类奇术增伤 / 群体类奇术增伤
    if (has('单体类奇术增伤') || has('群体类奇术增伤')) return '冠胄';
    // Slot 3/4: 全武学增效
    if (has('全武学增效')) return '环';
    // Slot 1: weapon-specific stats (无相攻击 or weapon type bonus)
    if (has('最大无相攻击') || has('最小无相攻击')) return '武器';
    for (final n in allNames) {
      if (n.endsWith('武学增效') && !n.startsWith('全')) return '武器';
    }
    return null;
  }

  /// Infer weapon type from recognized stats (e.g. 剑武学增效 -> 剑).
  static String? _inferWeaponTypeFromStats(
    List<OcrStatResult> stats,
    List<_Pending> pending,
  ) {
    final allNames = [
      ...stats.map((s) => s.name),
      ...pending.map((p) => p.name),
    ];
    for (final wt in CommonData.weaponTypes) {
      if (allNames.contains(wt.statName)) return wt.id;
    }
    return null;
  }

  /// Legacy method: returns just stat results.
  static List<OcrStatResult> parseText(String rawText) {
    return parseFull(rawText).stats;
  }

  static bool _shouldSkipLine(String line, {bool hasAffixMarker = false}) {
    // Strip leading | (OCR noise from screenshot borders) before checking
    var stripped = line.replaceAll(RegExp(r'\s+'), '');
    stripped = stripped.replaceAll(RegExp(r'^[|｜]+'), '');
    // Apply common OCR corrections before matching
    stripped = stripped.replaceAll('太', '大');
    stripped = stripped.replaceAll('玫击', '攻击');
    stripped = stripped.replaceAll('政击', '攻击');
    // Skip single-character lines (UI noise like "飞" set icon, "锁" lock icon)
    if (stripped.length <= 1) return true;
    // Skip lines that are pure numbers (造诣 score like 1101, defense 23)
    if (RegExp(r'^\d{2,}$').hasMatch(stripped)) return true;
    // Skip "N阶" pattern (e.g. "100阶", "承音·100阶")
    if (RegExp(r'\d+阶').hasMatch(stripped)) return true;
    // Skip weapon base damage range (e.g. "75-175", "75~175")
    if (RegExp(r'^\d+[\-~～]\d+$').hasMatch(stripped)) return true;
    // Skip slot info lines (e.g. "武器·绳镖")
    if (stripped.contains('武器') && stripped.contains('·')) return true;
    // Keyword filter: always check, but for lines with real affix markers
    // (♦◆+, etc. but NOT |) only skip definite header keywords
    final isRealAffix = RegExp(r'^[\s]*[•·◆◇❖※▪▫●○♦⬥☆★+,，\[\(]').hasMatch(line);
    for (final kw in _skipKeywords) {
      if (stripped.contains(kw)) {
        // "外功攻击" alone is weapon base stat; skip unless it has "最大/最小"
        if (kw == '外功攻击' && (stripped.contains('最大') || stripped.contains('最小'))) continue;
        // Don't skip "外功防御" if it's part of "外功攻击" (already handled by OCR correction)
        if ((kw == '外功防御' || kw == '内功防御') && stripped.contains('攻击')) continue;
        // Real affix lines with definite bullet markers: only skip造诣/装备等阶 (never appear as stats)
        if (isRealAffix && kw != '造诣' && kw != '造谐' && kw != '造诸' && kw != '装备等阶' && kw != '品级' && kw != '评分') continue;
        return true;
      }
    }
    return false;
  }

  static bool _isKnownSlotName(String text) {
    return _slotNameToId.keys.any((k) => text == k) ||
        _fuzzyMatchSlot(text) != null;
  }

  static String? _fuzzyMatchSlot(String text) {
    for (final entry in _slotNameToId.entries) {
      if (text.contains(entry.key)) return entry.key;
    }
    // OCR error corrections for slot names
    if (text.contains('脆甲') || text.contains('腕') || text.contains('碗甲') || text.contains('皖甲')) {
      return '腕甲';
    }
    if (text.contains('胸') || text.contains('胷')) {
      return '胸甲';
    }
    if (text.contains('胫') || text.contains('径') || text.contains('經甲')) {
      return '胫甲';
    }
    if (text.contains('冠') || text.contains('冉') || text.contains('胃')) {
      return '冠胄';
    }
    return null;
  }

  static String? getSlotIdFromName(String? slotName) {
    if (slotName == null) return null;
    return _slotNameToId[slotName];
  }

  static String? matchToAvailable(String ocrName, List<String> available) {
    if (available.contains(ocrName)) return ocrName;
    for (final opt in available) {
      if (opt == ocrName) return opt;
    }
    for (final opt in available) {
      if (opt.contains(ocrName) || ocrName.contains(opt)) return opt;
    }
    return null;
  }

  static bool _isDingyinStat(String statName, String textPart) {
    if (statName == '外功穿透' || statName == '属攻穿透') return true;
    if (statName == '指定武学技能增伤') return true;
    for (final kw in _dingyinSkillNames) {
      if (textPart.contains(kw)) return true;
    }
    return false;
  }

  static String? _tryExactMatch(String text) {
    String? best;
    int bestLen = 0;
    for (final entry in _knownStats.entries) {
      if (text.contains(entry.key) && entry.key.length > bestLen) {
        best = entry.value;
        bestLen = entry.key.length;
      }
    }
    return best;
  }

  static String? _tryFuzzyMatch(String text) {
    if (_matchAny(text, ['劲', '纪', '劝', '动', '缚', '纱', '荡', '妃', '弹'])) {
      if (!text.contains('外') && !text.contains('攻') && !text.contains('穿') && !text.contains('防')) {
        return '劲';
      }
    }
    if (_matchAny(text, ['敏', '考'])) return '敏';
    if (_matchAny(text, ['势', '执', '扫'])) return '势';

    if (text.contains('精') || text.contains('准')) return '精准率';
    if (text.contains('会') && (text.contains('心') || text.contains('计'))) return '会心率';
    if (text.contains('会') && text.contains('意')) return '会意率';

    if (text.contains('小') && (text.contains('外') || text.contains('功'))) return '最小外功攻击';
    if (text.contains('大') && (text.contains('外') || text.contains('功'))) return '最大外功攻击';

    if (text.contains('鸣') || text.contains('金')) {
      if (text.contains('小')) return '最小鸣金攻击';
      if (text.contains('大')) return '最大鸣金攻击';
    }
    if (text.contains('裂') || text.contains('石')) {
      if (text.contains('小')) return '最小裂石攻击';
      if (text.contains('大')) return '最大裂石攻击';
    }
    if (text.contains('牵') || text.contains('丝')) {
      if (text.contains('小')) return '最小牵丝攻击';
      if (text.contains('大')) return '最大牵丝攻击';
    }
    if (text.contains('破') || text.contains('竹')) {
      if (text.contains('小')) return '最小破竹攻击';
      if (text.contains('大')) return '最大破竹攻击';
    }
    if (text.contains('无') || text.contains('相')) {
      if (text.contains('小')) return '最小无相攻击';
      if (text.contains('大')) return '最大无相攻击';
    }

    if (text.contains('穿') && text.contains('外')) return '外功穿透';
    if (text.contains('穿')) return '属攻穿透';

    if (text.contains('首') && (text.contains('领') || text.contains('領'))) return '对首领单位增伤';
    if (text.contains('玩') && text.contains('家')) return '对玩家单位增效';

    if (text.contains('全') && text.contains('武')) return '全武学增效';

    if (text.contains('群') && text.contains('奇')) return '群体类奇术增伤';
    if (text.contains('单') && text.contains('奇')) return '单体类奇术增伤';

    if (text.contains('伞') && text.contains('增')) return '伞武学增效';
    if (text.contains('剑') && text.contains('增')) return '剑武学增效';
    if (text.contains('枪') && text.contains('增')) return '枪武学增效';
    if (text.contains('扇') && text.contains('增')) return '扇武学增效';
    if (text.contains('绳') || text.contains('镖')) return '绳标武学增效';
    if (text.contains('陌') && text.contains('刀')) return '陌刀武学增效';
    if (text.contains('双') && text.contains('刀')) return '双刀武学增效';
    if (text.contains('横') && text.contains('刀')) return '横刀武学增效';
    if (text.contains('拳') || (text.contains('甲') && text.contains('增'))) return '拳甲武学增效';

    if (text.contains('指定') && text.contains('增')) return '指定武学技能增伤';

    return null;
  }

  static String? _tryDingyinMatch(String text) {
    for (final name in _dingyinSkillNames) {
      if (text.contains(name)) return '指定武学技能增伤';
    }
    if (text.contains('增伤') || text.contains('增疗')) {
      return '指定武学技能增伤';
    }
    return null;
  }

  static bool _matchAny(String text, List<String> candidates) {
    return candidates.any((c) => text.contains(c));
  }

  /// Stats whose values are small percentages (typically <=15.2).
  /// Flat stats like 攻击/劲/敏/势 have values in 48~91 range.
  static bool _isPercentLikeStat(String name) {
    return CommonData.isPercentStat(name) ||
        name.contains('穿透') ||
        name.contains('增效') ||
        name.contains('增伤') ||
        name.contains('增疗');
  }

  static Equipment? buildEquipmentFromOcr(
    List<OcrStatResult> ocrResults, {
    required String slotId,
    String? weaponTypeId,
    String name = 'OCR识别装备',
  }) {
    if (ocrResults.isEmpty) return null;

    StatEntry? mainStat;
    final subStats = <StatEntry>[];
    StatEntry? dingyinStat;

    if (ocrResults.isNotEmpty) {
      final main = ocrResults[0];
      final val = double.tryParse(main.value ?? '') ?? 0;
      mainStat = StatEntry(
        type: main.name,
        value: val,
        isPercent: CommonData.isPercentStat(main.name),
      );
    }

    final subEnd = ocrResults.length >= 6
        ? ocrResults.length - 1
        : ocrResults.length;
    for (var i = 1; i < subEnd && i < 5; i++) {
      final sub = ocrResults[i];
      final val = double.tryParse(sub.value ?? '') ?? 0;
      subStats.add(StatEntry(
        type: sub.name,
        value: val,
        isPercent: CommonData.isPercentStat(sub.name),
      ));
    }

    if (ocrResults.length >= 6) {
      final dy = ocrResults.last;
      final val = double.tryParse(dy.value ?? '') ?? 0;
      final validDingyin = CommonData.dingyinRules[slotId];
      if (validDingyin != null && validDingyin.contains(dy.name)) {
        dingyinStat = StatEntry(
          type: dy.name,
          value: val,
          isPercent: CommonData.isPercentStat(dy.name),
        );
      }
    }

    if (mainStat == null) return null;

    return Equipment(
      id: '',
      slotId: slotId,
      weaponTypeId: slotId == '1' ? weaponTypeId : null,
      name: name,
      mainStat: mainStat,
      subStats: subStats,
      dingyinStat: dingyinStat,
    );
  }
}

class _Pending {
  final String name;
  final bool isDingyin;
  const _Pending({required this.name, required this.isDingyin});
}
