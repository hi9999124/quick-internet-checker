import 'package:flutter_test/flutter_test.dart';

import 'package:quick_internet_checker/app.dart';

void main() {
  testWidgets('QIC app boots and shows the home tab', (WidgetTester tester) async {
    await tester.pumpWidget(const QicApp());
    await tester.pump();

    expect(find.text('QIC'), findsWidgets);
    expect(find.text('START TEST'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const QicApp());
    await tester.pump();

    await tester.tap(find.text('Settings'));
    await tester.pump();

    expect(find.text('Appearance'), findsOneWidget);
  });
}
