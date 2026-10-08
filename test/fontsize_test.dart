import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_of_hymns/main.dart';
import 'package:home_of_hymns/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> boot(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      await tester.pumpWidget(const HoHApp());
      await Future<void>.delayed(const Duration(milliseconds: 3500));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // gate only opens while no profile is set (app is a global singleton)
    if (find.text('Enter').evaluate().isEmpty) return;
    await tester.enterText(
        find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)).first,
        'Tester');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Enter'));
    await tester.pumpAndSettle();
    // let the welcome snackbar (2s) disappear so it doesn't obscure controls
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('settings text size control updates the preview', (tester) async {
    await boot(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Text size'), findsOneWidget);

    final before = app.fontSize;
    expect(find.text('$before px'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(app.fontSize, before + 1);
    expect(find.text('${before + 1} px'), findsOneWidget,
        reason: 'settings label must rebuild after setFontSize');
  });

  testWidgets('settings slider sets the font size', (tester) async {
    await boot(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    final slider = find.byType(Slider);
    expect(slider, findsOneWidget);
    await tester.drag(slider, const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(app.fontSize, greaterThan(19));
    expect(find.text('${app.fontSize} px'), findsOneWidget);
  });

  testWidgets('player A+ button resizes hymn lyrics', (tester) async {
    await boot(tester);

    // open first hymn from the Hymns list
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Amazing').first);
    await tester.pumpAndSettle();

    final before = app.fontSize;
    await tester.tap(find.text('A+'));
    await tester.pumpAndSettle();

    expect(app.fontSize, before + 2);
    final sized = find.byWidgetPredicate(
        (w) => w is Text && w.style?.fontSize == app.fontSize.toDouble());
    // lyric lines are lazily built below the fold — drag until one appears
    final list = find.byWidgetPredicate(
        (w) => w is ListView && w.controller != null); // player's lyrics list
    expect(list, findsOneWidget);
    for (var i = 0; i < 20 && sized.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -250));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(sized, findsWidgets,
        reason: 'lyric lines must rebuild with the new font size');
  });
}
