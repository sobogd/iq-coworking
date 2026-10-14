import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iq_task_app/main.dart';
import 'package:iq_task_app/src/auth.dart';

void main() {
  testWidgets('login screen renders', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    auth = AuthStore(await SharedPreferences.getInstance());
    await tester.pumpWidget(const App());
    expect(find.text('IQ Task'), findsOneWidget);
    expect(find.text('Host'), findsOneWidget);
    expect(find.text('Токен'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
  });
}
