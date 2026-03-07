class Skill {
  final Map<String, dynamic> modifiers;
  final double outerRatio;
  final double fixed;
  final double eleRatio;
  final double exMinATK;
  final double exMaxATK;
  final double exATK;
  final double exCrit;
  final double exCritDmg;
  final double exIntent;
  final double exIntentDmg;
  final double exDmg;
  final double exPen;
  final int isCharge;
  final String type;
  final String weaponType;
  final String element;
  final String special;
  final String force;

  const Skill({
    this.modifiers = const {},
    this.outerRatio = 0,
    this.fixed = 0,
    this.eleRatio = 0,
    this.exMinATK = 0,
    this.exMaxATK = 0,
    this.exATK = 0,
    this.exCrit = 0,
    this.exCritDmg = 0,
    this.exIntent = 0,
    this.exIntentDmg = 0,
    this.exDmg = 0,
    this.exPen = 0,
    this.isCharge = 0,
    this.type = '',
    this.weaponType = '',
    this.element = '',
    this.special = '无',
    this.force = '无',
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      modifiers: (json['modifiers'] as Map<String, dynamic>?) ?? {},
      outerRatio: (json['outerRatio'] as num?)?.toDouble() ?? 0,
      fixed: (json['fixed'] as num?)?.toDouble() ?? 0,
      eleRatio: (json['eleRatio'] as num?)?.toDouble() ?? 0,
      exMinATK: (json['exMinATK'] as num?)?.toDouble() ?? 0,
      exMaxATK: (json['exMaxATK'] as num?)?.toDouble() ?? 0,
      exATK: (json['exATK'] as num?)?.toDouble() ?? 0,
      exCrit: (json['exCrit'] as num?)?.toDouble() ?? 0,
      exCritDmg: (json['exCritDmg'] as num?)?.toDouble() ?? 0,
      exIntent: (json['exIntent'] as num?)?.toDouble() ?? 0,
      exIntentDmg: (json['exIntentDmg'] as num?)?.toDouble() ?? 0,
      exDmg: (json['exDmg'] as num?)?.toDouble() ?? 0,
      exPen: (json['exPen'] as num?)?.toDouble() ?? 0,
      isCharge: (json['isCharge'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      weaponType: json['weaponType'] as String? ?? '',
      element: json['element'] as String? ?? '',
      special: json['special'] as String? ?? '无',
      force: json['force'] as String? ?? '无',
    );
  }
}
