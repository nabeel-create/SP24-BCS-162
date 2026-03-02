import 'package:dice_roller_plus/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Dice app renders title', (WidgetTester tester) async {
    await tester.pumpWidget(const DiceApp());

    expect(find.text('Dice Roller'), findsOneWidget);
    expect(find.text('Roll Dice'), findsOneWidget);
  });
}
