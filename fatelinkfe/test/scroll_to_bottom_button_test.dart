import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Scroll to bottom button appears on scroll up and handles tap',
      (tester) async {
    final scrollController = ScrollController();
    bool isNearBottom = true;
    int unreadCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              scrollController.addListener(() {
                final near = scrollController.offset <= 50.0;
                if (near != isNearBottom) {
                  setState(() => isNearBottom = near);
                }
              });

              return Stack(
                children: [
                  ListView.builder(
                    controller: scrollController,
                    reverse: true,
                    itemCount: 50,
                    itemBuilder: (_, index) => ListTile(
                      title: Text('Message $index'),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 16,
                    child: AnimatedScale(
                      scale: !isNearBottom ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: isNearBottom,
                        child: InkWell(
                          onTap: () {
                            scrollController.jumpTo(0.0);
                            setState(() {
                              isNearBottom = true;
                              unreadCount = 0;
                            });
                          },
                          child: Container(
                            key: const Key('scroll_to_bottom_btn'),
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Initial state: at bottom, scale should be 0.0
    expect(find.byKey(const Key('scroll_to_bottom_btn')), findsOneWidget);

    // Scroll up (in reverse ListView, offset increases)
    scrollController.jumpTo(300.0);
    await tester.pumpAndSettle();

    // Now button is visible and active
    expect(isNearBottom, isFalse);

    // Tap button to scroll back to bottom
    await tester.tap(find.byKey(const Key('scroll_to_bottom_btn')));
    await tester.pumpAndSettle();

    expect(scrollController.offset, 0.0);
    expect(isNearBottom, isTrue);
  });
}
