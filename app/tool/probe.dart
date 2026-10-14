import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:grpc/grpc.dart';

import '../lib/src/generated/task.pb.dart';
import '../lib/src/generated/task.pbgrpc.dart';

Future<void> main(List<String> args) async {
  final host = args.isNotEmpty ? args[0] : '46.225.143.221';
  final token = args.length > 1 ? args[1] : '';
  final cert = File('assets/iq-task.crt').readAsBytesSync();
  final der = base64Decode(RegExp(
          r'-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----',
          dotAll: true)
      .firstMatch(utf8.decode(cert))!
      .group(1)!
      .replaceAll(RegExp(r'\s'), ''));
  final pinned = sha256.convert(der).toString();
  final channel = ClientChannel(
    host,
    port: 46001,
    options: ChannelOptions(
      credentials: ChannelCredentials.secure(
        onBadCertificate: (c, h) =>
            sha256.convert(c.der).toString() == pinned,
      ),
    ),
  );
  final stub = HarnessClient(channel);
  final md = token.isEmpty ? <String, String>{} : {'x-iq-token': token};
  CallOptions opt() => CallOptions(metadata: md);
  try {
    final p = await stub.ping(PingRequest(), options: opt());
    print('ping ok: ${p.version}');
    final ts = await stub.listTasks(ListRequest(), options: opt());
    print('tasks: ${ts.tasks.length}');
    for (final t in ts.tasks) {
      print('  ${t.id} [${t.status}] ${t.text.substring(0, t.text.length > 50 ? 50 : t.text.length)}');
    }
    final rs = await stub.listRepos(ListRequest(), options: opt());
    print('repos: ${rs.repos.map((r) => r.path).toList()}');
  } catch (e, st) {
    print('FAIL: $e');
    print(st.toString().split('\n').take(6).join('\n'));
  }
  channel.shutdown();
  exit(0);
}