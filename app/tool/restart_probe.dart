import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;
import 'package:grpc/grpc.dart';

import 'package:iq_task_app/src/generated/task.pbgrpc.dart';
import 'package:iq_task_app/src/generated/task.pb.dart';

Future<void> main() async {
  final cert = File('/Users/sobogd/work/certs/iq-task.crt').readAsBytesSync();
  final token = _env('IQ_WORK_TOKEN');
  final meta = <String, String>{'x-iq-token': token};

  final der = base64Decode(cert
      .map((b) => String.fromCharCode(b))
      .join()
      .replaceAll(RegExp('-----BEGIN CERTIFICATE-----|-----END CERTIFICATE-----'), '')
      .replaceAll(RegExp(r'\s'), ''));
  final pin = crypto.sha256.convert(der).toString();
  ClientChannel ch() => ClientChannel(
        '46.225.143.221',
        port: 46001,
        options: ChannelOptions(
          credentials: ChannelCredentials.secure(
            onBadCertificate: (c, host) =>
                crypto.sha256.convert(c.der).toString() == pin),
        ));

  final c1 = ch();
  HarnessClient stub1 = HarnessClient(c1);

  for (var i = 1; i <= 2; i++) {
    await _call(stub1, meta, i);
  }
  print('RESTART NOW');
  await Future.delayed(Duration(seconds: 4));
  for (var i = 3; i <= 8; i++) {
    await _call(stub1, meta, i);
    await Future.delayed(const Duration(seconds: 1));
  }
  exit(0);
}

String _env(String k) {
  for (final l in File('/Users/sobogd/work/.env').readAsLinesSync()) {
    if (l.startsWith('$k=')) return l.split('=').sublist(1).join('=').trim();
  }
  return '';
}

Future<void> _call(HarnessClient stub, Map<String, String> meta, int i) async {
  try {
    final r = await stub.listSessions(ListRequest(), options: CallOptions(metadata: meta));
    print('$i OK sessions=${r.sessions.length}');
  } catch (e) {
    print('$i ERR $e');
  }
}
