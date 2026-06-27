import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {} // Khởi chạy auto-login

enum AuthSocialProvider { google, zalo, tiktok }

class AuthLoginRequested extends AuthEvent {
  final AuthSocialProvider provider;
  final String? accessToken;
  final String? authorizationCode;
  final String? codeVerifier;

  const AuthLoginRequested({
    required this.provider,
    this.accessToken,
    this.authorizationCode,
    this.codeVerifier,
  });

  @override
  List<Object?> get props => [
    provider,
    accessToken,
    authorizationCode,
    codeVerifier,
  ];
}

class AuthEmailLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthEmailLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthEmailRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const AuthEmailRegisterRequested({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

class AuthPhoneRequestOtpRequested extends AuthEvent {
  final String phoneNumber;
  final String? name;

  const AuthPhoneRequestOtpRequested({
    required this.phoneNumber,
    this.name,
  });

  @override
  List<Object?> get props => [phoneNumber, name];
}

class AuthPhoneLoginRequested extends AuthEvent {
  final String phoneNumber;
  final String otpCode;

  const AuthPhoneLoginRequested({
    required this.phoneNumber,
    required this.otpCode,
  });

  @override
  List<Object?> get props => [phoneNumber, otpCode];
}

class AuthMagicLinkRequestRequested extends AuthEvent {
  final String email;
  final String? name;

  const AuthMagicLinkRequestRequested({
    required this.email,
    this.name,
  });

  @override
  List<Object?> get props => [email, name];
}

class AuthLogoutRequested extends AuthEvent {} // Người dùng bấm đăng xuất
