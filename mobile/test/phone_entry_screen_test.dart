import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chdc_counselling/config/routes.dart';
import 'package:chdc_counselling/core/api/api_client.dart';
import 'package:chdc_counselling/core/api/mock_api_client.dart';
import 'package:chdc_counselling/core/storage/token_storage.dart';
import 'package:chdc_counselling/features/auth/screens/otp_screen.dart';
import 'package:chdc_counselling/features/auth/screens/phone_entry_screen.dart';

void main() {
  testWidgets('validates phone number and opens OTP screen on success',
      (tester) async {
    final storage = InMemoryTokenStorage();
    final api = MockApiClient(storage);

    await tester.pumpWidget(
      Provider<ApiClient>.value(
        value: api,
        child: MaterialApp(
          home: const PhoneEntryScreen(),
          onGenerateRoute: (settings) {
            if (settings.name == Routes.otp) {
              return MaterialPageRoute<void>(
                builder: (_) => OtpScreen(
                  args: settings.arguments! as OtpArgs,
                ),
              );
            }
            return null;
          },
        ),
      ),
    );

    // Test invalid phone number validation
    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(
      find.text('Enter a valid phone number for Nigeria.'),
      findsOneWidget,
    );

    // Test valid phone number submission
    await tester.enterText(find.byType(TextField), '0803 123 4567');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();

    expect(find.text('Verify Code'), findsOneWidget);
  });
}