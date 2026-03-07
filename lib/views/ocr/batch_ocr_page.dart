import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../data/common_data.dart';
import '../../models/equipment.dart';
import '../../services/ocr_service.dart';
import '../../services/ocr_parser.dart';
import '../../viewmodels/equipment_viewmodel.dart';

class _BatchItem {
  final File file;
  String? slotId;
  String? weaponTypeId;
  Equipment? parsedEquipment;
  String status = 'pending';
  String? errorMsg;

  _BatchItem({required this.file});
}

class BatchOcrPage extends ConsumerStatefulWidget {
  const BatchOcrPage({super.key});

  @override
  ConsumerState<BatchOcrPage> createState() => _BatchOcrPageState();
}

class _BatchOcrPageState extends ConsumerState<BatchOcrPage> {
  final ImagePicker _picker = ImagePicker();
  final List<_BatchItem> _items = [];
  bool _isProcessing = false;
  int _processedCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('批量OCR导入'),
        actions: [
          if (_items.isNotEmpty && !_isProcessing)
            TextButton.icon(
              onPressed: _startBatchRecognition,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('开始识别'),
            ),
        ],
      ),
      body: _items.isEmpty ? _buildEmpty() : _buildItemList(),
      floatingActionButton: !_isProcessing
          ? FloatingActionButton.extended(
              onPressed: _addImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('添加截图'),
            )
          : null,
    );
  }

  Widget _buildEmpty() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: cs.onSurfaceVariant.withAlpha(80)),
          const SizedBox(height: 24),
          Text('批量导入装备截图', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              '从相册选择多张装备截图，一次识别全部。\n每张截图对应一件装备。',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _addImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('选择截图'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (_isProcessing)
          LinearProgressIndicator(
            value: _items.isNotEmpty ? _processedCount / _items.length : null,
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text('共 ${_items.length} 张', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              if (_isProcessing) ...[
                const SizedBox(width: 8),
                Text('已处理 $_processedCount/${_items.length}',
                    style: TextStyle(color: cs.primary, fontSize: 13)),
              ],
              const Spacer(),
              if (!_isProcessing && _items.any((i) => i.parsedEquipment != null))
                TextButton.icon(
                  onPressed: _saveAll,
                  icon: const Icon(Icons.save_alt, size: 18),
                  label: Text('保存全部 (${_items.where((i) => i.parsedEquipment != null).length})'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
            itemCount: _items.length,
            itemBuilder: (ctx, i) => _buildItemCard(i),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(int index) {
    final cs = Theme.of(context).colorScheme;
    final item = _items[index];
    final statusIcon = switch (item.status) {
      'pending' => Icon(Icons.hourglass_empty, size: 18, color: cs.onSurfaceVariant),
      'processing' => SizedBox(
          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary)),
      'done' => Icon(Icons.check_circle, size: 18, color: cs.primary),
      'error' => const Icon(Icons.error, size: 18, color: AppColors.danger),
      _ => const SizedBox.shrink(),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(item.file, width: 60, height: 60, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: item.slotId,
                          decoration: const InputDecoration(isDense: true, labelText: '位置',
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                          items: CommonData.slots.map((s) => DropdownMenuItem(
                              value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: _isProcessing ? null : (v) => setState(() => item.slotId = v),
                          isExpanded: true,
                        ),
                      ),
                      if (item.slotId == '1') ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: item.weaponTypeId,
                            decoration: const InputDecoration(isDense: true, labelText: '武器',
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                            items: CommonData.weaponTypes.map((w) => DropdownMenuItem(
                                value: w.id, child: Text(w.name, style: const TextStyle(fontSize: 13)))).toList(),
                            onChanged: _isProcessing ? null : (v) => setState(() => item.weaponTypeId = v),
                            isExpanded: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.parsedEquipment != null) ...[
                    const SizedBox(height: 6),
                    _buildMiniStatPreview(item.parsedEquipment!),
                  ],
                  if (item.errorMsg != null) ...[
                    const SizedBox(height: 4),
                    Text(item.errorMsg!, style: const TextStyle(color: AppColors.danger, fontSize: 11)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                statusIcon,
                if (!_isProcessing) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() => _items.removeAt(index)),
                    child: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatPreview(Equipment equip) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6, runSpacing: 2,
      children: [
        _miniTag('主:${equip.mainStat.type} ${equip.mainStat.value.toStringAsFixed(1)}', AppColors.gold),
        ...equip.subStats.map((s) => _miniTag('${s.type} ${s.value.toStringAsFixed(1)}', cs.onSurfaceVariant)),
        if (equip.dingyinStat != null)
          _miniTag('定:${equip.dingyinStat!.type} ${equip.dingyinStat!.value.toStringAsFixed(1)}', cs.tertiary),
      ],
    );
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10)),
    );
  }

  Future<void> _addImages() async {
    final xFiles = await _picker.pickMultiImage(maxWidth: 1920, maxHeight: 1920, imageQuality: 90);
    if (xFiles.isEmpty) return;
    setState(() {
      for (final xf in xFiles) {
        _items.add(_BatchItem(file: File(xf.path)));
      }
    });
  }

  Future<void> _startBatchRecognition() async {
    final incomplete = _items.where((i) => i.slotId == null).toList();
    if (incomplete.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('还有 ${incomplete.length} 张截图未选择装备位置')),
      );
      return;
    }

    final weaponMissing = _items.where((i) => i.slotId == '1' && i.weaponTypeId == null).toList();
    if (weaponMissing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('武器截图需要选择武器种类')),
      );
      return;
    }

    setState(() { _isProcessing = true; _processedCount = 0; });

    final ocrService = ref.read(ocrServiceProvider);
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      setState(() => item.status = 'processing');

      try {
        final result = await ocrService.recognizeFromFile(item.file);
        final parsed = OcrParser.parseText(result.fullText);
        if (parsed.isEmpty) {
          setState(() { item.status = 'error'; item.errorMsg = '未能识别到词条'; });
        } else {
          final equip = OcrParser.buildEquipmentFromOcr(
            parsed,
            slotId: item.slotId!,
            weaponTypeId: item.weaponTypeId,
            name: 'OCR-${CommonData.getSlotById(item.slotId!)?.name ?? ""}',
          );
          setState(() {
            item.parsedEquipment = equip;
            item.status = equip != null ? 'done' : 'error';
            if (equip == null) item.errorMsg = '解析失败';
          });
        }
      } catch (e) {
        setState(() { item.status = 'error'; item.errorMsg = e.toString(); });
      }
      setState(() => _processedCount = i + 1);
    }

    setState(() => _isProcessing = false);
    if (mounted) {
      final doneCount = _items.where((i) => i.status == 'done').length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('识别完成：$doneCount/${_items.length} 成功')),
      );
    }
  }

  void _saveAll() {
    final successItems = _items.where((i) => i.parsedEquipment != null).toList();
    if (successItems.isEmpty) return;
    for (final item in successItems) {
      ref.read(equipmentProvider.notifier).addEquipment(item.parsedEquipment!);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已保存 ${successItems.length} 件装备')),
    );
    Navigator.pop(context);
  }
}
