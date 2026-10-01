import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fatelinkfe/logic/blocs/auth/auth_bloc.dart';
import 'package:fatelinkfe/presentation/screens/login/login_screen.dart';

class MockAuthBloc extends AuthBloc {}

class GoldenDevice {
  final String name;
  final Size size;
  final EdgeInsets safeAreaPadding;

  const GoldenDevice(
    this.name,
    this.size, {
    this.safeAreaPadding = const EdgeInsets.only(top: 44, bottom: 34),
  });
}

const goldenDevices = [
  GoldenDevice('320x568', Size(320, 568), safeAreaPadding: EdgeInsets.only(top: 20, bottom: 0)),
  GoldenDevice('360x640', Size(360, 640), safeAreaPadding: EdgeInsets.only(top: 24, bottom: 0)),
  GoldenDevice('360x760', Size(360, 760), safeAreaPadding: EdgeInsets.only(top: 24, bottom: 24)),
  GoldenDevice('393x852', Size(393, 852), safeAreaPadding: EdgeInsets.only(top: 48, bottom: 34)),
  GoldenDevice('430x932', Size(430, 932), safeAreaPadding: EdgeInsets.only(top: 50, bottom: 34)),
  GoldenDevice('844x390_landscape', Size(844, 390), safeAreaPadding: EdgeInsets.only(left: 44, right: 44, bottom: 21)),
];

const goldenScales = [1.0, 1.3];

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'FateLink',
      packageName: 'com.fatelink.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  for (final dev in goldenDevices) {
    for (final scale in goldenScales) {
      testWidgets('Golden LoginScreen - ${dev.name} @ scale ${scale}x', (tester) async {
        tester.view.physicalSize = dev.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          BlocProvider<AuthBloc>(
            create: (_) => MockAuthBloc(),
            child: MediaQuery(
              data: MediaQueryData(
                size: dev.size,
                textScaler: TextScaler.linear(scale),
                padding: dev.safeAreaPadding,
                viewInsets: EdgeInsets.zero,
              ),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                home: LoginScreen(
                  scrollController: scrollController,
                ),
              ),
            ),
          ),
        );

        // Allow microtasks, layout passes, animations to settle to first frame
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Requirement: at sizes >= 360x760 with scale 1.0, ALL content fits on one screen without scrolling
        final isAtLeast360x760 = (dev.size.width >= 360 && dev.size.height >= 760);
        if (isAtLeast360x760 && scale == 1.0) {
          expect(
            scrollController.hasClients,
            isTrue,
            reason: 'ScrollController should be attached to the SingleChildScrollView',
          );
          expect(
            scrollController.position.maxScrollExtent,
            equals(0.0),
            reason: 'Login content must fit entirely on screen without scrolling at ${dev.name} @ ${scale}x',
          );
        }

        // Golden capture
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/login_${dev.name}_scale_$scale.png'),
        );
      });
    }
  }
}
