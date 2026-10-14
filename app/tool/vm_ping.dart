import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final ws = await WebSocket.connect('ws://127.0.0.1:50150/5hRep7kSVok=/');
  int id = 0;
  final pending = <int, Completer<dynamic>>{};
  ws.listen((data) {
    final obj = jsonDecode(data as String) as Map<String, dynamic>;
    final oid = obj['id'];
    if (oid != null) {
      pending.remove(oid as int)?.complete(obj['result']);
      return;
    }
    if (obj['method'] == 'streamNotify') {
      final n = obj['params'] as Map<String, dynamic>;
      stderr.writeln('STREAM ${n['stream']}: ${n['output']}');
    }
  });
  Future<dynamic> send(String m, [Map<String, dynamic>? p]) async {
    final myId = ++id;
    final c = Completer<dynamic>();
    pending[myId] = c;
    ws.add(jsonEncode({'jsonrpc': '2.0', 'id': myId, 'method': m, 'params': p ?? {}}));
    return c.future;
  }
  print('streamListen -> ${jsonEncode(await send('streamListen', {'streams': ['Console', 'Stdout']}))}');
  final isos = await send('getIsolates') as Map<String, dynamic>;
  final iso = (isos['result'] as List).firstWhere((e) => e['isMain'] == true);
  print('main isolate: ${iso['id']}');
  print('evaluate -> ${jsonEncode(await send('evaluate', {'isolateId': iso['id'], 'expression': "print('PING_FROM_TOOL')"}))}');
  await Future.delayed(const Duration(seconds: 10));
  print('done');
}
