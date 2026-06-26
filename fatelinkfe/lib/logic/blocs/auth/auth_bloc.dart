import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../core/utils/constants.dart';
import '../../../core/utils/device_id_helper.dart';
import '../../../services/api_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final _secureStorage = const FlutterSecureStorage();

  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onSocialLoginRequested);
    on<AuthEmailLoginRequested>(_onEmailLoginRequested);
    on<AuthEmailRegisterRequested>(_onEmailRegisterRequested);
    on<AuthPhoneRequestOtpRequested>(_onPhoneRequestOtpRequested);
    on<AuthPhoneLoginRequested>(_onPhoneLoginRequested);
    on<AuthMagicLinkRequestRequested>(_onMagicLinkRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      var token = await _secureStorage.read(key: 'accessToken');
      final pendingTermsConsent =
          (await _secureStorage.read(key: 'pendingTermsConsent')) == 'true';
      token ??= await ApiService.tryRefreshToken();
      if (token != null && token.isNotEmpty) {
        emit(
          AuthAuthenticated(
            token,
            pendingTermsConsent: pendingTermsConsent,
          ),
        );
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSocialLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final authResult = await _authenticateWithSession(
        endpoint: _getLoginEndpoint(event.provider),
        body: _buildSocialLoginRequestBody(event),
      );
      emit(
        AuthAuthenticated(
          authResult.accessToken,
          pendingTermsConsent: authResult.pendingTermsConsent,
        ),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onEmailLoginRequested(
    AuthEmailLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final authResult = await _authenticateWithSession(
        endpoint: 'auth/email/login',
        body: {
          'email': event.email.trim(),
          'password': event.password,
        },
      );
      emit(
        AuthAuthenticated(
          authResult.accessToken,
          pendingTermsConsent: authResult.pendingTermsConsent,
        ),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onEmailRegisterRequested(
    AuthEmailRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final authResult = await _authenticateWithSession(
        endpoint: 'auth/email/register',
        body: {
          'email': event.email.trim(),
          'password': event.password,
          'name': event.name.trim(),
        },
        fallbackPendingTermsConsent: true,
      );
      emit(
        AuthAuthenticated(
          authResult.accessToken,
          pendingTermsConsent: authResult.pendingTermsConsent,
        ),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onPhoneRequestOtpRequested(
    AuthPhoneRequestOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/auth/phone/request-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phoneNumber': event.phoneNumber.trim(),
              if (event.name != null && event.name!.trim().isNotEmpty)
                'name': event.name!.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        emit(AuthActionSuccess(data['message']?.toString() ?? 'Đã gửi OTP.'));
        emit(AuthUnauthenticated());
      } else {
        throw Exception(
          'Gửi OTP thất bại: Mã lỗi ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onPhoneLoginRequested(
    AuthPhoneLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final authResult = await _authenticateWithSession(
        endpoint: 'auth/phone/login',
        body: {
          'phoneNumber': event.phoneNumber.trim(),
          'otpCode': event.otpCode.trim(),
        },
      );
      emit(
        AuthAuthenticated(
          authResult.accessToken,
          pendingTermsConsent: authResult.pendingTermsConsent,
        ),
      );
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onMagicLinkRequested(
    AuthMagicLinkRequestRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/auth/magic-link/request'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': event.email.trim(),
              if (event.name != null && event.name!.trim().isNotEmpty)
                'name': event.name!.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        emit(
          AuthActionSuccess(
            data['message']?.toString() ??
                'Đã gửi magic link. Vui lòng kiểm tra email.',
          ),
        );
        emit(AuthUnauthenticated());
      } else {
        throw Exception(
          'Gửi magic link thất bại: Mã lỗi ${response.statusCode} - ${response.body}',
        );
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
    emit(AuthLoading());
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      final urlEnpoints = '${AppConstants.baseUrl}/${AppConstants.logout}';
      debugPrint('Gọi API logout tại: $urlEnpoints với token: $token');
      if (token != null) {
        await http.post(
          Uri.parse(urlEnpoints),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 10));
      }
    } catch (e) {
      debugPrint('Lỗi khi đăng xuất: $e');
    } finally {
      await _secureStorage.delete(key: 'accessToken');
      await _secureStorage.delete(key: 'refreshToken');
      await _secureStorage.delete(key: 'avatarUrl');
      await _secureStorage.delete(key: 'userName');
      await _secureStorage.delete(key: 'userId');
      emit(AuthUnauthenticated());
    }
  }

  String _getLoginEndpoint(AuthSocialProvider provider) {
    switch (provider) {
      case AuthSocialProvider.google:
        return AppConstants.loginWithGoogle;
      case AuthSocialProvider.zalo:
        return AppConstants.loginWithZalo;
      case AuthSocialProvider.tiktok:
        return AppConstants.loginWithTikTok;
    }
  }

  Map<String, dynamic> _buildSocialLoginRequestBody(AuthLoginRequested event) {
    switch (event.provider) {
      case AuthSocialProvider.google:
        return {
          'token': event.accessToken,
        };
      case AuthSocialProvider.zalo:
        return {
          'accessToken': event.accessToken,
        };
      case AuthSocialProvider.tiktok:
        if (event.authorizationCode != null && event.codeVerifier != null) {
          return {
            'authType': 'authorization_code',
            'code': event.authorizationCode,
            'codeVerifier': event.codeVerifier,
          };
        }
        return {
          'authType': 'access_token',
          'accessToken': event.accessToken,
        };
    }
  }

  Future<_AuthResult> _authenticateWithSession({
    required String endpoint,
    required Map<String, dynamic> body,
    bool fallbackPendingTermsConsent = false,
  }) async {
    final deviceId = await DeviceIdHelper.getOrCreateDeviceId();
    final response = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}/$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            ...body,
            'deviceType': _getDeviceType(),
            'deviceId': deviceId,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Xác thực thất bại: Mã lỗi ${response.statusCode} - ${response.body}',
      );
    }

    return _persistAuthPayload(
      response.body,
      fallbackPendingTermsConsent:
          fallbackPendingTermsConsent || response.statusCode == 201,
    );
  }

  Future<_AuthResult> _persistAuthPayload(
    String rawBody, {
    bool fallbackPendingTermsConsent = false,
  }) async {
    final data = jsonDecode(rawBody);
    final String accessToken = data['accessToken'];
    final String? refreshToken = data['refreshToken']?.toString();
    final userData = data['data'];
    final bool pendingTermsConsent = _resolvePendingTermsConsent(
      data,
      fallbackPendingTermsConsent,
    );

    if (userData != null) {
      await _secureStorage.write(
        key: 'avatarUrl',
        value: userData['avatar']?.toString() ?? '',
      );
      await _secureStorage.write(
        key: 'userName',
        value: userData['name']?.toString() ?? '',
      );
      await _secureStorage.write(
        key: 'userId',
        value: userData['_id']?.toString() ?? '',
      );
    }

    await _secureStorage.write(key: 'accessToken', value: accessToken);
    await _secureStorage.write(
      key: 'pendingTermsConsent',
      value: pendingTermsConsent.toString(),
    );
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorage.write(key: 'refreshToken', value: refreshToken);
    }
    return _AuthResult(
      accessToken: accessToken,
      pendingTermsConsent: pendingTermsConsent,
    );
  }

  bool _resolvePendingTermsConsent(
    dynamic data,
    bool fallbackPendingTermsConsent,
  ) {
    if (data is Map<String, dynamic>) {
      final candidates = [
        data['pendingTermsConsent'],
        data['requiresTermsConsent'],
        data['mustAcceptTerms'],
        data['isNewUser'],
        data['newUser'],
        data['isFirstLogin'],
        data['firstLogin'],
        data['data'] is Map<String, dynamic>
            ? (data['data'] as Map<String, dynamic>)['pendingTermsConsent']
            : null,
        data['data'] is Map<String, dynamic>
            ? (data['data'] as Map<String, dynamic>)['isNewUser']
            : null,
        data['data'] is Map<String, dynamic>
            ? (data['data'] as Map<String, dynamic>)['firstLogin']
            : null,
      ];

      for (final candidate in candidates) {
        final resolved = _asBool(candidate);
        if (resolved != null) {
          return resolved;
        }
      }
    }

    return fallbackPendingTermsConsent;
  }

  bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }

  String _getDeviceType() {
    if (kIsWeb) {
      return 'web';
    }
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return 'desktop';
    }
    return 'mobile';
  }
}

class _AuthResult {
  final String accessToken;
  final bool pendingTermsConsent;

  const _AuthResult({
    required this.accessToken,
    required this.pendingTermsConsent,
  });
}
