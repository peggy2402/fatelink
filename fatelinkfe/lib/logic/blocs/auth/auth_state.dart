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
  final bool pendingTermsConsent;
  const AuthAuthenticated(this.token, {this.pendingTermsConsent = false});

  @override
  List<Object?> get props => [token, pendingTermsConsent];
} // Đã đăng nhập

class AuthActionSuccess extends AuthState {
  final String message;
  const AuthActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthUnauthenticated
    extends AuthState {} // Chưa đăng nhập hoặc token hết hạn

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
} // Lỗi đăng nhập
