import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_of_hymns/main.dart';
import 'package:home_of_hymns/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> boot(WidgetTester tester) async {
  // the app state is a global singleton — reset per test
  app.hymnOpen = null;
  app.view = 'home';
  app.collection = null;
  app.search = '';
  app.jumpOpen = false;
  app.jumpDigits = '';
  SharedPreferences.setMockInitialValues({
    'userInfo': jsonEncode({
      'name': 'Tester',
      'contact': '',
      'church': '',
      'photo': '',
      'enteredAt': 0,
    }),
  });
  await tester.runAsync(() async {
    await tester.pumpWidget(const HoHApp());
    await Future<void>.delayed(const Duration(milliseconds: 3500));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('digit key opens jump dialog', (tester) async {
    await boot(tester);

    expect(find.byType(Dialog), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Jump to hymn number'), findsOneWidget);
    expect(app.jumpOpen, isTrue);
  });

  testWidgets('Enter submits the jump dialog and opens the hymn',
      (tester) async {
    await boot(tester);

    final target = app.data.hymns.firstWhere(
        (h) => int.tryParse(app.hymnNo(h)) != null);
    final num = app.hymnNo(target);

    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)), num);
    await tester.pumpAndSettle();
    expect(app.jumpOpen, isTrue);

    // the fix: shell forwards Enter to the dialog's registered submit
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Dialog), findsNothing,
        reason: 'Enter must dismiss the jump dialog');
    expect(app.jumpOpen, isFalse);
    expect(app.hymnOpen, target.id,
        reason: 'Enter must open the matched hymn');
  });

  testWidgets('Enter on a bad number dismisses with a toast', (tester) async {
    await boot(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit9);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)), '99999');
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(app.jumpOpen, isFalse);
    expect(app.hymnOpen, isNull);
  });

  testWidgets('Esc closes the jump dialog without opening a hymn',
      (tester) async {
    await boot(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(app.hymnOpen, isNull);
  });
}
