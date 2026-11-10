import 'package:flutter_test/flutter_test.dart';
import 'package:chdc_counselling/config/env.dart';

void main() {
  test('uses the live backend unless mock mode is explicitly enabled', () {
    expect(Env.useMock, isFalse);
  });
}
