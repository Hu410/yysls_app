import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../theme/app_colors.dart';
import '../../data/common_data.dart';
import '../../data/class_config.dart';
import '../../services/ocr_service.dart';
import '../../viewmodels/equipment_viewmodel.dart';
import '../../models/equipment.dart';

class OcrScanPage extends ConsumerStatefulWidget {
  final String? presetSlotId;
  final String? presetWeaponTypeId;

  const OcrScanPage({
    super.key,
    this.presetSlotId,
    this.presetWeaponTypeId,
  });

  @override
  ConsumerState<OcrScanPage> createState() => _OcrScanPageState();
}

class _OcrScanPageState extends ConsumerState<OcrScanPage> {
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isRecognizing = false;
  String _statusText = '拍照或选择装备截图，自动提取数值';

  String? _slotId;
  String? _weaponTypeId;
  String _equipName = '';

  final List<_StatRow> _rows = [];
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _slotId = widget.presetSlotId;
    _weaponTypeId = widget.presetWeaponTypeId;
    _initRows();
  }

  void _initRows() {
    _rows.clear();
    _rows.addAll([
      _StatRow(label: '主词条', isMain: true),
      _StatRow(label: '副词条1'),
      _StatRow(label: '副词条2'),
      _StatRow(label: '副词条3'),
      _StatRow(label: '副词条4'),
      _StatRow(label: '定音', isDingyin: true),
    ]);
  }

  List<String> _getStatOptions(int index) {
    final slot = _slotId ?? '1';
    if (index == 0) {
      return ClassConfig.mainStatRules[slot] ?? CommonData.baseSubStats;
    }
    if (index == 5) {
      final validDy = CommonData.dingyinRules[slot] ?? [];
      return validDy.where((s) => s != '无').toList();
    }
    return CommonData.getAvailableSubStats(slot, _weaponTypeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR识别装备'),
        actions: [
          if (_rows.any((r) => r.type != null && r.value.isNotEmpty))
            TextButton.icon(
              onPressed: _saveEquipment,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('保存'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSlotSelector(),
            const SizedBox(height: 12),
            _buildImageSection(),
            const SizedBox(height: 12),
            _buildStatEditor(),
            if (_rows.any((r) => r.type != null && r.value.isNotEmpty)) ...[
              const SizedBox(height: 16),
              _buildSaveButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlotSelector() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
            Text('装备信息', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _slotId,
                    decoration: const InputDecoration(labelText: '位置', isDense: true),
                    items: CommonData.slots.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (v) => setState(() {
                      _slotId = v;
                      if (v != '1') _weaponTypeId = null;
                    }),
                  ),
                ),
                if (_slotId == '1') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _weaponTypeId,
                      decoration: const InputDecoration(labelText: '武器种类', isDense: true),
                      items: CommonData.weaponTypes.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                      onChanged: (v) => setState(() => _weaponTypeId = v),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: _equipName,
              decoration: const InputDecoration(labelText: '装备名称（可选）', hintText: '留空使用默认名称', isDense: true),
              onChanged: (v) => _equipName = v,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final cs = Theme.of(context).colorScheme;
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
          children: [
            if (_imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_imageFile!, fit: BoxFit.contain, height: 200),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isRecognizing ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('拍照'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isRecognizing ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('相册'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_isRecognizing)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),
            Text(_statusText, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatEditor() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
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
                Icon(
                  _hasScanned ? Icons.auto_fix_high : Icons.edit_note,
                  color: _hasScanned ? cs.primary : cs.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _hasScanned ? '数值已自动填入，请选择词条名' : '词条编辑',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (_hasScanned)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  '数值已从截图自动识别，请为每一行选择对应的词条名称',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 8),
            ...List.generate(_rows.length, (i) => _buildRowWidget(i)),
          ],
        ),
      ),
    );
  }

  Widget _buildRowWidget(int index) {
    final cs = Theme.of(context).colorScheme;
    final row = _rows[index];
    final options = _getStatOptions(index);
    final valueCtrl = TextEditingController(text: row.value);
    valueCtrl.selection = TextSelection.fromPosition(TextPosition(offset: row.value.length));

    final labelColor = row.isMain ? AppColors.gold : (row.isDingyin ? AppColors.purple : cs.onSurface);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(row.label, style: TextStyle(color: labelColor, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: (row.type != null && options.contains(row.type)) ? row.type : null,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                hintText: '选择词条',
                hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              items: options.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => row.type = v),
              isExpanded: true,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextField(
              controller: valueCtrl,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                hintText: '数值',
                hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: labelColor, fontWeight: FontWeight.w600, fontSize: 14),
              onChanged: (v) => row.value = v,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    final canSave = _slotId != null && (_slotId != '1' || _weaponTypeId != null);
    return FilledButton.icon(
      onPressed: canSave ? _saveEquipment : null,
      icon: const Icon(Icons.save),
      label: const Text('保存到装备库'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _picker.pickImage(source: source, maxWidth: 1920, maxHeight: 1920, imageQuality: 90);
    if (xFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: xFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '裁剪装备词条区域',
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: '裁剪装备词条区域', minimumAspectRatio: 0.3),
      ],
    );
    if (croppedFile == null) return;

    setState(() {
      _imageFile = File(croppedFile.path);
      _isRecognizing = true;
      _statusText = '正在识别数值...';
    });

    try {
      final ocrService = ref.read(ocrServiceProvider);
      final result = await ocrService.recognizeFromFile(_imageFile!);
      final numbers = RegExp(r'(\d+\.?\d*)').allMatches(result.fullText).map((m) => m.group(0)!).toList();

      setState(() {
        _isRecognizing = false;
        _hasScanned = true;
        if (numbers.isEmpty) {
          _statusText = '未能识别到数值，请手动输入';
        } else {
          _statusText = '识别到 ${numbers.length} 个数值，已自动填入';
          for (var i = 0; i < _rows.length && i < numbers.length; i++) {
            _rows[i].value = numbers[i];
          }
        }
      });
    } catch (e) {
      setState(() {
        _isRecognizing = false;
        _statusText = '识别出错: $e';
      });
    }
  }

  void _saveEquipment() {
    if (_slotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先选择装备位置')));
      return;
    }
    if (_slotId == '1' && _weaponTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先选择武器种类')));
      return;
    }

    final mainRow = _rows[0];
    if (mainRow.type == null || mainRow.value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写主词条')));
      return;
    }
    final mainStat = StatEntry(
      type: mainRow.type!,
      value: double.tryParse(mainRow.value) ?? 0,
      isPercent: CommonData.isPercentStat(mainRow.type!),
    );

    final subStats = <StatEntry>[];
    for (var i = 1; i <= 4; i++) {
      final row = _rows[i];
      if (row.type != null && row.value.isNotEmpty) {
        subStats.add(StatEntry(
          type: row.type!,
          value: double.tryParse(row.value) ?? 0,
          isPercent: CommonData.isPercentStat(row.type!),
        ));
      }
    }

    StatEntry? dingyinStat;
    final dyRow = _rows[5];
    if (dyRow.type != null && dyRow.value.isNotEmpty) {
      final validDingyin = CommonData.dingyinRules[_slotId!];
      if (validDingyin != null && validDingyin.contains(dyRow.type)) {
        dingyinStat = StatEntry(
          type: dyRow.type!,
          value: double.tryParse(dyRow.value) ?? 0,
          isPercent: CommonData.isPercentStat(dyRow.type!),
        );
      }
    }

    final name = _equipName.trim().isEmpty ? 'OCR装备' : _equipName.trim();
    final equipment = Equipment(
      id: '',
      slotId: _slotId!,
      weaponTypeId: _slotId == '1' ? _weaponTypeId : null,
      name: name,
      mainStat: mainStat,
      subStats: subStats,
      dingyinStat: dingyinStat,
    );

    ref.read(equipmentProvider.notifier).addEquipment(equipment);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('装备「$name」已保存')),
    );
    Navigator.pop(context);
  }
}

class _StatRow {
  final String label;
  final bool isMain;
  final bool isDingyin;
  String? type;
  String value;

  _StatRow({required this.label, this.isMain = false, this.isDingyin = false, this.type, this.value = ''});
}
