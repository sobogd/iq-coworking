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

import 'package:protobuf/protobuf.dart' as $pb;

import 'task.pb.dart' as $0;
import 'task.pbjson.dart';

export 'task.pb.dart';

abstract class HarnessServiceBase extends $pb.GeneratedService {
  $async.Future<$0.PingResponse> ping(
      $pb.ServerContext ctx, $0.PingRequest request);
  $async.Future<$0.LoginResponse> login(
      $pb.ServerContext ctx, $0.LoginRequest request);
  $async.Future<$0.Session> createSession(
      $pb.ServerContext ctx, $0.CreateSessionRequest request);
  $async.Future<$0.Session> getSession(
      $pb.ServerContext ctx, $0.SessionRef request);
  $async.Future<$0.Sessions> listSessions(
      $pb.ServerContext ctx, $0.ListRequest request);
  $async.Future<$0.Session> watchSession(
      $pb.ServerContext ctx, $0.WatchRequest request);
  $async.Future<$0.Session> stopSession(
      $pb.ServerContext ctx, $0.SessionRef request);
  $async.Future<$0.Session> resumeSession(
      $pb.ServerContext ctx, $0.SessionRef request);
  $async.Future<$0.SessionRef> deleteSession(
      $pb.ServerContext ctx, $0.SessionRef request);
  $async.Future<$0.Session> sendMessage(
      $pb.ServerContext ctx, $0.MessageRequest request);
  $async.Future<$0.Activity> getActivity(
      $pb.ServerContext ctx, $0.SessionRef request);
  $async.Future<$0.Dirs> listDirs(
      $pb.ServerContext ctx, $0.DirsRequest request);
  $async.Future<$0.CompleteResponse> complete(
      $pb.ServerContext ctx, $0.CompleteRequest request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'Ping':
        return $0.PingRequest();
      case 'Login':
        return $0.LoginRequest();
      case 'CreateSession':
        return $0.CreateSessionRequest();
      case 'GetSession':
        return $0.SessionRef();
      case 'ListSessions':
        return $0.ListRequest();
      case 'WatchSession':
        return $0.WatchRequest();
      case 'StopSession':
        return $0.SessionRef();
      case 'ResumeSession':
        return $0.SessionRef();
      case 'DeleteSession':
        return $0.SessionRef();
      case 'SendMessage':
        return $0.MessageRequest();
      case 'GetActivity':
        return $0.SessionRef();
      case 'ListDirs':
        return $0.DirsRequest();
      case 'Complete':
        return $0.CompleteRequest();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'Ping':
        return ping(ctx, request as $0.PingRequest);
      case 'Login':
        return login(ctx, request as $0.LoginRequest);
      case 'CreateSession':
        return createSession(ctx, request as $0.CreateSessionRequest);
      case 'GetSession':
        return getSession(ctx, request as $0.SessionRef);
      case 'ListSessions':
        return listSessions(ctx, request as $0.ListRequest);
      case 'WatchSession':
        return watchSession(ctx, request as $0.WatchRequest);
      case 'StopSession':
        return stopSession(ctx, request as $0.SessionRef);
      case 'ResumeSession':
        return resumeSession(ctx, request as $0.SessionRef);
      case 'DeleteSession':
        return deleteSession(ctx, request as $0.SessionRef);
      case 'SendMessage':
        return sendMessage(ctx, request as $0.MessageRequest);
      case 'GetActivity':
        return getActivity(ctx, request as $0.SessionRef);
      case 'ListDirs':
        return listDirs(ctx, request as $0.DirsRequest);
      case 'Complete':
        return complete(ctx, request as $0.CompleteRequest);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => HarnessServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => HarnessServiceBase$messageJson;
}
