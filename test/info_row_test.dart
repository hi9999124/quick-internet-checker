import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quick_internet_checker/widgets/info_section.dart';

// NOTE: flutter_test renders with a placeholder font where every glyph is a
// full em wide — far wider than the real UI font. Widths below are chosen
// against those metrics, so they look generous for the strings involved.

Widget _host({required double width, required double textScale, required Widget child}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

/// True when the label and value ended up side by side on a single line.
bool _isSingleLine(WidgetTester tester, String label, String value) {
  final labelRect = tester.getRect(find.text(label));
  final valueRect = tester.getRect(find.text(value));
  return (labelRect.center.dy - valueRect.center.dy).abs() < 2;
}

void main() {
  testWidgets('keeps label and value on one line when they fit', (tester) async {
    await tester.pumpWidget(_host(
      width: 320,
      textScale: 1.0,
      child: const InfoRow(label: 'Ping', value: '12 ms'),
    ));

    expect(_isSingleLine(tester, 'Ping', '12 ms'), isTrue,
        reason: 'a short pair with room to spare should stay on one line');
  });

  testWidgets('stacks label above value when one line would not fit', (tester) async {
    const label = 'Ping';
    const value = '12 ms';
    await tester.pumpWidget(_host(
      width: 320,
      textScale: 3.0,
      child: const InfoRow(label: label, value: value),
    ));

    expect(_isSingleLine(tester, label, value), isFalse,
        reason: 'once scaled up the pair must stack instead of clipping');

    // The value stays inside the row rather than being clipped mid-word,
    // which is what produced the "Onli/ne" rendering on the reported device.
    expect(tester.getRect(find.text(value)).width, lessThanOrEqualTo(320));
  });

  testWidgets('stacks a long value rather than truncating it', (tester) async {
    const label = 'ISP';
    const longValue = 'Deutsche Telekom AG Broadband';
    await tester.pumpWidget(_host(
      width: 300,
      textScale: 1.0,
      child: const InfoRow(label: label, value: longValue),
    ));

    expect(_isSingleLine(tester, label, longValue), isFalse);
    expect(tester.getRect(find.text(longValue)).width, lessThanOrEqualTo(300));
  });
}
