import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/equipment.dart';
import '../services/storage_service.dart';
import 'account_viewmodel.dart';

class EquipmentState {
  final List<Equipment> equipments;
  final String? filterSlotId;
  final bool isLoading;

  const EquipmentState({
    this.equipments = const [],
    this.filterSlotId,
    this.isLoading = false,
  });

  List<Equipment> get filteredEquipments {
    if (filterSlotId == null) return equipments;
    return equipments.where((e) => e.slotId == filterSlotId).toList();
  }

  EquipmentState copyWith({
    List<Equipment>? equipments,
    String? filterSlotId,
    bool? isLoading,
    bool clearFilter = false,
  }) {
    return EquipmentState(
      equipments: equipments ?? this.equipments,
      filterSlotId: clearFilter ? null : (filterSlotId ?? this.filterSlotId),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class EquipmentViewModel extends StateNotifier<EquipmentState> {
  final StorageService _storage;
  String? _currentAccountId;

  EquipmentViewModel(this._storage) : super(const EquipmentState());

  Future<void> loadForAccount(String? accountId) async {
    _currentAccountId = accountId;
    if (accountId == null) {
      state = const EquipmentState();
      return;
    }
    state = state.copyWith(isLoading: true);
    final equipments = await _storage.getEquipments(accountId);
    state = state.copyWith(equipments: equipments, isLoading: false);
  }

  void setFilter(String? slotId) {
    if (slotId == state.filterSlotId) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterSlotId: slotId);
    }
  }

  Future<void> addEquipment(Equipment equip) async {
    if (_currentAccountId == null) return;
    final newEquip = equip.copyWith(id: const Uuid().v4());
    final updated = [...state.equipments, newEquip];
    await _storage.saveEquipments(_currentAccountId!, updated);
    state = state.copyWith(equipments: updated);
  }

  Future<void> updateEquipment(Equipment equip) async {
    if (_currentAccountId == null) return;
    final updated = state.equipments.map((e) {
      return e.id == equip.id ? equip : e;
    }).toList();
    await _storage.saveEquipments(_currentAccountId!, updated);
    state = state.copyWith(equipments: updated);
  }

  Future<void> deleteEquipment(String id) async {
    if (_currentAccountId == null) return;
    final updated = state.equipments.where((e) => e.id != id).toList();
    await _storage.saveEquipments(_currentAccountId!, updated);
    state = state.copyWith(equipments: updated);
  }

  Equipment? getById(String id) {
    try {
      return state.equipments.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

final equipmentProvider =
    StateNotifierProvider<EquipmentViewModel, EquipmentState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return EquipmentViewModel(storage);
});
