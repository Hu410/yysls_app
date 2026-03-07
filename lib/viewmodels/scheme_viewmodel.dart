import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/scheme.dart';
import '../services/storage_service.dart';
import 'account_viewmodel.dart';

class SchemeState {
  final List<Scheme> schemes;
  final String? currentSchemeId;
  final bool isLoading;

  const SchemeState({
    this.schemes = const [],
    this.currentSchemeId,
    this.isLoading = false,
  });

  Scheme? get currentScheme {
    if (currentSchemeId == null) return null;
    try {
      return schemes.firstWhere((s) => s.id == currentSchemeId);
    } catch (_) {
      return null;
    }
  }

  SchemeState copyWith({
    List<Scheme>? schemes,
    String? currentSchemeId,
    bool? isLoading,
    bool clearCurrent = false,
  }) {
    return SchemeState(
      schemes: schemes ?? this.schemes,
      currentSchemeId:
          clearCurrent ? null : (currentSchemeId ?? this.currentSchemeId),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SchemeViewModel extends StateNotifier<SchemeState> {
  final StorageService _storage;
  String? _currentAccountId;

  SchemeViewModel(this._storage) : super(const SchemeState());

  Future<void> loadForAccount(String? accountId) async {
    _currentAccountId = accountId;
    if (accountId == null) {
      state = const SchemeState();
      return;
    }
    state = state.copyWith(isLoading: true);
    final schemes = await _storage.getSchemes(accountId);
    if (schemes.isEmpty) {
      final defaultScheme = Scheme(
        id: const Uuid().v4(),
        name: '方案1',
      );
      final list = [defaultScheme];
      await _storage.saveSchemes(accountId, list);
      state = SchemeState(
        schemes: list,
        currentSchemeId: defaultScheme.id,
        isLoading: false,
      );
    } else {
      state = SchemeState(
        schemes: schemes,
        currentSchemeId: schemes.first.id,
        isLoading: false,
      );
    }
  }

  Future<void> selectScheme(String id) async {
    state = state.copyWith(currentSchemeId: id);
  }

  Future<void> createScheme(String name) async {
    if (_currentAccountId == null) return;
    final scheme = Scheme(id: const Uuid().v4(), name: name.trim());
    final updated = [...state.schemes, scheme];
    await _storage.saveSchemes(_currentAccountId!, updated);
    state = state.copyWith(schemes: updated, currentSchemeId: scheme.id);
  }

  Future<void> renameScheme(String id, String newName) async {
    if (_currentAccountId == null) return;
    final updated = state.schemes.map((s) {
      return s.id == id ? s.copyWith(name: newName.trim()) : s;
    }).toList();
    await _storage.saveSchemes(_currentAccountId!, updated);
    state = state.copyWith(schemes: updated);
  }

  Future<void> deleteScheme(String id) async {
    if (_currentAccountId == null) return;
    if (state.schemes.length <= 1) return;
    final updated = state.schemes.where((s) => s.id != id).toList();
    await _storage.saveSchemes(_currentAccountId!, updated);
    final newCurrent =
        state.currentSchemeId == id ? updated.first.id : state.currentSchemeId;
    state = state.copyWith(schemes: updated, currentSchemeId: newCurrent);
  }

  Future<void> updateScheme(Scheme scheme) async {
    if (_currentAccountId == null) return;
    final updated = state.schemes.map((s) {
      return s.id == scheme.id ? scheme : s;
    }).toList();
    await _storage.saveSchemes(_currentAccountId!, updated);
    state = state.copyWith(schemes: updated);
  }

  Future<void> equipItem(String slotKey, String? equipId) async {
    final current = state.currentScheme;
    if (current == null) return;
    final items = Map<String, String?>.from(current.equippedItems);
    items[slotKey] = equipId;
    await updateScheme(current.copyWith(equippedItems: items));
  }

  Future<void> unequipItem(String slotKey) async {
    await equipItem(slotKey, null);
  }

  Future<void> setXinfa(int index, String? xinfaName) async {
    final current = state.currentScheme;
    if (current == null) return;
    final xinfa = List<String?>.from(current.xinfa);
    xinfa[index] = xinfaName;
    await updateScheme(current.copyWith(xinfa: xinfa));
  }

  Future<void> setBowType(String bowType) async {
    final current = state.currentScheme;
    if (current == null) return;
    await updateScheme(current.copyWith(bowType: bowType));
  }

  Future<void> setSetBonus(String? setBonus) async {
    final current = state.currentScheme;
    if (current == null) return;
    await updateScheme(current.copyWith(setBonus: setBonus));
  }

  Future<void> setEarlySeasonBonus(bool value) async {
    final current = state.currentScheme;
    if (current == null) return;
    await updateScheme(current.copyWith(earlySeasonBonus: value));
  }

  Future<void> setPvpMode(bool value) async {
    final current = state.currentScheme;
    if (current == null) return;
    await updateScheme(current.copyWith(pvpMode: value));
  }

  Future<void> setLoanDingyin(bool value) async {
    final current = state.currentScheme;
    if (current == null) return;
    await updateScheme(current.copyWith(loanDingyin: value));
  }
}

final schemeProvider =
    StateNotifierProvider<SchemeViewModel, SchemeState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return SchemeViewModel(storage);
});
