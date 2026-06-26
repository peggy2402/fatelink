import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fatelinkfe/services/api_service.dart';
import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final _secureStorage = const FlutterSecureStorage();

  SplashBloc() : super(SplashInitial()) {
    on<SplashStarted>(_onSplashStarted);
  }

  Future<void> _onSplashStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashLoading());
    
    // Đợi 2.5 giây để người dùng kịp ngắm hiệu ứng đẹp mắt của Splash Screen
    await Future.delayed(const Duration(milliseconds: 2500));

    try {
      // 1. Kiểm tra xem có phải là lần đầu mở app không
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('is_first_time') ?? true;

      if (isFirstTime) {
        emit(SplashNavigateToOnboarding());
        return;
      }

      // 2. Nếu không phải lần đầu, kiểm tra xem token có tồn tại không
      var token = await _secureStorage.read(key: 'accessToken');
      token ??= await ApiService.tryRefreshToken();
      if (token != null && token.isNotEmpty) {
        emit(SplashNavigateToHome());
      } else {
        emit(SplashNavigateToLogin());
      }
    } catch (e) {
      emit(SplashNavigateToLogin());
    }
  }
}
