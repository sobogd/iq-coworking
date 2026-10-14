import 'dart:async';
import 'dart:convert';
import 'dart:io';

void log(String s) =>
    File('/tmp/iq_vm_events.log').writeAsStringSync('$s\n',
        mode: FileMode.append, flush: true);

Future<void> main() async {
  final ws = await WebSocket.connect('ws://127.0.0.1:50150/5hRep7kSVok=/');
  int id = 0;
  final pending = <int, Completer<dynamic>>{};
  Future<dynamic> send(String m, [Map<String, dynamic>? p]) async {
    final myId = ++id;
    final c = Completer<dynamic>();
    pending[myId] = c;
    ws.add(jsonEncode({'jsonrpc': '2.0', 'id': myId, 'method': m, 'params': p ?? {}}));
    return c.future;
  }
  ws.listen((data) {
    final s = data as String;
    log('RAW ${s.length > 400 ? s.substring(0, 400) : s}');
    try {
      final obj = jsonDecode(s) as Map<String, dynamic>;
      if (obj['id'] != null) {
        pending.remove(obj['id'] as int)?.complete(obj['result']);
        return;
      }
      if (obj['method'] == 'streamNotify') {
        final n = obj['params'] as Map<String, dynamic>;
        if (n['stream'] == 'Console' || n['stream'] == 'Stdout') {
          log('CONSOLE ${n['output']}');
        }
      }
    } catch (_) {}
  });
  try {
    for (final s in ['Console', 'Stdout', 'Stderr']) {
      await send('streamListen', {'streamId': s});
    }
    log('streamListen ok');
  } catch (e) {
    log('streamListen FAIL $e');
  }
  await Future.delayed(const Duration(seconds: 600));
}
