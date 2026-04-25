import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {} // Vừa mở app

class AuthLoading
    extends AuthState {} // Đang check token hoặc đang gọi API Login

class AuthAuthenticated extends AuthState {
  final String token;
  const AuthAuthenticated(this.token);

  @override
  List<Object?> get props => [token];
} // Đã đăng nhập

class AuthUnauthenticated
    extends AuthState {} // Chưa đăng nhập hoặc token hết hạn

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
} // Lỗi đăng nhập
