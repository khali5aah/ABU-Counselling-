import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('app starts on the welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CrownbirdApp());

    expect(find.text('Crownbird E-Counselling'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
