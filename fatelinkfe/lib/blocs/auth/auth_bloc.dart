import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/constants.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final _secureStorage = const FlutterSecureStorage();

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (token != null && token.isNotEmpty) {
        // TODO: (Tuỳ chọn) Gọi API để verify xem token này còn sống không
        emit(AuthAuthenticated(token));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Gọi API lên Backend NestJS để đổi Google Token lấy JWT Access Token
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.loginWithGoogle}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': event.googleIdToken}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final String accessToken = data['accessToken'];
        
        await _secureStorage.write(key: 'accessToken', value: accessToken);
        emit(AuthAuthenticated(accessToken));
      } else {
        throw Exception('Đăng nhập thất bại: ${response.statusCode}');
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _secureStorage.delete(key: 'accessToken');
    emit(AuthUnauthenticated());
  }
}
