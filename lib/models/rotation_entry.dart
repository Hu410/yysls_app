class RotationEntry {
  final String name;
  final double count;
  final bool isDingyin;
  final double generalBonus;
  final bool included;
  final double yishui;
  final String? chunlei;
  final bool? yongquan;
  final double? tiaozhan;

  const RotationEntry({
    required this.name,
    this.count = 1,
    this.isDingyin = false,
    this.generalBonus = 0,
    this.included = false,
    this.yishui = 10,
    this.chunlei,
    this.yongquan,
    this.tiaozhan,
  });

  factory RotationEntry.fromJson(Map<String, dynamic> json) {
    return RotationEntry(
      name: json['name'] as String? ?? '',
      count: (json['count'] as num?)?.toDouble() ?? 1,
      isDingyin: json['isDingyin'] as bool? ?? false,
      generalBonus: (json['generalBonus'] as num?)?.toDouble() ?? 0,
      included: json['included'] as bool? ?? false,
      yishui: (json['yishui'] as num?)?.toDouble() ?? 10,
      chunlei: json['chunlei'] as String?,
      yongquan: json['yongquan'] as bool?,
      tiaozhan: (json['tiaozhan'] as num?)?.toDouble(),
    );
  }
}

class RotationConfig {
  final List<RotationEntry> rotation;
  final double baseline;
  final double baseline2;
  final double useTime;
  final String version;
  final String author;
  final String updateTime;
  final String skillDatabaseKey;

  const RotationConfig({
    required this.rotation,
    this.baseline = 1,
    this.baseline2 = 0,
    this.useTime = 0,
    this.version = '',
    this.author = '',
    this.updateTime = '',
    this.skillDatabaseKey = '',
  });
}
