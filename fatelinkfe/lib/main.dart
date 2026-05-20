import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/fcm_service.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/match_chat_screen.dart';
import 'logic/blocs/auth/auth_bloc.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/matches_repository.dart';
import 'data/repositories/home_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'logic/blocs/chat/chat_bloc.dart';
import 'logic/blocs/matches/matches_bloc.dart';
import 'logic/blocs/home/home_bloc.dart';
import 'logic/blocs/profile/profile_bloc.dart';
import 'logic/blocs/main/main_bloc.dart';
import 'logic/blocs/main/main_event.dart';
import 'logic/blocs/splash/splash_bloc.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await EasyLocalization.ensureInitialized();
    await Firebase.initializeApp();
    
    try {
      await FcmService.initialize();
    } catch (fcmError) {
      debugPrint('Cảnh báo: Không thể khởi tạo FCM (Thường xảy ra trên máy ảo iOS): $fcmError');
    }
  } catch (e, stackTrace) {
    debugPrint('Lỗi khởi tạo App: $e\n$stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Lỗi khởi tạo ứng dụng:\n$e\n\nVui lòng kiểm tra cấu hình Firebase hoặc thư mục translations.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
    );
    return; // Dừng lại, không chạy app chính để tránh crash màn hình đỏ
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('vi'), Locale('en')],
      path: 'assets/translations', // Đường dẫn tới thư mục chứa file JSON
      fallbackLocale: const Locale('vi'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Khởi tạo các repository ở đây để đảm bảo chúng là Singleton
    final chatRepository = ChatRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: chatRepository),
        RepositoryProvider<MatchesRepository>(
          create: (context) => MatchesRepository(),
        ),
        RepositoryProvider<HomeRepository>(
          create: (context) => HomeRepository(),
        ),
        RepositoryProvider<ProfileRepository>(
          create: (context) => ProfileRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(create: (context) => AuthBloc()),
          BlocProvider<MainBloc>(
            create: (context) => MainBloc()..add(InitMainEvent()),
          ),
          BlocProvider<ChatBloc>(
            create: (context) => ChatBloc(chatRepository: chatRepository),
          ),
          BlocProvider<MatchesBloc>(
            create: (context) =>
                MatchesBloc(repository: context.read<MatchesRepository>()),
          ),
          BlocProvider<HomeBloc>(
            create: (context) =>
                HomeBloc(homeRepository: context.read<HomeRepository>()),
          ),
          BlocProvider<ProfileBloc>(
            create: (context) =>
                ProfileBloc(repository: context.read<ProfileRepository>()),
          ),
          BlocProvider<SplashBloc>(create: (context) => SplashBloc()),
        ],
        child: MaterialApp(
          title: 'FateLink',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(primarySwatch: Colors.blue),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: const SplashScreen(),
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
