import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fatelinkfe/presentation/screens/chat/widgets/chat_conversation_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestTile({
    required double width,
    required double textScaleFactor,
    required String name,
    required String lastMessage,
    String time = 'Vừa xong',
    int unreadCount = 0,
    int? age = 24,
    String? gender = 'female',
    double? meyuFeelProgress = 0.35,
    bool isBot = false,
    bool isSystem = false,
    bool isWaveRequest = false,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(textScaleFactor),
        ),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: ChatConversationTile(
                name: name,
                lastMessage: lastMessage,
                time: time,
                unreadCount: unreadCount,
                age: age,
                gender: gender,
                meyuFeelProgress: meyuFeelProgress,
                isBot: isBot,
                isSystem: isSystem,
                isWaveRequest: isWaveRequest,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('ChatConversationTile Responsiveness & Zero Overflow Tests', () {
    final widths = [320.0, 360.0, 390.0, 412.0];
    final textScales = [1.0, 1.3];

    for (final width in widths) {
      for (final scale in textScales) {
        testWidgets(
          'Render test at width: ${width}dp, textScale: $scale without overflow',
          (tester) async {
            tester.view.physicalSize = Size(width * 2, 800 * 2);
            tester.view.devicePixelRatio = 2.0;
            addTearDown(() => tester.view.resetPhysicalSize());

            await tester.pumpWidget(
              buildTestTile(
                width: width,
                textScaleFactor: scale,
                name: 'TRAN VAN ANH',
                lastMessage: 'Trao đổi thông tin tuyển dụng',
                time: 'Vừa xong',
                unreadCount: 0,
                age: 24,
                gender: 'female',
                meyuFeelProgress: 0.35,
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 50));

            expect(tester.takeException(), isNull);
            expect(find.text('TRAN VAN ANH'), findsOneWidget);
            expect(find.text('Trao đổi thông tin tuyển dụng'), findsOneWidget);
          },
        );
      }
    }

    testWidgets(
      'TRAN VAN ANH at width 360dp, textScale 1.0 does not clip or overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360 * 2, 800 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildTestTile(
            width: 360,
            textScaleFactor: 1.0,
            name: 'TRAN VAN ANH',
            lastMessage: 'Trao đổi thông tin tuyển dụng',
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(tester.takeException(), isNull);

        // Kiểm tra RenderParagraph của Tên không bị exceeded maxLines ở 360dp
        final nameFinder = find.text('TRAN VAN ANH');
        expect(nameFinder, findsOneWidget);

        final textWidget = tester.widget<Text>(nameFinder);
        expect(textWidget.data, 'TRAN VAN ANH');
        expect(textWidget.maxLines, 1);
      },
    );

    testWidgets(
      'Unread count > 0 shows badge, unread count = 0 does not reserve empty space',
      (tester) async {
        // Tile có unreadCount = 3
        await tester.pumpWidget(
          buildTestTile(
            width: 360,
            textScaleFactor: 1.0,
            name: 'Max Veo',
            lastMessage: 'Xin chào bạn nhé',
            unreadCount: 3,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('3'), findsOneWidget);

        // Tile có unreadCount = 0: không có text số chưa đọc
        await tester.pumpWidget(
          buildTestTile(
            width: 360,
            textScaleFactor: 1.0,
            name: 'Max Veo',
            lastMessage: 'Đã kết đôi • Mở khóa trò chuyện vĩnh viễn 💕',
            unreadCount: 0,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.text('3'), findsNothing);
        expect(find.text('Đã kết đôi • Mở khóa trò chuyện vĩnh viễn 💕'), findsOneWidget);
      },
    );
  });
}
