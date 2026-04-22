import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/fcm_service.dart';
import 'screens/splash_screen.dart';
import 'screens/match_chat_screen.dart';
import 'blocs/auth/auth_bloc.dart';
import 'widgets/auth_wrapper.dart';
import 'repositories/chat_repository.dart';
import 'repositories/matches_repository.dart';
import 'repositories/home_repository.dart';
import 'repositories/profile_repository.dart';
import 'blocs/chat/chat_bloc.dart';
import 'blocs/matches/matches_bloc.dart';
import 'blocs/home/home_bloc.dart';
import 'blocs/profile/profile_bloc.dart';
import 'blocs/main/main_bloc.dart';
import 'blocs/main/main_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FcmService.initialize();
  await EasyLocalization.ensureInitialized();

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
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ChatRepository>(
          create: (context) => ChatRepository(),
        ),
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
          BlocProvider<MainBloc>(create: (context) => MainBloc()..add(InitMainEvent())),
          BlocProvider<ChatBloc>(
            create: (context) =>
                ChatBloc(chatRepository: context.read<ChatRepository>()),
          ),
          BlocProvider<MatchesBloc>(
            create: (context) =>
                MatchesBloc(repository: context.read<MatchesRepository>()),
          ),
          BlocProvider<HomeBloc>(
            create: (context) =>
                HomeBloc(repository: context.read<HomeRepository>()),
          ),
          BlocProvider<ProfileBloc>(
            create: (context) =>
                ProfileBloc(repository: context.read<ProfileRepository>()),
          ),
        ],
        child: MaterialApp(
          title: 'FateLink',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(primarySwatch: Colors.blue),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: const AuthWrapper(),
          onGenerateRoute: (settings) {
            if (settings.name == '/match-chat') {
              final args = settings.arguments;
              String partnerId = args is String ? args : 'unknown_id';
              return MaterialPageRoute(
                builder: (context) => MatchChatScreen(
                  partnerId: partnerId,
                  partnerName: 'FateLink'.tr(),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}
