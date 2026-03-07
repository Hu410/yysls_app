class ClassConfig {
  ClassConfig._();

  static const List<String> classes = [
    '鸣金虹', '鸣金影', '破竹尘', '破竹风', '破竹鸢',
    '裂石威', '裂石钧', '裂石钧（纯唐）', '牵丝霖', '牵丝玉',
  ];

  /// weaponRules[className] = [主武器TypeId, 副武器TypeId]
  static const Map<String, List<String>> weaponRules = {
    '鸣金虹': ['1', '2'],
    '鸣金影': ['1', '2'],
    '破竹尘': ['3', '5'],
    '破竹风': ['6', '5'],
    '破竹鸢': ['9', '5'],
    '裂石威': ['7', '2'],
    '裂石钧': ['8', '7'],
    '裂石钧（纯唐）': ['8', '7'],
    '牵丝霖': ['3', '4'],
    '牵丝玉': ['3', '4'],
  };

  static List<String>? getWeaponRule(String className) =>
      weaponRules[className];

  static bool isHealingClass(String className, List<String?> xinfaList) {
    return className == '牵丝霖' &&
        !xinfaList.any((x) => x == '怒斩马');
  }

  static const Map<String, String> specificSkillBonusNames = {
    '鸣金影': '积矩九剑·流血增伤',
    '鸣金虹': '无名剑法·蓄力技增伤',
    '破竹尘': '醉梦游春·武学技增伤',
    '破竹风': '栗子游尘·鼠鼠增伤',
    '裂石钧（纯唐）': '斩雪刀法·轻重击派生技增伤',
    '裂石钧': '十方破阵·蓄力技增伤',
    '牵丝玉': '九重春色·特殊技增伤',
    '裂石威': '嗟夫刀法·蓄力技增伤',
    '破竹鸢': '天志垂象·蓄力技增伤',
    '牵丝霖': '明川药典·治疗技增疗',
  };

  static const Map<String, List<String>> weaponBonusNames = {
    '鸣金虹': ['剑武学增效', '枪武学增效'],
    '鸣金影': ['剑武学增效', '枪武学增效'],
    '破竹尘': ['伞武学增效', '绳标武学增效'],
    '破竹风': ['双刀武学增效', '绳标武学增效'],
    '破竹鸢': ['拳甲武学增效', '绳标武学增效'],
    '裂石威': ['陌刀武学增效', '枪武学增效'],
    '裂石钧': ['横刀武学增效', '陌刀武学增效'],
    '裂石钧（纯唐）': ['横刀武学增效', '陌刀武学增效'],
    '牵丝霖': ['伞武学增效', '扇武学增效'],
    '牵丝玉': ['伞武学增效', '扇武学增效'],
  };

  /// 各槽位可选的主词条（与JS MAIN_STAT_RULES 对齐）
  static const Map<String, List<String>> mainStatRules = {
    '1': ['最大外功攻击', '最小外功攻击', '最小无相攻击', '最大无相攻击', '劲', '敏', '势', '生存类词条'],
    '3': ['最大外功攻击', '最小外功攻击', '生存类词条'],
    '4': ['最大外功攻击', '最小外功攻击', '生存类词条'],
    '5': ['精准率', '会心率', '会意率', '生存类词条'],
    '6': ['精准率', '会心率', '会意率', '生存类词条'],
    '7': ['精准率', '会心率', '会意率', '劲', '生存类词条'],
    '8': ['精准率', '会心率', '会意率', '劲', '生存类词条'],
  };

  static const Map<String, String> defaultSets = {
    '鸣金虹': '玉斗',
    '鸣金影': '飞隼',
    '破竹风': '飞隼',
    '牵丝玉': '飞隼',
    '牵丝霖': '时雨',
    '裂石威': '时雨',
    '裂石钧': '时雨',
    '裂石钧（纯唐）': '断岳',
    '破竹尘': '连星',
    '破竹鸢': '撼天',
  };

  static const Map<String, Map<String, List<String>>> xinfaRules = {
    '鸣金影': {
      'default': ['易水歌', '剑气纵横', '逐狼心经', '凝神章'],
      'extra': ['移经易武', '断石之构'],
    },
    '鸣金虹': {
      'default': ['易水歌', '无名心法', '威猛歌', '千山法'],
      'extra': ['断石之构'],
    },
    '裂石威': {
      'default': ['易水歌', '山河绝韵', '穿喉决', '移经易武'],
      'extra': ['断石之构', '抗造大法', '威猛歌'],
    },
    '裂石钧（纯唐）': {
      'default': ['易水歌', '霜天白夜', '穿喉决', '征人归'],
      'extra': ['断石之构'],
    },
    '裂石钧': {
      'default': ['易水歌', '霜天白夜', '孤忠不辞', '穿喉决'],
      'extra': ['断石之构'],
    },
    '破竹风': {
      'default': ['忘川绝响', '心弥泥鱼', '极乐泣血', '易水歌'],
      'extra': ['断石之构'],
    },
    '破竹尘': {
      'default': ['易水歌', '千营一呼', '绳舟行木', '所恨年年'],
      'extra': ['大唐歌', '断石之构', '灯儿亮'],
    },
    '破竹鸢': {
      'default': ['易水歌', '扶摇直上', '擒天势', '断石之构'],
      'extra': ['三穷致知'],
    },
    '牵丝霖': {
      'default': ['易水歌', '君臣药', '怒斩马', '征人归'],
      'extra': ['断石之构', '杏花不见', '千丝蛊'],
    },
    '牵丝玉': {
      'default': ['易水歌', '花上月令', '纵地摘星', '断石之构'],
      'extra': ['春雷篇'],
    },
  };

  /// armory element by class prefix
  static String getArmoryForClass(String className) {
    if (className.startsWith('鸣金')) return '鸣金';
    if (className.startsWith('裂石')) return '裂石';
    if (className.startsWith('牵丝')) return '牵丝';
    if (className.startsWith('破竹')) return '破竹';
    return '通用';
  }
}
