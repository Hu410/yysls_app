class StatEntry {
  final String type;
  final double value;
  final bool isPercent;

  const StatEntry({
    required this.type,
    required this.value,
    this.isPercent = false,
  });

  StatEntry copyWith({String? type, double? value, bool? isPercent}) {
    return StatEntry(
      type: type ?? this.type,
      value: value ?? this.value,
      isPercent: isPercent ?? this.isPercent,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'value': value,
        'isPercent': isPercent,
      };

  factory StatEntry.fromJson(Map<String, dynamic> json) => StatEntry(
        type: json['type'] as String,
        value: (json['value'] as num).toDouble(),
        isPercent: json['isPercent'] as bool? ?? false,
      );
}

class Equipment {
  final String id;
  final String slotId;
  final String? weaponTypeId;
  final String name;
  final bool isChengyin;
  final bool isPurple;
  final bool isConvertible;
  final List<String>? availableClasses;
  final StatEntry mainStat;
  final List<StatEntry> subStats;
  final StatEntry? dingyinStat;

  const Equipment({
    required this.id,
    required this.slotId,
    this.weaponTypeId,
    required this.name,
    this.isChengyin = false,
    this.isPurple = false,
    this.isConvertible = false,
    this.availableClasses,
    required this.mainStat,
    this.subStats = const [],
    this.dingyinStat,
  });

  Equipment copyWith({
    String? id,
    String? slotId,
    String? weaponTypeId,
    String? name,
    bool? isChengyin,
    bool? isPurple,
    bool? isConvertible,
    List<String>? availableClasses,
    StatEntry? mainStat,
    List<StatEntry>? subStats,
    StatEntry? dingyinStat,
  }) {
    return Equipment(
      id: id ?? this.id,
      slotId: slotId ?? this.slotId,
      weaponTypeId: weaponTypeId ?? this.weaponTypeId,
      name: name ?? this.name,
      isChengyin: isChengyin ?? this.isChengyin,
      isPurple: isPurple ?? this.isPurple,
      isConvertible: isConvertible ?? this.isConvertible,
      availableClasses: availableClasses ?? this.availableClasses,
      mainStat: mainStat ?? this.mainStat,
      subStats: subStats ?? this.subStats,
      dingyinStat: dingyinStat ?? this.dingyinStat,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slotId': slotId,
        'weaponTypeId': weaponTypeId,
        'name': name,
        'isChengyin': isChengyin,
        'isPurple': isPurple,
        'isConvertible': isConvertible,
        'availableClasses': availableClasses,
        'mainStat': mainStat.toJson(),
        'subStats': subStats.map((s) => s.toJson()).toList(),
        'dingyinStat': dingyinStat?.toJson(),
      };

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
        id: json['id'] as String,
        slotId: json['slotId'] as String,
        weaponTypeId: json['weaponTypeId'] as String?,
        name: json['name'] as String,
        isChengyin: json['isChengyin'] as bool? ?? false,
        isPurple: json['isPurple'] as bool? ?? false,
        isConvertible: json['isConvertible'] as bool? ?? false,
        availableClasses: (json['availableClasses'] as List<dynamic>?)
            ?.cast<String>(),
        mainStat: StatEntry.fromJson(json['mainStat'] as Map<String, dynamic>),
        subStats: (json['subStats'] as List<dynamic>?)
                ?.map((s) => StatEntry.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        dingyinStat: json['dingyinStat'] != null
            ? StatEntry.fromJson(json['dingyinStat'] as Map<String, dynamic>)
            : null,
      );
}
