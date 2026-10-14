// This is a generated file - do not edit.
//
// Generated from task.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'task.pb.dart' as $0;

export 'task.pb.dart';

@$pb.GrpcServiceName('iq.Harness')
class HarnessClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  HarnessClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.PingResponse> ping(
    $0.PingRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$ping, request, options: options);
  }

  $grpc.ResponseFuture<$0.LoginResponse> login(
    $0.LoginRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$login, request, options: options);
  }

  $grpc.ResponseFuture<$0.Session> createSession(
    $0.CreateSessionRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createSession, request, options: options);
  }

  $grpc.ResponseFuture<$0.Session> getSession(
    $0.SessionRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getSession, request, options: options);
  }

  $grpc.ResponseFuture<$0.Sessions> listSessions(
    $0.ListRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listSessions, request, options: options);
  }

  $grpc.ResponseStream<$0.Session> watchSession(
    $0.WatchRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchSession, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.Session> stopSession(
    $0.SessionRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$stopSession, request, options: options);
  }

  $grpc.ResponseFuture<$0.Session> resumeSession(
    $0.SessionRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$resumeSession, request, options: options);
  }

  $grpc.ResponseFuture<$0.SessionRef> deleteSession(
    $0.SessionRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteSession, request, options: options);
  }

  $grpc.ResponseFuture<$0.Session> sendMessage(
    $0.MessageRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$sendMessage, request, options: options);
  }

  $grpc.ResponseFuture<$0.Activity> getActivity(
    $0.SessionRef request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getActivity, request, options: options);
  }

  $grpc.ResponseFuture<$0.Dirs> listDirs(
    $0.DirsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listDirs, request, options: options);
  }

  $grpc.ResponseFuture<$0.CompleteResponse> complete(
    $0.CompleteRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$complete, request, options: options);
  }

  // method descriptors

  static final _$ping = $grpc.ClientMethod<$0.PingRequest, $0.PingResponse>(
      '/iq.Harness/Ping',
      ($0.PingRequest value) => value.writeToBuffer(),
      $0.PingResponse.fromBuffer);
  static final _$login = $grpc.ClientMethod<$0.LoginRequest, $0.LoginResponse>(
      '/iq.Harness/Login',
      ($0.LoginRequest value) => value.writeToBuffer(),
      $0.LoginResponse.fromBuffer);
  static final _$createSession =
      $grpc.ClientMethod<$0.CreateSessionRequest, $0.Session>(
          '/iq.Harness/CreateSession',
          ($0.CreateSessionRequest value) => value.writeToBuffer(),
          $0.Session.fromBuffer);
  static final _$getSession = $grpc.ClientMethod<$0.SessionRef, $0.Session>(
      '/iq.Harness/GetSession',
      ($0.SessionRef value) => value.writeToBuffer(),
      $0.Session.fromBuffer);
  static final _$listSessions = $grpc.ClientMethod<$0.ListRequest, $0.Sessions>(
      '/iq.Harness/ListSessions',
      ($0.ListRequest value) => value.writeToBuffer(),
      $0.Sessions.fromBuffer);
  static final _$watchSession = $grpc.ClientMethod<$0.WatchRequest, $0.Session>(
      '/iq.Harness/WatchSession',
      ($0.WatchRequest value) => value.writeToBuffer(),
      $0.Session.fromBuffer);
  static final _$stopSession = $grpc.ClientMethod<$0.SessionRef, $0.Session>(
      '/iq.Harness/StopSession',
      ($0.SessionRef value) => value.writeToBuffer(),
      $0.Session.fromBuffer);
  static final _$resumeSession = $grpc.ClientMethod<$0.SessionRef, $0.Session>(
      '/iq.Harness/ResumeSession',
      ($0.SessionRef value) => value.writeToBuffer(),
      $0.Session.fromBuffer);
  static final _$deleteSession =
      $grpc.ClientMethod<$0.SessionRef, $0.SessionRef>(
          '/iq.Harness/DeleteSession',
          ($0.SessionRef value) => value.writeToBuffer(),
          $0.SessionRef.fromBuffer);
  static final _$sendMessage =
      $grpc.ClientMethod<$0.MessageRequest, $0.Session>(
          '/iq.Harness/SendMessage',
          ($0.MessageRequest value) => value.writeToBuffer(),
          $0.Session.fromBuffer);
  static final _$getActivity = $grpc.ClientMethod<$0.SessionRef, $0.Activity>(
      '/iq.Harness/GetActivity',
      ($0.SessionRef value) => value.writeToBuffer(),
      $0.Activity.fromBuffer);
  static final _$listDirs = $grpc.ClientMethod<$0.DirsRequest, $0.Dirs>(
      '/iq.Harness/ListDirs',
      ($0.DirsRequest value) => value.writeToBuffer(),
      $0.Dirs.fromBuffer);
  static final _$complete =
      $grpc.ClientMethod<$0.CompleteRequest, $0.CompleteResponse>(
          '/iq.Harness/Complete',
          ($0.CompleteRequest value) => value.writeToBuffer(),
          $0.CompleteResponse.fromBuffer);
}

