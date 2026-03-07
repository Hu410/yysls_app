import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/class_config.dart';

class SimulatorState {
  final String? selectedClass;
  final String? selectedArmory;

  const SimulatorState({
    this.selectedClass,
    this.selectedArmory,
  });

  SimulatorState copyWith({
    String? selectedClass,
    String? selectedArmory,
    bool clearClass = false,
  }) {
    return SimulatorState(
      selectedClass:
          clearClass ? null : (selectedClass ?? this.selectedClass),
      selectedArmory: selectedArmory ?? this.selectedArmory,
    );
  }
}

class SimulatorViewModel extends StateNotifier<SimulatorState> {
  SimulatorViewModel() : super(const SimulatorState());

  void selectClass(String? className) {
    state = state.copyWith(
      selectedClass: className,
      clearClass: className == null,
    );
  }

  void selectArmory(String? armory) {
    state = state.copyWith(selectedArmory: armory);
  }

  List<String>? get currentWeaponRule {
    if (state.selectedClass == null) return null;
    return ClassConfig.getWeaponRule(state.selectedClass!);
  }
}

final simulatorProvider =
    StateNotifierProvider<SimulatorViewModel, SimulatorState>((ref) {
  return SimulatorViewModel();
});
