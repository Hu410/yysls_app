import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/account.dart';
import '../models/equipment.dart';
import '../models/scheme.dart';

class StorageService {
  static const String _accountsBox = 'accounts';
  static const String _settingsBox = 'settings';
  static const String _lastAccountKey = 'last_selected_account';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_accountsBox);
    await Hive.openBox(_settingsBox);
  }

  // ---- Accounts ----

  List<Account> getAccounts() {
    final box = Hive.box(_accountsBox);
    final raw = box.get('account_list', defaultValue: '[]') as String;
    final list = jsonDecode(raw) as List;
    return list.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveAccounts(List<Account> accounts) async {
    final box = Hive.box(_accountsBox);
    await box.put('account_list', jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }

  String? getLastAccountId() {
    final box = Hive.box(_settingsBox);
    return box.get(_lastAccountKey) as String?;
  }

  Future<void> setLastAccountId(String? id) async {
    final box = Hive.box(_settingsBox);
    if (id == null) {
      await box.delete(_lastAccountKey);
    } else {
      await box.put(_lastAccountKey, id);
    }
  }

  // ---- Equipment ----

  Future<Box> _openEquipBox(String accountId) async {
    final boxName = 'equip_$accountId';
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
    return await Hive.openBox(boxName);
  }

  Future<List<Equipment>> getEquipments(String accountId) async {
    final box = await _openEquipBox(accountId);
    final raw = box.get('data', defaultValue: '[]') as String;
    final list = jsonDecode(raw) as List;
    return list.map((e) => Equipment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveEquipments(String accountId, List<Equipment> equipments) async {
    final box = await _openEquipBox(accountId);
    await box.put('data', jsonEncode(equipments.map((e) => e.toJson()).toList()));
  }

  // ---- Schemes ----

  Future<Box> _openSchemeBox(String accountId) async {
    final boxName = 'schemes_$accountId';
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
    return await Hive.openBox(boxName);
  }

  Future<List<Scheme>> getSchemes(String accountId) async {
    final box = await _openSchemeBox(accountId);
    final raw = box.get('data', defaultValue: '[]') as String;
    final list = jsonDecode(raw) as List;
    return list.map((e) => Scheme.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveSchemes(String accountId, List<Scheme> schemes) async {
    final box = await _openSchemeBox(accountId);
    await box.put('data', jsonEncode(schemes.map((s) => s.toJson()).toList()));
  }

  // ---- Delete Account Data ----

  Future<void> deleteAccountData(String accountId) async {
    final equipBoxName = 'equip_$accountId';
    final schemeBoxName = 'schemes_$accountId';
    if (Hive.isBoxOpen(equipBoxName)) {
      await Hive.box(equipBoxName).deleteFromDisk();
    } else {
      try {
        final box = await Hive.openBox(equipBoxName);
        await box.deleteFromDisk();
      } catch (_) {}
    }
    if (Hive.isBoxOpen(schemeBoxName)) {
      await Hive.box(schemeBoxName).deleteFromDisk();
    } else {
      try {
        final box = await Hive.openBox(schemeBoxName);
        await box.deleteFromDisk();
      } catch (_) {}
    }
  }

  // ---- Export / Import ----

  Future<String> exportAccountData(String accountId) async {
    final equipments = await getEquipments(accountId);
    final schemes = await getSchemes(accountId);
    final data = {
      'equipments': equipments.map((e) => e.toJson()).toList(),
      'schemes': schemes.map((s) => s.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  Future<void> importAccountData(String accountId, String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (data.containsKey('equipments')) {
      final equipments = (data['equipments'] as List)
          .map((e) => Equipment.fromJson(e as Map<String, dynamic>))
          .toList();
      await saveEquipments(accountId, equipments);
    }
    if (data.containsKey('schemes')) {
      final schemes = (data['schemes'] as List)
          .map((s) => Scheme.fromJson(s as Map<String, dynamic>))
          .toList();
      await saveSchemes(accountId, schemes);
    }
  }
}
