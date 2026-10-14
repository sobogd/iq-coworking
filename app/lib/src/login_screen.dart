import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';

import 'auth.dart';
import 'harness.dart';

class LoginScreen extends StatefulWidget {
  final AuthStore auth;
  final Harness harness;

  const LoginScreen({super.key, required this.auth, required this.harness});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _host = TextEditingController(text: AuthStore.defaultHost);
  final _token = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _host.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final host = _host.text.trim();
    final token = _token.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Введите токен');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      widget.auth.host = host;
      await widget.harness.ensureConnected(host);
      widget.auth.token = token;
      widget.auth.expiresAt = null;
      widget.harness.token = token;
      await widget.harness.ping();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/sessions', (_) => false);
    } on GrpcError catch (e) {
      setState(() => _error = 'GPRC: ${e.message}');
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.hub, size: 64, color: Colors.indigoAccent),
                const SizedBox(height: 12),
                Text('IQ Task',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _host,
                  decoration: const InputDecoration(labelText: 'Host'),
                  autocorrect: false,
                  enabled: !_busy,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _token,
                  decoration: const InputDecoration(labelText: 'Токен'),
                  obscureText: true,
                  autocorrect: false,
                  enabled: !_busy,
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Войти'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
