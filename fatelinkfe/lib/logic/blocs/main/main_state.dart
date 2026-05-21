import 'package:equatable/equatable.dart';

class MainState extends Equatable {
  final int selectedIndex;
  final List<int> tabHistory; // Thêm mảng lưu lịch sử

  const MainState({
    this.selectedIndex = 0,
    this.tabHistory = const [0],
  });

  MainState copyWith({int? selectedIndex, List<int>? tabHistory}) {
    return MainState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      tabHistory: tabHistory ?? this.tabHistory,
    );
  }

  @override
  List<Object> get props => [selectedIndex, tabHistory];
}
