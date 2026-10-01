import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fatelinkfe/data/models/match_user.dart';
import 'package:fatelinkfe/presentation/screens/home/widgets/home_hero_banner.dart';
import 'package:fatelinkfe/presentation/screens/home/widgets/radar_scanner_modal.dart';
import 'package:fatelinkfe/presentation/screens/home/widgets/home_online_stories.dart';
import 'package:fatelinkfe/presentation/screens/home/widgets/home_header.dart';
import 'package:fatelinkfe/presentation/screens/home/widgets/soul_match_card.dart';
import 'package:fatelinkfe/presentation/widgets/custom_bottom_nav_bar.dart';
import 'package:fatelinkfe/presentation/widgets/chat_input_bar.dart';
import 'package:fatelinkfe/presentation/widgets/floating_ai_bubble.dart';
import 'package:fatelinkfe/presentation/widgets/settings_distance_bottom_sheet.dart';
import 'package:fatelinkfe/presentation/widgets/menu.dart';
import 'package:fatelinkfe/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fatelinkfe/data/repositories/home_repository.dart';
import 'package:fatelinkfe/logic/blocs/home/home_bloc.dart';
import 'package:fatelinkfe/logic/blocs/home/home_state.dart';
import 'package:fatelinkfe/presentation/screens/explore/explore_screen.dart';

class MockHomeRepository extends HomeRepository {
  @override
  Future<List<MatchUser>> fetchRecommendations({required BuildContext context}) async => [];

  @override
  Future<bool> updateUserFrequency({
    required BuildContext context,
    required String mood,
    required String vibe,
    required String signal,
    String? frequencyHertz,
  }) async => true;
}

// Test matrix definitions
class MatrixConfig {
  final String name;
  final Size size;

  const MatrixConfig(this.name, this.size);
}

const testDevices = [
  MatrixConfig('Phone_320x568', Size(320, 568)),
  MatrixConfig('Phone_360x640', Size(360, 640)),
  MatrixConfig('Phone_390x844', Size(390, 844)),
  MatrixConfig('Phone_430x932', Size(430, 932)),
  MatrixConfig('Tablet_600x960', Size(600, 960)),
  MatrixConfig('Phone_Landscape_844x390', Size(844, 390)),
  MatrixConfig('Tablet_Landscape_1024x768', Size(1024, 768)),
];

const testScales = [0.85, 1.0, 1.3, 2.0];

class TestResult {
  final String component;
  final String device;
  final double scale;
  final bool keyboardOpen;
  final bool passed;
  final String? errorMessage;

  TestResult({
    required this.component,
    required this.device,
    required this.scale,
    required this.keyboardOpen,
    required this.passed,
    this.errorMessage,
  });
}

final List<TestResult> baselineResults = [];

void recordResult({
  required String component,
  required String device,
  required double scale,
  required bool keyboardOpen,
  required bool passed,
  String? errorMessage,
}) {
  baselineResults.add(TestResult(
    component: component,
    device: device,
    scale: scale,
    keyboardOpen: keyboardOpen,
    passed: passed,
    errorMessage: errorMessage,
  ));
}

