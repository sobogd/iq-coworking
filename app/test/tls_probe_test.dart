import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

Future<void> run(String label, SecurityContext? ctx,
    {bool Function(dynamic)? onBad}) async {
  try {
    final s = await SecureSocket.connect('46.225.143.221', 46001,
        context: ctx, onBadCertificate: onBad)
        .timeout(const Duration(seconds: 15));
    print('$label: OK');
    s.destroy();
  } catch (e) {
    print('$label: FAILED: $e');
  }
}

Future<void> main() async {
  final pemBytes = File('assets/iq-task.crt').readAsBytesSync();
  final text = utf8.decode(pemBytes, allowMalformed: true);
  final der = base64Decode(RegExp(
          r'-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----',
          dotAll: true)
      .firstMatch(text)!
      .group(1)!
      .replaceAll(RegExp(r'\s'), ''));
  final pinned = sha256.convert(der).toString();
  print('pinned sha256(der) = $pinned');

  final ctx = SecurityContext();
  try {
    ctx.setTrustedCertificatesBytes(pemBytes);
    print('setTrustedCertificatesBytes: ok');
  } catch (e) {
    print('setTrustedCertificatesBytes FAILED: $e');
  }

  await run('case1 trusted-bytes, no callback', ctx);
  await run('case2 default ctx + onBadCertificate', null,
      onBad: (c) {
        final h = sha256.convert((c as dynamic).der as dynamic).toString();
        print('  callback: sha256(der)=${h} match=${h == pinned}');
        return h == pinned;
      });
  await run('case3 trusted-bytes + onBadCertificate', ctx,
      onBad: (c) {
        final h = sha256.convert((c as dynamic).der as dynamic).toString();
        return h == pinned;
      });
}
