import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {} // Khởi chạy auto-login

class AuthLoginRequested extends AuthEvent {
  final String googleIdToken; // Mã token từ Google Sign-In gửi lên

  const AuthLoginRequested(this.googleIdToken);

  @override
  List<Object?> get props => [googleIdToken];
}

class AuthLogoutRequested extends AuthEvent {} // Người dùng bấm đăng xuất
