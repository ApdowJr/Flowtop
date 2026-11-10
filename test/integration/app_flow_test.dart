import 'package:flutter_test/flutter_test.dart';
import 'package:flowtop/main.dart';

void main() {
  testWidgets('App launches and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FlowTopApp());
    await tester.pumpAndSettle();
    // The splash screen brand is rendered.
    expect(find.text('flowTop'), findsOneWidget);
  });
}
