class Scheme {
  final String id;
  final String name;
  final Map<String, String?> equippedItems;
  final List<String?> xinfa;
  final String bowType;
  final String? setBonus;
  final bool earlySeasonBonus;
  final bool pvpMode;
  final bool loanDingyin;

  const Scheme({
    required this.id,
    required this.name,
    this.equippedItems = const {},
    this.xinfa = const [null, null, null, null],
    this.bowType = 'precision',
    this.setBonus,
    this.earlySeasonBonus = false,
    this.pvpMode = false,
    this.loanDingyin = false,
  });

  static const List<String> slotKeys = [
    'weapon1', 'weapon2', 'head', 'chest',
    'ring', 'pendant', 'legs', 'hands',
  ];

  String? getEquipId(String slotKey) => equippedItems[slotKey];

  Scheme copyWith({
    String? id,
    String? name,
    Map<String, String?>? equippedItems,
    List<String?>? xinfa,
    String? bowType,
    String? setBonus,
    bool? earlySeasonBonus,
    bool? pvpMode,
    bool? loanDingyin,
  }) {
    return Scheme(
      id: id ?? this.id,
      name: name ?? this.name,
      equippedItems: equippedItems ?? this.equippedItems,
      xinfa: xinfa ?? this.xinfa,
      bowType: bowType ?? this.bowType,
      setBonus: setBonus ?? this.setBonus,
      earlySeasonBonus: earlySeasonBonus ?? this.earlySeasonBonus,
      pvpMode: pvpMode ?? this.pvpMode,
      loanDingyin: loanDingyin ?? this.loanDingyin,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'equippedItems': equippedItems,
        'xinfa': xinfa,
        'bowType': bowType,
        'setBonus': setBonus,
        'earlySeasonBonus': earlySeasonBonus,
        'pvpMode': pvpMode,
        'loanDingyin': loanDingyin,
      };

  factory Scheme.fromJson(Map<String, dynamic> json) => Scheme(
        id: json['id'] as String,
        name: json['name'] as String,
        equippedItems:
            (json['equippedItems'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, v as String?),
                ) ??
                {},
        xinfa: (json['xinfa'] as List<dynamic>?)
                ?.map((e) => e as String?)
                .toList() ??
            [null, null, null, null],
        bowType: json['bowType'] as String? ?? 'precision',
        setBonus: json['setBonus'] as String?,
        earlySeasonBonus: json['earlySeasonBonus'] as bool? ?? false,
        pvpMode: json['pvpMode'] as bool? ?? false,
        loanDingyin: json['loanDingyin'] as bool? ?? false,
      );
}
