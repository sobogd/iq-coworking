import 'dart:convert';
import 'dart:io' show X509Certificate;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/services.dart' show rootBundle;
import 'package:grpc/grpc.dart';

import 'generated/task.pbgrpc.dart';

const defaultPort = 46001;
const authTokenKey = 'x-iq-token';

class Harness {
  static const rpcTimeout = Duration(seconds: 30);
  ClientChannel _channel;
  late HarnessClient _stub;
  String? token;
  String? _host;
  Future<void> _connecting = Future.value();
  static String _pinnedSha = '';

  static bool _isPinned(X509Certificate c, String host) =>
      crypto.sha256.convert(c.der).toString() == _pinnedSha;

  static Uint8List _derFromPem(ByteData pem) {
    final text = utf8.decode(
      pem.buffer.asUint8List(pem.offsetInBytes, pem.lengthInBytes),
      allowMalformed: true,
    );
    final m = RegExp(
      r'-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----',
      dotAll: true,
    ).firstMatch(text);
    final b64 = m!.group(1)!.replaceAll(RegExp(r'\s'), '');
    return Uint8List.fromList(base64Decode(b64));
  }

  Harness() : _channel = ClientChannel('localhost') {
    _stub = HarnessClient(_channel);
  }

  Future<void> ensureConnected(String host) {
    if (_host == host) return Future.value();
    _connecting = _connecting.then((_) async {
      if (_host == host) return;
      final bd = await rootBundle.load('assets/iq-task.crt');
      _pinnedSha = crypto.sha256.convert(_derFromPem(bd)).toString();
      _channel.shutdown();
      _channel = _build(host);
      _stub = HarnessClient(_channel);
      _host = host;
    });
    return _connecting;
  }

  ClientChannel _build(String host) => ClientChannel(
        host,
        port: defaultPort,
        options: ChannelOptions(
          credentials: ChannelCredentials.secure(onBadCertificate: _isPinned),
        ),
      );

  Map<String, String> get _meta => token == null ? {} : {authTokenKey: token!};

  CallOptions _opts({Duration? timeout}) =>
      CallOptions(metadata: _meta, timeout: timeout);

  void dispose() => _channel.shutdown();

  Future<T> _call<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on GrpcError catch (e) {
      if (!_isStale(e.code)) rethrow;
      final host = _host;
      if (host == null) rethrow;
      _channel.shutdown();
      _channel = _build(host);
      _stub = HarnessClient(_channel);
      return await fn();
    }
  }

  bool _isStale(int code) =>
      code == StatusCode.unimplemented ||
      code == StatusCode.unavailable ||
      code == StatusCode.internal ||
      code == StatusCode.unknown;

  Future<PingResponse> ping() => _call(
      () => _stub.ping(PingRequest(), options: _opts(timeout: rpcTimeout)));

  Future<LoginResponse> login(String token) => _call(
      () => _stub.login(LoginRequest(token: token), options: _opts()));

  Future<Session> createSession(String message, String repo,
          {String systemPrompt = '', String thinking = 'low', int context = 0}) =>
      _call(() => _stub.createSession(
            CreateSessionRequest(
                repo: repo,
                systemPrompt: systemPrompt,
                message: message,
                thinking: thinking,
                contextTokens: context),
            options: _opts(timeout: const Duration(seconds: 60)),
          ));

  Future<Session> getSession(String id) => _call(() => _stub.getSession(
    SessionRef(id: id),
    options: _opts(timeout: rpcTimeout),
  ));

  Future<List<Session>> listSessions() async =>
      (await _call(() => _stub.listSessions(
        ListRequest(),
        options: _opts(timeout: rpcTimeout),
      ))).sessions;

  Stream<Session> watchSession(String id) =>
      _stub.watchSession(WatchRequest(id: id), options: _opts());

  Future<Session> stopSession(String id) => _call(() => _stub.stopSession(
    SessionRef(id: id),
    options: _opts(timeout: rpcTimeout),
  ));

  Future<Session> resumeSession(String id) => _call(() => _stub.resumeSession(
    SessionRef(id: id),
    options: _opts(timeout: rpcTimeout),
  ));

  Future<void> deleteSession(String id) => _call(() => _stub.deleteSession(
    SessionRef(id: id),
    options: _opts(timeout: rpcTimeout),
  ));

  Future<Session> sendMessage(String id, String text) =>
      _call(() => _stub.sendMessage(
            MessageRequest(id: id, text: text),
            options: _opts(timeout: rpcTimeout),
          ));

  Future<Activity> getActivity(String id) => _call(() => _stub.getActivity(
    SessionRef(id: id),
    options: _opts(timeout: rpcTimeout),
  ));

  Future<CompleteResponse> complete(String id, String text) => _call(
      () => _stub.complete(
            CompleteRequest(id: id, text: text),
            options: _opts(timeout: rpcTimeout),
          ));

  Future<Dirs> listDirs(String path) => _call(() => _stub.listDirs(
    DirsRequest(path: path),
    options: _opts(timeout: rpcTimeout),
  ));
}