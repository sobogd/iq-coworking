import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:grpc/grpc.dart';

import '../lib/src/generated/task.pb.dart';
import '../lib/src/generated/task.pbgrpc.dart';

Future<void> main() async {
  const home = '/Users/sobogd';
  String token = '';
  for (final l in File('/Users/sobogd/work/.env').readAsLinesSync()) {
    if (l.startsWith('IQ_WORK_TOKEN=')) {
      token = l.substring(l.indexOf('=') + 1).trim();
    }
  }
  final pem = File('assets/iq-task.crt').readAsBytesSync();
  final text = utf8.decode(pem, allowMalformed: true);
  final m = RegExp(
    r'-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----',
    dotAll: true,
  ).firstMatch(text)!;
  final der =
      Uint8List.fromList(
        base64Decode(m.group(1)!.replaceAll(RegExp(r'\s'), '')),
      );
  final sha = crypto.sha256.convert(der).toString();
  final meta = <String, String>{'x-iq-token': token};
  final ch = ClientChannel(
    '46.225.143.221',
    port: 46001,
    options: ChannelOptions(
      credentials: ChannelCredentials.secure(
        onBadCertificate: (
          X509Certificate c,
          String host,
        ) =>
            crypto.sha256.convert(c.der).toString() == sha,
      ),
    ),
  );
  final stub = HarnessClient(ch);
  final tasks =
      (await stub.listTasks(ListRequest(), options: CallOptions(metadata: meta)))
          .tasks;
  print('tasks: ${tasks.length}');
  for (final t in tasks) {
    print('-- ${t.id} ${t.mode} ${t.status}');
    final sw = Stopwatch()..start();
    final a = await stub.getActivity(
      TaskRef(id: t.id),
      options: CallOptions(metadata: meta),
    );
    sw.stop();
    print('  activity: ${a.messages.length} msgs in ${sw.elapsedMilliseconds}ms');
    for (final msg in a.messages.take(4)) {
      final c = msg.content.replaceAll('\n', ' ');
      print('  [${msg.role}] ${c.substring(0, c.length > 60 ? 60 : c.length)}');
    }
  }
  ch.shutdown();
  exit(0);
}
