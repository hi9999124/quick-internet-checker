import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quick_internet_checker/app.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Taps a bottom-nav tab by key — its label collides with page titles
/// ("Settings", "History") when matched by text.
Future<void> _tapTab(WidgetTester tester, String tab) async {
  await tester.tap(find.byKey(ValueKey('nav-$tab')));
  await _settle(tester);
}

/// Taps something inside a scrolling page, scrolling it into view first —
/// at large font scales the target is often below the fold.
Future<void> _tapInList(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

/// These screens use their own back icon rather than an AppBar, so
/// [WidgetTester.pageBack] can't find a button to press.
Future<void> _goBack(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
  await _settle(tester);
}

/// Walks every tab and pushed page. Any RenderFlex overflow raises a
/// FlutterError, which fails the enclosing test — that's the assertion.
Future<void> _visitEveryScreen(WidgetTester tester) async {
  await tester.pumpWidget(const QicApp());
  await _settle(tester);

  for (final tab in ['Network', 'History', 'Settings', 'About', 'Test']) {
    await _tapTab(tester, tab);
  }

  // Home -> Full network report, which fans out into the densest layout.
  await _tapInList(tester, 'View full network report');
  await _goBack(tester);

  // Settings -> Statistics / Device info.
  for (final page in ['Statistics', 'Device info']) {
    await _tapTab(tester, 'Settings');
    await _tapInList(tester, page);
    await _goBack(tester);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('QIC app boots and shows the home tab', (WidgetTester tester) async {
    await tester.pumpWidget(const QicApp());
    await tester.pump();

    expect(find.text('QIC'), findsWidgets);
    expect(find.text('START TEST'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const QicApp());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('nav-Settings')));
    await tester.pump();

    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('every screen lays out on a small phone at default font scale',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await _visitEveryScreen(tester);
  });

  testWidgets('every screen lays out at a large system font scale',
      (WidgetTester tester) async {
    // Reproduces the reported bug: a device with the system font size turned
    // well up used to clip labels ("DNS lookup t…") and hyphenate values
    // mid-word ("Onli/ne") on the report and snapshot cards.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _visitEveryScreen(tester);
  });

  testWidgets('every screen lays out on a narrow phone at a large font scale',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(720, 1520);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _visitEveryScreen(tester);
  });
}
