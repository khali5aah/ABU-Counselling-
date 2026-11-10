import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chdc_counselling/widgets/error_banner.dart';

void main() {
  testWidgets('wraps the full account validation error on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const message = 'Please correct the highlighted fields.';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(24),
            child: ErrorBanner(message: message),
          ),
        ),
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byType(ErrorBanner),
        matching: find.text(message),
      ),
    );
    expect(paragraph.size.height, greaterThan(paragraph.preferredLineHeight));
    expect(tester.takeException(), isNull);
  });
}
