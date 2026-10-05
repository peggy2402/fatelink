import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fatelinkfe/presentation/screens/chat/widgets/meyufeel_liquid_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget(double progress) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: MeyuFeelLiquidText(
            progress: progress,
            fontSize: 14.0,
            text: 'MEYUFEEL',
          ),
        ),
      ),
    );
  }

  group('MeyuFeelLiquidText Progress States Tests', () {
    for (final progress in [0.0, 0.35, 0.7, 1.0]) {
      testWidgets('Renders cleanly at progress = $progress', (tester) async {
        await tester.pumpWidget(buildTestWidget(progress));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);
        expect(find.text('MEYUFEEL'), findsOneWidget);

        // Đảm bảo không có icon 🪷 hoặc Container viền
        expect(find.text('🪷'), findsNothing);
      });
    }
  });
}
