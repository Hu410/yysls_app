import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../theme/app_colors.dart';
import '../../data/common_data.dart';
import '../../data/class_config.dart';
import '../../models/equipment.dart';
import '../../services/ocr_service.dart';
import '../../services/ocr_parser.dart';
import '../../services/color_analyzer.dart';
import '../../viewmodels/equipment_viewmodel.dart';

class EquipmentFormPage extends ConsumerStatefulWidget {
  final Equipment? equipment;
  const EquipmentFormPage({super.key, this.equipment});

  @override
  ConsumerState<EquipmentFormPage> createState() => _EquipmentFormPageState();
}

class _EquipmentFormPageState extends ConsumerState<EquipmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  late String? _slotId;
  late String? _weaponTypeId;
  late String _name;
  late bool _isChengyin;
  late bool _isPurple;
  late bool _isConvertible;
  late String? _mainStatType;
  late double _mainStatValue;
  final List<_SubStatEntry> _subStats = [];
  late String? _dingyinType;
  late double _dingyinValue;

  bool _isOcrLoading = false;
  String? _lastOcrLog;
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _nameController;

  bool get _isEditing => widget.equipment != null;

  List<String> get _availableSubStats {
    final opts = CommonData.getAvailableSubStats(_slotId, _weaponTypeId);
    for (final s in _subStats) {
      if (s.type != null && !opts.contains(s.type)) {
        opts.add(s.type!);
      }
    }
    return opts;
  }

  List<String> get _mainStatOptions {
    final rules = ClassConfig.mainStatRules[_slotId ?? ''];
    final opts = (rules ?? ['最大外功攻击', '最小外功攻击', '生存类词条']).toList();
    if (_mainStatType != null && !opts.contains(_mainStatType)) {
      opts.insert(0, _mainStatType!);
    }
    return opts;
  }

  List<String> get _dingyinOptions {
    final rules = CommonData.dingyinRules[_slotId ?? ''];
    if (rules == null) return ['外功穿透', '属攻穿透', '指定武学技能增伤'];
    final opts = rules.where((s) => s != '无').toSet().toList();
    if (_dingyinType != null && !opts.contains(_dingyinType)) {
      opts.add(_dingyinType!);
    }
    return opts;
  }

  @override
  void initState() {
    super.initState();
    final e = widget.equipment;
    _slotId = e?.slotId;
    _weaponTypeId = e?.weaponTypeId;
    _name = e?.name ?? '';
    _isChengyin = e?.isChengyin ?? false;
    _isPurple = e?.isPurple ?? false;
    _isConvertible = e?.isConvertible ?? false;
    _mainStatType = e?.mainStat.type;
    _mainStatValue = e?.mainStat.value ?? 0;
    _dingyinType = e?.dingyinStat?.type;
    _dingyinValue = e?.dingyinStat?.value ?? 0;

    _nameController = TextEditingController(text: _name);

    if (e != null) {
      for (final s in e.subStats) {
        _subStats.add(_SubStatEntry(type: s.type, value: s.value));
      }
    }
    while (_subStats.length < 4) {
      _subStats.add(_SubStatEntry());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑装备' : '录入装备'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: _isOcrLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt_rounded),
              tooltip: '拍照识别词条',
              onPressed: _isOcrLoading ? null : _ocrFillValues,
            ),
          if (_lastOcrLog != null)
            IconButton(
              icon: const Icon(Icons.article_outlined, size: 20),
              tooltip: '查看OCR原始数据',
              onPressed: _showOcrLog,
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_rounded, color: AppColors.danger),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _buildBasicInfo(),
            const SizedBox(height: 14),
            _buildFlags(),
            const SizedBox(height: 14),
            _buildMainStat(),
            const SizedBox(height: 14),
            _buildSubStats(),
            const SizedBox(height: 14),
            _buildDingyinStat(),
            const SizedBox(height: 28),
            _buildSubmitButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    Color? iconColor,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = iconColor ?? cs.primary;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return _buildSection(
      title: '基本信息',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _slotId,
                  decoration: const InputDecoration(labelText: '装备位置'),
                  items: CommonData.slots
                      .map((s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _slotId = v;
                    if (v != '1') _weaponTypeId = null;
                  }),
                  validator: (v) => v == null ? '请选择位置' : null,
                ),
              ),
              if (_slotId == '1') ...[
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _weaponTypeId,
                    decoration: const InputDecoration(labelText: '武器种类'),
                    items: CommonData.weaponTypes
                        .map((w) =>
                            DropdownMenuItem(value: w.id, child: Text(w.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _weaponTypeId = v),
                    validator: (v) =>
                        _slotId == '1' && v == null ? '请选择种类' : null,
                  ),
                ),
              ],
              if (_slotId != null)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  tooltip: '清除槽位',
                  onPressed: () => setState(() {
                    _slotId = null;
                    _weaponTypeId = null;
                    _mainStatType = null;
                    _mainStatValue = 0;
                    for (final s in _subStats) {
                      s.type = null;
                      s.value = 0;
                    }
                    _dingyinType = null;
                    _dingyinValue = 0;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '装备名称（选填）',
              hintText: '留空则自动生成',
            ),
            onChanged: (v) => _name = v,
          ),
        ],
      ),
    );
  }

  Widget _buildFlags() {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withAlpha(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('承音'),
              selected: _isChengyin,
              onSelected: (v) => setState(() => _isChengyin = v),
            ),
            FilterChip(
              label: const Text('紫装'),
              selected: _isPurple,
              onSelected: (v) => setState(() => _isPurple = v),
              selectedColor: AppColors.purpleDim,
            ),
            FilterChip(
              label: const Text('可转律'),
              selected: _isConvertible,
              onSelected: (v) => setState(() => _isConvertible = v),
              selectedColor: AppColors.orangeDim,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStat() {
    return _buildSection(
      title: '主词条',
      icon: Icons.star_rounded,
      iconColor: AppColors.gold,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: _mainStatType,
              decoration: const InputDecoration(labelText: '词条类型'),
              items: _mainStatOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _mainStatType = v),
              isExpanded: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('main_$_mainStatValue'),
              initialValue:
                  _mainStatValue > 0 ? _mainStatValue.toString() : '',
              decoration: const InputDecoration(labelText: '数值'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _mainStatValue = double.tryParse(v) ?? 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStats() {
    return _buildSection(
      title: '副词条',
      icon: Icons.layers_rounded,
      child: Column(
        children: List.generate(_subStats.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: _subStats[i].type,
                    decoration:
                        InputDecoration(labelText: '副词条 ${i + 1}'),
                    items: _availableSubStats
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _subStats[i].type = v),
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: ValueKey('sub${i}_${_subStats[i].value}'),
                    initialValue: _subStats[i].value > 0
                        ? _subStats[i].value.toString()
                        : '',
                    decoration: const InputDecoration(labelText: '数值'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) =>
                        _subStats[i].value = double.tryParse(v) ?? 0,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDingyinStat() {
    final cs = Theme.of(context).colorScheme;
    return _buildSection(
      title: '定音词条',
      icon: Icons.music_note_rounded,
      iconColor: cs.tertiary,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: _dingyinType,
              decoration: const InputDecoration(labelText: '词条类型'),
              items: _dingyinOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _dingyinType = v),
              isExpanded: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextFormField(
              key: ValueKey('dy_$_dingyinValue'),
              initialValue:
                  _dingyinValue > 0 ? _dingyinValue.toString() : '',
              decoration: const InputDecoration(labelText: '数值'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => _dingyinValue = double.tryParse(v) ?? 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: _submit,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: Text(_isEditing ? '保存修改' : '保存装备'),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_mainStatType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择主词条类型')),
      );
      return;
    }

    final subStats = _subStats
        .where((s) => s.type != null && s.value > 0)
        .map((s) => StatEntry(
              type: s.type!,
              value: s.value,
              isPercent: CommonData.isPercentStat(s.type!),
            ))
        .toList();

    var finalName = _nameController.text.trim();
    if (finalName.isEmpty) {
      final slotName = CommonData.getSlotById(_slotId!)?.name ?? '装备';
      finalName = '$slotName·${_mainStatType ?? "未知"}';
    }

    final equipment = Equipment(
      id: widget.equipment?.id ?? '',
      slotId: _slotId!,
      weaponTypeId: _slotId == '1' ? _weaponTypeId : null,
      name: finalName,
      isChengyin: _isChengyin,
      isPurple: _isPurple,
      isConvertible: _isConvertible,
      mainStat: StatEntry(
        type: _mainStatType!,
        value: _mainStatValue,
        isPercent: CommonData.isPercentStat(_mainStatType!),
      ),
      subStats: subStats,
      dingyinStat: _dingyinType != null && _dingyinValue > 0
          ? StatEntry(
              type: _dingyinType!,
              value: _dingyinValue,
              isPercent: CommonData.isPercentStat(_dingyinType!),
            )
          : null,
    );

    if (_isEditing) {
      ref.read(equipmentProvider.notifier).updateEquipment(equipment);
    } else {
      ref.read(equipmentProvider.notifier).addEquipment(equipment);
    }
    Navigator.pop(context);
  }

  Future<void> _ocrFillValues() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1a2332),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'OCR 截图示例',
                style: TextStyle(
                  color: Color(0xFFd4a748),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '请参考下图，截取或裁剪装备面板的完整区域\n（包含装备名、槽位、所有词条）',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/ocr_guide.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: const Text('取消', style: TextStyle(color: Colors.white54)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFd4a748),
                        foregroundColor: const Color(0xFF1a2332),
                      ),
                      child: const Text('开始识别'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (proceed != true) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final xFile = await _imagePicker.pickImage(
      source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 90,
    );
    if (xFile == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: xFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪词条区域',
          toolbarColor: const Color(0xFF1a2332),
          toolbarWidgetColor: const Color(0xFFd4a748),
          initAspectRatio: CropAspectRatioPreset.ratio4x3,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio3x2,
          ],
        ),
        IOSUiSettings(
          title: '裁剪词条区域',
          minimumAspectRatio: 0.3,
          resetAspectRatioEnabled: true,
          aspectRatioLockEnabled: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio3x2,
          ],
        ),
      ],
    );
    if (cropped == null) return;

    setState(() => _isOcrLoading = true);
    final log = StringBuffer();
    void _log(String msg) {
      log.writeln(msg);
      debugPrint(msg);
    }

    _log('[OCR] 原图: ${xFile.path}');
    _log('[OCR] 裁剪: ${cropped.path}');

    try {
      // Color analysis on the ORIGINAL image (contains full equipment header)
      final originalFile = File(xFile.path);
      final quality = await ColorAnalyzer.analyzeEquipQuality(originalFile);
      _log('[颜色] 品质判定: $quality');

      final ocrService = ref.read(ocrServiceProvider);
      final result = await ocrService.recognizeFromFile(File(cropped.path));

      _log('── 原始文本 (${result.fullText.length}字) ──');
      _log(result.fullText);
      _log('── 原始文本结束 ──');

      if (result.fullText.trim().isEmpty) {
        _log('识别结果为空');
        // Still apply color result even if text is empty
        if (quality == EquipQuality.purple) {
          setState(() { _isPurple = true; _isOcrLoading = false; _lastOcrLog = log.toString(); });
          _log('自动设置紫装: true (仅颜色)');
        } else {
          setState(() { _isOcrLoading = false; _lastOcrLog = log.toString(); });
        }
        return;
      }

      final fullResult = OcrParser.parseFull(result.fullText);
      final meta = fullResult.metadata;
      final ocrResults = fullResult.stats;

      _log('── 元数据 ──');
      _log('装备名: ${meta.equipName ?? "无"}');
      _log('槽位: ${meta.slotName ?? "无"}');
      _log('承音: ${meta.isChengyin}');
      _log('品质颜色: ${quality.name}');
      _log('解析结果: ${ocrResults.length} 条');
      for (var i = 0; i < ocrResults.length; i++) {
        final r = ocrResults[i];
        _log('  [$i] "${r.name}" = ${r.value ?? "无"} 定音=${r.isDingyin}');
      }

      // Auto-fill metadata in a single setState to avoid intermediate rebuilds
      setState(() {
        if (meta.slotName != null) {
          final slotId = OcrParser.getSlotIdFromName(meta.slotName);
          if (slotId != null && _slotId == null) {
            _log('自动设置槽位: ${meta.slotName} -> $slotId');
            _slotId = slotId;
          }
        }
        if (meta.weaponTypeId != null && _weaponTypeId == null && _slotId == '1') {
          final wtName = CommonData.getWeaponTypeById(meta.weaponTypeId!)?.name;
          _log('自动设置武器种类: $wtName (id=${meta.weaponTypeId})');
          _weaponTypeId = meta.weaponTypeId;
        }
        if (meta.isChengyin && !_isChengyin) {
          _log('自动设置承音: true');
          _isChengyin = true;
        }
        if (quality == EquipQuality.purple && !_isPurple) {
          _log('自动设置紫装: true');
          _isPurple = true;
        }
        if (meta.equipName != null && _name.isEmpty) {
          _log('自动设置名称: ${meta.equipName}');
          _name = meta.equipName!;
          _nameController.text = _name;
        }
      });

      if (ocrResults.isEmpty) {
        _log('无有效词条，走纯数值兜底');
        final skipWords = [
          '造诣', '造谐', '造诸', '装备等阶', '品级', '评分',
          '气血最大值', '气血最大', '气血',
          '外功防御', '内功防御', '防御', '阶',
        ];
        final numLines = <double>[];
        for (final rawLine in result.fullText.split('\n')) {
          final trimmed = rawLine.trim();
          if (trimmed.isEmpty) continue;
          final noSpace = trimmed.replaceAll(RegExp(r'\s+'), '');
          if (skipWords.any((kw) => noSpace.contains(kw))) {
            _log('兜底跳过: $trimmed');
            continue;
          }
          if (RegExp(r'^\d{4,}$').hasMatch(noSpace)) {
            _log('兜底跳过纯大数: $trimmed');
            continue;
          }
          final cleaned = rawLine.replaceAll(RegExp(r'[%％\s]'), '');
          final m = RegExp(r'^[\D]{0,5}(\d+\.?\d*)$').firstMatch(cleaned);
          if (m != null) {
            final v = double.tryParse(m.group(1)!);
            if (v != null && v > 0) numLines.add(v);
          }
        }
        _log('提取数值: $numLines');

        if (numLines.isEmpty) {
          _log('无数值可填');
          setState(() { _isOcrLoading = false; _lastOcrLog = log.toString(); });
          return;
        }

        setState(() {
          int idx = 0;
          if (idx < numLines.length) _mainStatValue = numLines[idx++];
          for (var i = 0; i < _subStats.length && idx < numLines.length; i++) {
            _subStats[i].value = numLines[idx++];
          }
          if (idx < numLines.length) _dingyinValue = numLines[idx];
          _isOcrLoading = false;
        });

        _log('── 兜底填入 ──');
        _log('主=$_mainStatValue');
        for (var i = 0; i < _subStats.length; i++) {
          _log('副${i + 1}=${_subStats[i].value}');
        }
        _log('定音=$_dingyinValue');
        setState(() { _lastOcrLog = log.toString(); });
        return;
      }

      // If slot was not set by OCR text, try to infer from recognized stats
      if (_slotId == null) {
        final inferredSlot = _inferSlotFromOcrStats(ocrResults);
        if (inferredSlot != null) {
          _log('从词条反推槽位: $inferredSlot');
          setState(() => _slotId = inferredSlot);
        }
      }

      final mainOptions = _mainStatOptions;
      final subOptions = _availableSubStats;
      final dyOptions = _dingyinOptions;

      _log('当前槽位: $_slotId');
      _log('可选主词条: $mainOptions');
      _log('可选副词条: $subOptions');
      _log('可选定音: $dyOptions');

      final normalResults = <OcrStatResult>[];
      final dingyinResults = <OcrStatResult>[];
      for (final r in ocrResults) {
        if (r.isDingyin) {
          dingyinResults.add(r);
        } else {
          normalResults.add(r);
        }
      }
      _log('普通=${normalResults.length} 定音=${dingyinResults.length}');

      // Separate main stat from sub stats by checking against mainOptions
      OcrStatResult? mainResult;
      final subResults = <OcrStatResult>[];
      for (final r in normalResults) {
        if (mainResult == null && mainOptions.contains(r.name)) {
          mainResult = r;
        } else {
          subResults.add(r);
        }
      }
      // If no exact main match, try fuzzy match on mainOptions
      if (mainResult == null) {
        for (var i = 0; i < normalResults.length; i++) {
          final matched = OcrParser.matchToAvailable(normalResults[i].name, mainOptions);
          if (matched != null) {
            mainResult = normalResults[i];
            subResults.remove(normalResults[i]);
            break;
          }
        }
      }
      _log('主词条候选: ${mainResult?.name ?? "无"}  副词条数: ${subResults.length}');

      int filledNames = 0;
      int filledValues = 0;

      setState(() {
        if (mainResult != null) {
          var matched = OcrParser.matchToAvailable(mainResult!.name, mainOptions);
          matched ??= _tryDirectStatName(mainResult!.name);
          _log('主: "${mainResult!.name}" -> ${matched ?? "未匹配"} val=${mainResult!.value}');
          if (matched != null) { _mainStatType = matched; filledNames++; }
          if (mainResult!.value != null) { _mainStatValue = double.tryParse(mainResult!.value!) ?? 0; filledValues++; }
        }

        for (var i = 0; i < _subStats.length && i < subResults.length; i++) {
          final sub = subResults[i];
          var matched = OcrParser.matchToAvailable(sub.name, subOptions);
          matched ??= _tryDirectStatName(sub.name);
          _log('副${i + 1}: "${sub.name}" -> ${matched ?? "未匹配"} val=${sub.value}');
          if (matched != null) { _subStats[i].type = matched; filledNames++; }
          if (sub.value != null) { _subStats[i].value = double.tryParse(sub.value!) ?? 0; filledValues++; }
        }

        if (dingyinResults.isNotEmpty) {
          final dy = dingyinResults.first;
          var matched = OcrParser.matchToAvailable(dy.name, dyOptions);
          matched ??= _tryDirectStatName(dy.name);
          _log('定音: "${dy.name}" -> ${matched ?? "未匹配"} val=${dy.value}');
          if (matched != null) { _dingyinType = matched; filledNames++; }
          if (dy.value != null) { _dingyinValue = double.tryParse(dy.value!) ?? 0; filledValues++; }
        }
        _isOcrLoading = false;
      });

      _log('── 填入结果 ──');
      _log('词条名: $filledNames  数值: $filledValues');
      _log('主: type=$_mainStatType val=$_mainStatValue');
      for (var i = 0; i < _subStats.length; i++) {
        _log('副${i + 1}: type=${_subStats[i].type} val=${_subStats[i].value}');
      }
      _log('定音: type=$_dingyinType val=$_dingyinValue');

      setState(() { _lastOcrLog = log.toString(); });
    } catch (e, stack) {
      _log('异常: $e\n$stack');
      setState(() { _isOcrLoading = false; _lastOcrLog = log.toString(); });
    }
  }

  void _showOcrLog() {
    if (_lastOcrLog == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('OCR 原始数据', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              _lastOcrLog!,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.5),
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// Infer slot ID from OCR-recognized stat types.
  String? _inferSlotFromOcrStats(List<OcrStatResult> stats) {
    final names = stats.map((s) => s.name).toSet();
    if (names.contains('对首领单位增伤') || names.contains('对玩家单位增效')) {
      return '8'; // slot 7 or 8
    }
    if (names.contains('单体类奇术增伤') || names.contains('群体类奇术增伤')) {
      return '5'; // slot 5 or 6
    }
    if (names.contains('全武学增效')) {
      return '3'; // slot 3 or 4
    }
    if (names.contains('最大无相攻击') || names.contains('最小无相攻击')) {
      return '1';
    }
    for (final n in names) {
      if (n.endsWith('武学增效') && !n.startsWith('全')) return '1';
    }
    return null;
  }

  /// If OCR returned a valid stat name (exists in CommonData.maxValues or known stats),
  /// use it directly even if not in the current slot's dropdown options.
  String? _tryDirectStatName(String name) {
    if (CommonData.maxValues.containsKey(name)) return name;
    if (CommonData.percentStats.contains(name)) return name;
    if (CommonData.baseSubStats.contains(name)) return name;
    if (name == '生存类词条') return name;
    return null;
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除装备',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('确定要删除「${widget.equipment!.name}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(equipmentProvider.notifier)
                  .deleteEquipment(widget.equipment!.id);
              Navigator.pop(context);
            },
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _SubStatEntry {
  String? type;
  double value;
  _SubStatEntry({this.type, this.value = 0});
}
