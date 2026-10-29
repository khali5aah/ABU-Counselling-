import 'package:chdc_counselling/main.dart'; // or your matching package name
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const ChdcApp());
    expect(find.byType(ChdcApp), findsOneWidget);
  });
}