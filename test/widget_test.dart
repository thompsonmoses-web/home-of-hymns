import 'package:flutter_test/flutter_test.dart';
import 'package:home_of_hymns/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots to shell with gate dialog', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.runAsync(() async {
      await tester.pumpWidget(const HoHApp());
      // real time for asset loading + the 1100ms splash minimum
      await Future<void>.delayed(const Duration(milliseconds: 3500));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('Home of Hymns'), findsWidgets);
    // first launch requires the entry gate
    expect(find.text('Enter'), findsOneWidget);
  });
}
