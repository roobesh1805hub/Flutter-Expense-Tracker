import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:auspify_expense_tracker/main.dart';

void main() {
  testWidgets('Expense Tracker screen loads correctly', (tester) async {
    // Set a larger screen size for this widget test.
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const ExpenseTrackerApp());

    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.text('Total Expenses'), findsOneWidget);
    expect(find.text('Recent Expenses'), findsOneWidget);
    expect(find.text('Spending by Category'), findsOneWidget);
  });
}
