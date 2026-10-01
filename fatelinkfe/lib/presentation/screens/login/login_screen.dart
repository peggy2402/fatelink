import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_zalo/flutter_zalo.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/utils/constants.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../logic/blocs/auth/auth_bloc.dart';
import '../../../logic/blocs/auth/auth_event.dart';
import '../../../logic/blocs/auth/auth_state.dart';
import 'widgets/login_auth_sheets.dart';
import 'widgets/login_backdrop.dart';
import 'widgets/login_form.dart';
import 'widgets/login_form_header.dart';

class LoginScreen extends StatefulWidget {
  final ScrollController? scrollController;
  const LoginScreen({super.key, this.scrollController});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _LoginAction { google, zalo, tiktok, email, register }

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  bool _internalScrollController = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '918573554808-07stv5tp2474icsh5f47mvop9vaa9sug.apps.googleusercontent.com',
  );

  final FlutterZalo _flutterZalo = FlutterZalo();
  static const MethodChannel _tikTokChannel = MethodChannel(
    'fatelink/tiktok_auth',
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _isEmailLoginExpanded = false;
  String _appVersion = '';
  _LoginAction? _activeLoginAction;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _internalScrollController = true;
    }
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
    _initAppVersion();
    _initZalo();
  }

  Future<void> _initZalo() async {
    try {
      await _flutterZalo.init();
    } catch (error) {
      debugPrint('Lỗi khởi tạo Zalo SDK: $error');
    }
  }

  Future<void> _initAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersion = 'v${packageInfo.version}';
      });
    } catch (error) {
      debugPrint('Lỗi khi lấy thông tin phiên bản: $error');
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    if (_internalScrollController) {
      _scrollController.dispose();
    }
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _activeLoginAction = _LoginAction.google);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _activeLoginAction = null);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('Không thể lấy được idToken từ Google.');
      }

      if (mounted) {
        context.read<AuthBloc>().add(
          AuthLoginRequested(
            provider: AuthSocialProvider.google,
            accessToken: idToken,
          ),
        );
      }
    } catch (error) {
      setState(() => _activeLoginAction = null);
      debugPrint('Lỗi Google Sign-In: $error');
      if (mounted) {
        ToastUtil.showError(context, 'Đăng nhập Google thất bại: $error');
      }
    }
  }

  Future<void> _handleZaloSignIn() async {
    if (AppConstants.zaloAppId == 'YOUR_ZALO_APP_ID') {
      ToastUtil.showWarning(context, 'Chưa cấu hình Zalo App ID.');
      return;
    }

    setState(() => _activeLoginAction = _LoginAction.zalo);
    try {
      final loggedIn = await _flutterZalo.logIn();
      if (loggedIn != true) {
        setState(() => _activeLoginAction = null);
        return;
      }

      final accessToken = await _flutterZalo.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Không lấy được access token từ Zalo.');
      }

      if (!mounted) return;
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          provider: AuthSocialProvider.zalo,
          accessToken: accessToken,
        ),
      );
    } catch (error) {
      setState(() => _activeLoginAction = null);
      debugPrint('Lỗi Zalo Sign-In: $error');
      if (mounted) {
        ToastUtil.showError(context, 'Đăng nhập Zalo thất bại.');
      }
    }
  }

  Future<void> _handleTikTokSignIn() async {
    setState(() => _activeLoginAction = _LoginAction.tiktok);
    try {
      final response = await _tikTokChannel.invokeMapMethod<String, dynamic>(
        'login',
      );
      final code = response?['code']?.toString();
      final codeVerifier = response?['codeVerifier']?.toString();

      if (code == null ||
          code.isEmpty ||
          codeVerifier == null ||
          codeVerifier.isEmpty) {
        setState(() => _activeLoginAction = null);
        throw Exception('Không nhận được authorization code từ TikTok.');
      }

      if (!mounted) return;
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          provider: AuthSocialProvider.tiktok,
          authorizationCode: code,
          codeVerifier: codeVerifier,
        ),
      );
    } on PlatformException catch (error) {
      setState(() => _activeLoginAction = null);
      debugPrint('Lỗi TikTok Sign-In: ${error.code} - ${error.message}');
      if (mounted) {
        ToastUtil.showError(
          context,
          error.message ?? 'Đăng nhập TikTok thất bại.',
        );
      }
    } catch (error) {
      setState(() => _activeLoginAction = null);
      debugPrint('Lỗi TikTok Sign-In: $error');
      if (mounted) {
        ToastUtil.showError(context, 'Đăng nhập TikTok thất bại.');
      }
    }
  }

  void _handleEmailLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ToastUtil.showWarning(context, 'Vui lòng nhập email và mật khẩu.');
      return;
    }

    setState(() => _activeLoginAction = _LoginAction.email);
    context.read<AuthBloc>().add(
      AuthEmailLoginRequested(email: email, password: password),
    );
  }

  void _handleEmailRegister() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      ToastUtil.showWarning(context, 'Vui lòng nhập tên hoặc biệt danh của bạn.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ToastUtil.showWarning(context, 'Vui lòng nhập email hợp lệ.');
      return;
    }
    if (password.length < 6) {
      ToastUtil.showWarning(context, 'Mật khẩu phải có ít nhất 6 ký tự.');
      return;
    }
    if (password != confirmPassword) {
      ToastUtil.showWarning(context, 'Mật khẩu xác nhận không khớp.');
      return;
    }

    setState(() => _activeLoginAction = _LoginAction.register);
    context.read<AuthBloc>().add(
      AuthEmailRegisterRequested(
        name: name,
        email: email,
        password: password,
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleEmailLoginExpanded() {
    setState(() {
      _isEmailLoginExpanded = !_isEmailLoginExpanded;
    });
  }

  Future<void> _showPhoneOtpSheet() {
    return showPhoneOtpSheet(context);
  }

  Future<void> _showMagicLinkSheet() {
    return showMagicLinkSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCFD),
      body: Stack(
        children: [
          const LoginBackdrop(),
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is! AuthLoading) {
                setState(() => _activeLoginAction = null);
              }
              if (state is AuthError) {
                ToastUtil.showError(context, state.message);
              } else if (state is AuthActionSuccess) {
                ToastUtil.showSuccess(context, state.message);
              } else if (state is AuthAuthenticated) {
                Navigator.pushReplacementNamed(context, '/main');
              }
            },
            child: SafeArea(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isAuthLoading = state is AuthLoading;
                  return LoginForm(
                    scrollController: _scrollController,
                    isLoginMode: _isLoginMode,
                    onTabChanged: (val) => setState(() => _isLoginMode = val),
                    nameController: _nameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    bounceAnimation: _bounceAnimation,
                    obscurePassword: _obscurePassword,
                    isEmailLoginExpanded: _isEmailLoginExpanded,
                    isLoading: isAuthLoading,
                    isGoogleLoading:
                        isAuthLoading &&
                        _activeLoginAction == _LoginAction.google,
                    isTikTokLoading:
                        isAuthLoading &&
                        _activeLoginAction == _LoginAction.tiktok,
                    isZaloLoading:
                        isAuthLoading &&
                        _activeLoginAction == _LoginAction.zalo,
                    isEmailLoading:
                        isAuthLoading &&
                        _activeLoginAction == _LoginAction.email,
                    isRegisterLoading:
                        isAuthLoading &&
                        _activeLoginAction == _LoginAction.register,
                    appVersion: _appVersion,
                    onGoogleSignIn: _handleGoogleSignIn,
                    onTikTokSignIn: _handleTikTokSignIn,
                    onZaloSignIn: _handleZaloSignIn,
                    onEmailLogin: _handleEmailLogin,
                    onEmailRegister: _handleEmailRegister,
                    onToggleEmailLoginExpanded: _toggleEmailLoginExpanded,
                    onTogglePasswordVisibility: _togglePasswordVisibility,
                    onShowMagicLinkSheet: _showMagicLinkSheet,
                    onShowPhoneOtpSheet: _showPhoneOtpSheet,
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, right: 16),
                child: const LoginSupportButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
