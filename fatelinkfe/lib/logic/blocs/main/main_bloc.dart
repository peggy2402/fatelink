import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_event.dart';
import 'main_state.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  MainBloc() : super(const MainState(selectedIndex: 0, tabHistory: [0])) {
    on<InitMainEvent>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      final lastTab = prefs.getInt('lastTab') ?? 0;
      emit(state.copyWith(selectedIndex: lastTab, tabHistory: [lastTab]));
    });

    on<ChangeTabEvent>((event, emit) async {
      if (state.selectedIndex == event.tabIndex) return;
      
      // Cập nhật lịch sử: xoá tab nếu đã tồn tại và đẩy nó lên đầu
      final newHistory = List<int>.from(state.tabHistory);
      newHistory.remove(event.tabIndex);
      newHistory.add(event.tabIndex);

      // Phát emit cập nhật UI ngay lập tức để không có độ trễ
      emit(state.copyWith(selectedIndex: event.tabIndex, tabHistory: newHistory));
      // Lưu background (fire-and-forget)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastTab', event.tabIndex);
    });

    on<PopTabEvent>((event, emit) async {
      if (state.tabHistory.length > 1) {
        // Lấy danh sách lịch sử, xoá tab hiện tại, và lấy tab liền trước đó
        final newHistory = List<int>.from(state.tabHistory)..removeLast();
        final previousTab = newHistory.last;
        
        emit(state.copyWith(selectedIndex: previousTab, tabHistory: newHistory));
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('lastTab', previousTab);
      }
    });
  }
}
