import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_event.dart';
import 'main_state.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  MainBloc() : super(const MainState(selectedIndex: 0)) {
    on<InitMainEvent>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      final lastTab = prefs.getInt('lastTab') ?? 0;
      emit(state.copyWith(selectedIndex: lastTab));
    });

    on<ChangeTabEvent>((event, emit) async {
      // Phát emit cập nhật UI ngay lập tức để không có độ trễ
      emit(state.copyWith(selectedIndex: event.tabIndex));
      // Lưu background (fire-and-forget)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastTab', event.tabIndex);
    });
  }
}
