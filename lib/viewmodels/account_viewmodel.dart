import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class AccountState {
  final List<Account> accounts;
  final String? currentAccountId;
  final bool isLoading;

  const AccountState({
    this.accounts = const [],
    this.currentAccountId,
    this.isLoading = true,
  });

  Account? get currentAccount {
    if (currentAccountId == null) return null;
    try {
      return accounts.firstWhere((a) => a.id == currentAccountId);
    } catch (_) {
      return null;
    }
  }

  AccountState copyWith({
    List<Account>? accounts,
    String? currentAccountId,
    bool? isLoading,
    bool clearCurrentAccount = false,
  }) {
    return AccountState(
      accounts: accounts ?? this.accounts,
      currentAccountId: clearCurrentAccount
          ? null
          : (currentAccountId ?? this.currentAccountId),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AccountViewModel extends StateNotifier<AccountState> {
  final StorageService _storage;

  AccountViewModel(this._storage) : super(const AccountState());

  Future<void> load() async {
    final accounts = _storage.getAccounts();
    final lastId = _storage.getLastAccountId();
    final validId =
        accounts.any((a) => a.id == lastId) ? lastId : null;
    state = AccountState(
      accounts: accounts,
      currentAccountId: validId,
      isLoading: false,
    );
  }

  Future<void> createAccount(String name) async {
    final account = Account(id: const Uuid().v4(), name: name.trim());
    final updated = [...state.accounts, account];
    await _storage.saveAccounts(updated);
    await _storage.setLastAccountId(account.id);
    state = state.copyWith(
      accounts: updated,
      currentAccountId: account.id,
    );
  }

  Future<void> selectAccount(String id) async {
    await _storage.setLastAccountId(id);
    state = state.copyWith(currentAccountId: id);
  }

  Future<void> deleteAccount(String id) async {
    final updated = state.accounts.where((a) => a.id != id).toList();
    await _storage.saveAccounts(updated);
    await _storage.deleteAccountData(id);
    final newCurrent =
        state.currentAccountId == id ? null : state.currentAccountId;
    if (newCurrent == null) {
      await _storage.setLastAccountId(null);
    }
    state = state.copyWith(
      accounts: updated,
      currentAccountId: newCurrent,
      clearCurrentAccount: state.currentAccountId == id,
    );
  }
}

final accountProvider =
    StateNotifierProvider<AccountViewModel, AccountState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AccountViewModel(storage);
});