@$pb.GrpcServiceName('iq.Harness')
abstract class HarnessServiceBase extends $grpc.Service {
  $core.String get $name => 'iq.Harness';

  HarnessServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.PingRequest, $0.PingResponse>(
        'Ping',
        ping_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PingRequest.fromBuffer(value),
        ($0.PingResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LoginRequest, $0.LoginResponse>(
        'Login',
        login_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LoginRequest.fromBuffer(value),
        ($0.LoginResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateSessionRequest, $0.Session>(
        'CreateSession',
        createSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CreateSessionRequest.fromBuffer(value),
        ($0.Session value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SessionRef, $0.Session>(
        'GetSession',
        getSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SessionRef.fromBuffer(value),
        ($0.Session value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListRequest, $0.Sessions>(
        'ListSessions',
        listSessions_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListRequest.fromBuffer(value),
        ($0.Sessions value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchRequest, $0.Session>(
        'WatchSession',
        watchSession_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.WatchRequest.fromBuffer(value),
        ($0.Session value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SessionRef, $0.Session>(
        'StopSession',
        stopSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SessionRef.fromBuffer(value),
        ($0.Session value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SessionRef, $0.Session>(
        'ResumeSession',
        resumeSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SessionRef.fromBuffer(value),
        ($0.Session value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SessionRef, $0.SessionRef>(
        'DeleteSession',
        deleteSession_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SessionRef.fromBuffer(value),
        ($0.SessionRef value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.MessageRequest, $0.Session>(
        'SendMessage',
        sendMessage_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.MessageRequest.fromBuffer(value),
        ($0.Session value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SessionRef, $0.Activity>(
        'GetActivity',
        getActivity_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SessionRef.fromBuffer(value),
        ($0.Activity value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DirsRequest, $0.Dirs>(
        'ListDirs',
        listDirs_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DirsRequest.fromBuffer(value),
        ($0.Dirs value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CompleteRequest, $0.CompleteResponse>(
        'Complete',
        complete_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CompleteRequest.fromBuffer(value),
        ($0.CompleteResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.PingResponse> ping_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.PingRequest> $request) async {
    return ping($call, await $request);
  }

  $async.Future<$0.PingResponse> ping(
      $grpc.ServiceCall call, $0.PingRequest request);

  $async.Future<$0.LoginResponse> login_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LoginRequest> $request) async {
    return login($call, await $request);
  }

  $async.Future<$0.LoginResponse> login(
      $grpc.ServiceCall call, $0.LoginRequest request);

  $async.Future<$0.Session> createSession_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateSessionRequest> $request) async {
    return createSession($call, await $request);
  }

  $async.Future<$0.Session> createSession(
      $grpc.ServiceCall call, $0.CreateSessionRequest request);

  $async.Future<$0.Session> getSession_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SessionRef> $request) async {
    return getSession($call, await $request);
  }

  $async.Future<$0.Session> getSession(
      $grpc.ServiceCall call, $0.SessionRef request);

  $async.Future<$0.Sessions> listSessions_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.ListRequest> $request) async {
    return listSessions($call, await $request);
  }

  $async.Future<$0.Sessions> listSessions(
      $grpc.ServiceCall call, $0.ListRequest request);

  $async.Stream<$0.Session> watchSession_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.WatchRequest> $request) async* {
    yield* watchSession($call, await $request);
  }

  $async.Stream<$0.Session> watchSession(
      $grpc.ServiceCall call, $0.WatchRequest request);

  $async.Future<$0.Session> stopSession_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SessionRef> $request) async {
    return stopSession($call, await $request);
  }

  $async.Future<$0.Session> stopSession(
      $grpc.ServiceCall call, $0.SessionRef request);

  $async.Future<$0.Session> resumeSession_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SessionRef> $request) async {
    return resumeSession($call, await $request);
  }

  $async.Future<$0.Session> resumeSession(
      $grpc.ServiceCall call, $0.SessionRef request);

  $async.Future<$0.SessionRef> deleteSession_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SessionRef> $request) async {
    return deleteSession($call, await $request);
  }

  $async.Future<$0.SessionRef> deleteSession(
      $grpc.ServiceCall call, $0.SessionRef request);

  $async.Future<$0.Session> sendMessage_Pre($grpc.ServiceCall $call,
      $async.Future<$0.MessageRequest> $request) async {
    return sendMessage($call, await $request);
  }

  $async.Future<$0.Session> sendMessage(
      $grpc.ServiceCall call, $0.MessageRequest request);

  $async.Future<$0.Activity> getActivity_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SessionRef> $request) async {
    return getActivity($call, await $request);
  }

  $async.Future<$0.Activity> getActivity(
      $grpc.ServiceCall call, $0.SessionRef request);

  $async.Future<$0.Dirs> listDirs_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.DirsRequest> $request) async {
    return listDirs($call, await $request);
  }

  $async.Future<$0.Dirs> listDirs(
      $grpc.ServiceCall call, $0.DirsRequest request);

  $async.Future<$0.CompleteResponse> complete_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CompleteRequest> $request) async {
    return complete($call, await $request);
  }

  $async.Future<$0.CompleteResponse> complete(
      $grpc.ServiceCall call, $0.CompleteRequest request);
}
