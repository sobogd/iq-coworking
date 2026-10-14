import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/auth.dart';
import 'src/harness.dart';
import 'src/login_screen.dart';
import 'src/session_screen.dart';
import 'src/sessions_screen.dart';

final harness = Harness();
late final AuthStore auth;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  auth = AuthStore(await SharedPreferences.getInstance());
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IQ Cowork',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      routes: {
        '/': (context) => LoginScreen(auth: auth, harness: harness),
        '/sessions': (context) => SessionsScreen(auth: auth, harness: harness),
        '/session': (context) => SessionDetailScreen(
              auth: auth,
              harness: harness,
              id: ModalRoute.of(context)!.settings.arguments as String,
            ),
      },
    );
  }
}
