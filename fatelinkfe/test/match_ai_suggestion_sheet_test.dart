import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fatelinkfe/presentation/screens/match/widgets/match_ai_suggestion_sheet.dart';

void main() {
  group('MatchAiSuggestionSheet Widget Tests', () {
    testWidgets('renders header, quote card, and handles suggestion tap',
        (tester) async {
      String? selectedText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchAiSuggestionSheet(
              partnerName: 'Ngọc Ánh',
              lastPartnerMessage: 'Hôm nay đi làm về mệt quá cậu ơi...',
              onSelectSuggestion: (text) {
                selectedText = text;
              },
            ),
          ),
        ),
      );

      // Verify header rendered
      expect(find.text('Faye AI gợi ý câu trả lời:'), findsOneWidget);
      expect(find.textContaining('Ngọc Ánh'), findsWidgets);

      // Verify partner quote is visible
      expect(find.textContaining('Hôm nay đi làm về mệt quá cậu ơi...'), findsOneWidget);

      // Pump to let the contextual fallbacks populate (or timer finish)
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Tap the first suggestion
      final suggestionFinder = find.byIcon(Icons.touch_app_rounded);
      expect(suggestionFinder, findsWidgets);

      await tester.tap(suggestionFinder.first);
      await tester.pump();

      expect(selectedText, isNotNull);
      expect(selectedText!.isNotEmpty, isTrue);
    });
  });
}
