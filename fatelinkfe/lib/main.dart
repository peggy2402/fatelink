import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/fcm_service.dart';
import 'screens/splash_screen.dart';
import 'screens/match_chat_screen.dart';

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
    return MaterialApp(
      title: 'FateLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale, // Lắng nghe ngôn ngữ hiện tại
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/match-chat') {
          // Trích xuất arguments được truyền từ Navigator.pushNamed
          final args = settings.arguments;
          String partnerId = args is String ? args : 'unknown_id';

          return MaterialPageRoute(
            builder: (context) => MatchChatScreen(
              partnerId: partnerId,
              partnerName:
                  'Định mệnh', // Tên mặc định, có thể nâng cấp truyền Map sau
            ),
          );
        }
        return null; // Trả về null để Flutter dùng các route mặc định khác
      },
    );
  }
}
