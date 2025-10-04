// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rupaya/main.dart';

void main() {
  testWidgets('Language selection screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RupayaApp());

    // Verify that the app title is displayed
    expect(find.text('Rupaya'), findsOneWidget);
    expect(find.text('Manage your money easily'), findsOneWidget);

    // Verify language buttons are present
    expect(find.text('हिंदी'), findsOneWidget);
    expect(find.text('मराठी'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });
}