Widget buildTestHarness({
  required Widget child,
  required Size size,
  required double textScale,
  EdgeInsets viewInsets = EdgeInsets.zero,
  EdgeInsets padding = const EdgeInsets.only(top: 44, bottom: 34),
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      textScaler: TextScaler.linear(textScale),
      viewInsets: viewInsets,
      padding: padding,
    ),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: child,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  tearDownAll(() {
    // Print structured baseline failure report
    debugPrint('\n=================== BASELINE TEST MATRIX REPORT ===================');
    final failures = baselineResults.where((r) => !r.passed).toList();
    debugPrint('TOTAL TESTS RUN: ${baselineResults.length}');
    debugPrint('TOTAL FAILURES: ${failures.length}');
    debugPrint('TOTAL PASSES:   ${baselineResults.length - failures.length}\n');

    debugPrint('| Component | Device | TextScale | Keyboard | Status | Error Details |');
    debugPrint('| :--- | :--- | :---: | :---: | :---: | :--- |');
    for (final r in baselineResults) {
      if (!r.passed) {
        debugPrint('| ${r.component} | ${r.device} | ${r.scale}x | ${r.keyboardOpen ? "Open" : "Closed"} | FAIL | ${r.errorMessage?.replaceAll("\n", " ").take(60)} |');
      }
    }
    debugPrint('===================================================================\n');
  });

  final dummyUser = MatchUser(
    id: 'user_test_123',
    name: 'Nguyễn Văn Định Mệnh',
    emotion: 'Bí ẩn & Lắng đọng',
    compatibilityScore: 92,
    distanceKm: 2.5,
    tags: ['#NhạcIndie', '#DeepTalk', '#NgắmMưa'],
    moodIcon: '🌧️',
    bio: 'Đang tìm kiếm một kết nối đồng điệu vượt qua mọi giới hạn...',
  );

  // -------------------------------------------------------------
  // GROUP (A) CỰC KỲ NGHIÊM TRỌNG
  // -------------------------------------------------------------
  group('Group A - HomeHeroBanner Matrix', () {
    for (final dev in testDevices) {
      for (final scale in testScales) {
        testWidgets('${dev.name} @ ${scale}x', (tester) async {
          String? overflowError;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            final msg = details.exceptionAsString();
            if (msg.contains('overflow') || msg.contains('RenderFlex')) {
              overflowError = msg;
              debugPrint('OVERFLOW DETAIL: $msg\n${details.informationCollector?.call().map((e) => e.toString()).join("\n")}');
            }
          };

          await tester.binding.setSurfaceSize(dev.size);
          await tester.pumpWidget(buildTestHarness(
            size: dev.size,
            textScale: scale,
            child: HomeHeroBanner(onStartChat: () {}),
          ));
          await tester.pump();

          FlutterError.onError = prevOnError;

          final passed = overflowError == null;
          recordResult(
            component: 'HomeHeroBanner',
            device: dev.name,
            scale: scale,
            keyboardOpen: false,
            passed: passed,
            errorMessage: overflowError,
          );
        });
      }
    }
  });

  group('Group A - RadarScannerModal Matrix', () {
    for (final dev in testDevices) {
      for (final scale in testScales) {
        testWidgets('${dev.name} @ ${scale}x', (tester) async {
          String? overflowError;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            final msg = details.exceptionAsString();
            if (msg.contains('overflow') || msg.contains('RenderFlex')) {
              overflowError = msg;
              debugPrint('RADAR OVERFLOW DETAIL: $msg\n${details.informationCollector?.call().map((e) => e.toString()).join("\n")}');
            }
          };

          await tester.binding.setSurfaceSize(dev.size);
          await tester.pumpWidget(buildTestHarness(
            size: dev.size,
            textScale: scale,
            child: const RadarScannerModal(),
          ));
          await tester.pump();

          FlutterError.onError = prevOnError;

          final passed = overflowError == null;
          recordResult(
            component: 'RadarScannerModal',
            device: dev.name,
            scale: scale,
            keyboardOpen: false,
            passed: passed,
            errorMessage: overflowError,
          );
        });
      }
    }
  });

  group('Group A - FloatingAiBubble Matrix', () {
    for (final dev in testDevices) {
      for (final scale in testScales) {
        testWidgets('${dev.name} @ ${scale}x', (tester) async {
          String? overflowError;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            final msg = details.exceptionAsString();
            if (msg.contains('overflow') || msg.contains('RenderFlex')) {
              overflowError = msg;
            }
          };

          await tester.binding.setSurfaceSize(dev.size);
          await tester.pumpWidget(buildTestHarness(
            size: dev.size,
            textScale: scale,
            child: Stack(
              children: [
                FloatingAiBubble(onTap: () {}),
              ],
            ),
          ));
          await tester.pump();

          FlutterError.onError = prevOnError;

          final passed = overflowError == null;
          recordResult(
            component: 'FloatingAiBubble',
            device: dev.name,
            scale: scale,
            keyboardOpen: false,
            passed: passed,
            errorMessage: overflowError,
          );
        });
      }
    }
  });

  group('Group A - ExploreScreen Matrix', () {
    for (final dev in testDevices) {
      for (final scale in testScales) {
        testWidgets('${dev.name} @ ${scale}x', (tester) async {
          String? overflowError;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            final msg = details.exceptionAsString();
            if (msg.contains('overflow') || msg.contains('RenderFlex')) {
              overflowError = msg;
            }
          };

          await tester.binding.setSurfaceSize(dev.size);
          await tester.pumpWidget(buildTestHarness(
            size: dev.size,
            textScale: scale,
            child: BlocProvider<HomeBloc>(
              create: (_) => HomeBloc(homeRepository: MockHomeRepository())
                ..emit(HomeState(status: HomeStatus.loaded, matchedUsers: [dummyUser])),
              child: const ExploreScreen(),
            ),
          ));
          await tester.pump();

          FlutterError.onError = prevOnError;

          final passed = overflowError == null;
          recordResult(
            component: 'ExploreScreen',
            device: dev.name,
            scale: scale,
            keyboardOpen: false,
            passed: passed,
            errorMessage: overflowError,
          );
        });
      }
    }
  });

  // -------------------------------------------------------------
  // GROUP (B) NGHIÊM TRỌNG
  // -------------------------------------------------------------
  group('Group B - HomeOnlineStories Matrix', () {
    for (final dev in testDevices) {
      for (final scale in testScales) {
        testWidgets('${dev.name} @ ${scale}x', (tester) async {
          String? overflowError;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            final msg = details.exceptionAsString();
            if (msg.contains('overflow') || msg.contains('RenderFlex')) {
              overflowError = msg;
            }
          };

          await tester.binding.setSurfaceSize(dev.size);
          await tester.pumpWidget(buildTestHarness(
            size: dev.size,
            textScale: scale,
            child: HomeOnlineStories(
              currentUserMood: 'Bình yên',
              currentUserFrequency: '528 Hz',
              onlineUsers: [dummyUser],
            ),
          ));
          await tester.pump();

          FlutterError.onError = prevOnError;

          final passed = overflowError == null;
          recordResult(
            component: 'HomeOnlineStories',
            device: dev.name,
            scale: scale,
            keyboardOpen: false,
            passed: passed,
            errorMessage: overflowError,
          );
        });
      }
    }
  });

  group('Group B - HomeHeader Matrix', () {
    for (final dev in testDevices) {
      for (final scale in testScales) {
        testWidgets('${dev.name} @ ${scale}x', (tester) async {
          String? overflowError;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            final msg = details.exceptionAsString();
            if (msg.contains('overflow') || msg.contains('RenderFlex')) {
              overflowError = msg;
            }
          };

          await tester.binding.setSurfaceSize(dev.size);
          await tester.pumpWidget(buildTestHarness(
            size: dev.size,
            textScale: scale,
            child: HomeHeader(
              userName: 'Nguyễn Văn Định Mệnh Rất Dài',
              userHandle: '@dinhmenh2026_superlong',
              onSearchTap: () {},
            ),
          ));
          await tester.pump();

          FlutterError.onError = prevOnError;

          final passed = overflowError == null;
          recordResult(
            component: 'HomeHeader',
            device: dev.name,
            scale: scale,
            keyboardOpen: false,
            passed: passed,
            errorMessage: overflowError,
          );
        });
      }
    }
  });

  group('Group B - SoulMatchCard Matrix', () {
    for (final dev in testDevices) {
      for (final scale in testScales) {
        testWidgets('${dev.name} @ ${scale}x', (tester) async {
          String? overflowError;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            final msg = details.exceptionAsString();
            if (msg.contains('overflow') || msg.contains('RenderFlex')) {
              overflowError = msg;
              debugPrint('SOULMATCH OVERFLOW: $msg\n${details.informationCollector?.call().map((e) => e.toString()).join("\n")}');
            }
          };

          await tester.binding.setSurfaceSize(dev.size);
          await tester.pumpWidget(buildTestHarness(
            size: dev.size,
            textScale: scale,
            child: SingleChildScrollView(
              child: SoulMatchCard(user: dummyUser),
            ),
          ));
          await tester.pump();

          FlutterError.onError = prevOnError;

          final passed = overflowError == null;
          recordResult(
            component: 'SoulMatchCard',
            device: dev.name,
            scale: scale,
            keyboardOpen: false,
            passed: passed,
            errorMessage: overflowError,
          );
        });
      }
    }
  });

  group('Group B - CustomBottomNavBar Matrix', () {
    for (final dev in testDevices) {
      for (final scale in testScales) {
        testWidgets('${dev.name} @ ${scale}x', (tester) async {
          String? overflowError;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            final msg = details.exceptionAsString();
            if (msg.contains('overflow') || msg.contains('RenderFlex')) {
              overflowError = msg;
            }
          };

          await tester.binding.setSurfaceSize(dev.size);
          await tester.pumpWidget(buildTestHarness(
            size: dev.size,
            textScale: scale,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: CustomBottomNavBar(
                currentIndex: 0,
                onTap: (_) {},
              ),
            ),
          ));
          await tester.pump();

          FlutterError.onError = prevOnError;

          final passed = overflowError == null;
          recordResult(
            component: 'CustomBottomNavBar',
            device: dev.name,
            scale: scale,
            keyboardOpen: false,
            passed: passed,
            errorMessage: overflowError,
          );
        });
      }
    }
  });

  group('Group B - ChatInputBar Matrix (Keyboard Closed & Open)', () {
    for (final dev in testDevices) {
      for (final scale in testScales) {
        for (final isKeyboard in [false, true]) {
          testWidgets('${dev.name} @ ${scale}x KB:${isKeyboard ? "Open" : "Closed"}', (tester) async {
            String? overflowError;
            final prevOnError = FlutterError.onError;
            FlutterError.onError = (details) {
              final msg = details.exceptionAsString();
              if (msg.contains('overflow') || msg.contains('RenderFlex')) {
                overflowError = msg;
              }
            };

            await tester.binding.setSurfaceSize(dev.size);
            await tester.pumpWidget(buildTestHarness(
              size: dev.size,
              textScale: scale,
              viewInsets: isKeyboard ? const EdgeInsets.only(bottom: 280) : EdgeInsets.zero,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ChatInputBar(
                  controller: TextEditingController(),
                  onSubmitted: (_) {},
                ),
              ),
            ));
            await tester.pump();

            FlutterError.onError = prevOnError;

            final passed = overflowError == null;
            recordResult(
              component: 'ChatInputBar',
              device: dev.name,
              scale: scale,
              keyboardOpen: isKeyboard,
              passed: passed,
              errorMessage: overflowError,
            );
          });
        }
      }
    }
  });

  group('Group B - SettingsDistanceBottomSheet Matrix', () {
    for (final dev in testDevices) {
      for (final scale in testScales) {
        testWidgets('${dev.name} @ ${scale}x', (tester) async {
          String? overflowError;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            final msg = details.exceptionAsString();
            if (msg.contains('overflow') || msg.contains('RenderFlex')) {
              overflowError = msg;
            }
          };

          await tester.binding.setSurfaceSize(dev.size);
          await tester.pumpWidget(buildTestHarness(
            size: dev.size,
            textScale: scale,
            child: const Align(
              alignment: Alignment.bottomCenter,
              child: SettingsDistanceBottomSheet(currentValue: 'Chỉ hiện khu vực'),
            ),
          ));
          await tester.pump();

          FlutterError.onError = prevOnError;

          final passed = overflowError == null;
          recordResult(
            component: 'SettingsDistanceBottomSheet',
            device: dev.name,
            scale: scale,
            keyboardOpen: false,
            passed: passed,
            errorMessage: overflowError,
          );
        });
      }
    }
  });

  // -------------------------------------------------------------
  // GROUP (C) CÒN LẠI
  // -------------------------------------------------------------
  group('Group C - OnboardingScreen Matrix', () {
    for (final dev in testDevices) {
      for (final scale in testScales) {
        testWidgets('${dev.name} @ ${scale}x', (tester) async {
          String? overflowError;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            final msg = details.exceptionAsString();
            if (msg.contains('overflow') || msg.contains('RenderFlex')) {
              overflowError = msg;
            }
          };

          await tester.binding.setSurfaceSize(dev.size);
          await tester.pumpWidget(buildTestHarness(
            size: dev.size,
            textScale: scale,
            child: const OnboardingScreen(),
          ));
          await tester.pump();

          FlutterError.onError = prevOnError;

          final passed = overflowError == null;
          recordResult(
            component: 'OnboardingScreen',
            device: dev.name,
            scale: scale,
            keyboardOpen: false,
            passed: passed,
            errorMessage: overflowError,
          );
        });
      }
    }
  });

  group('Group C - AppMenuDrawer Matrix', () {
    for (final dev in testDevices) {
      for (final scale in testScales) {
        testWidgets('${dev.name} @ ${scale}x', (tester) async {
          String? overflowError;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            final msg = details.exceptionAsString();
            if (msg.contains('overflow') || msg.contains('RenderFlex')) {
              overflowError = msg;
            }
          };

          await tester.binding.setSurfaceSize(dev.size);
          await tester.pumpWidget(buildTestHarness(
            size: dev.size,
            textScale: scale,
            child: const Align(
              alignment: Alignment.centerRight,
              child: AppMenuDrawer(),
            ),
          ));
          await tester.pump();

          FlutterError.onError = prevOnError;

          final passed = overflowError == null;
          recordResult(
            component: 'AppMenuDrawer',
            device: dev.name,
            scale: scale,
            keyboardOpen: false,
            passed: passed,
            errorMessage: overflowError,
          );
        });
      }
    }
  });
}

extension StringExtension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
