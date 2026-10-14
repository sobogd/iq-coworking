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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class PingRequest extends $pb.GeneratedMessage {
  factory PingRequest() => PingRequest._();

  PingRequest._();

  factory PingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PingRequest()..mergeFromBuffer(data, registry);
  factory PingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PingRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: PingRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PingRequest copyWith(void Function(PingRequest) updates) =>
      super.copyWith((message) => updates(message as PingRequest))
          as PingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PingRequest() / PingRequest.new instead')
  static PingRequest create() => PingRequest._();
  static $pb.GeneratedMessage $_createMessage() => PingRequest._();
  @$core.override
  PingRequest createEmptyInstance() => PingRequest._();
  @$core.pragma('dart2js:noInline')
  static PingRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PingRequest>(
          PingRequest.$_createMessage);
  static PingRequest? _defaultInstance;
}

class PingResponse extends $pb.GeneratedMessage {
  factory PingResponse({
    $core.String? version,
    $core.int? sessions,
  }) {
    final result = PingResponse._();
    if (version != null) result.version = version;
    if (sessions != null) result.sessions = sessions;
    return result;
  }

  PingResponse._();

  factory PingResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PingResponse()..mergeFromBuffer(data, registry);
  factory PingResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PingResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PingResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: PingResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'version')
    ..aI(2, _omitFieldNames ? '' : 'sessions')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PingResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PingResponse copyWith(void Function(PingResponse) updates) =>
      super.copyWith((message) => updates(message as PingResponse))
          as PingResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PingResponse() / PingResponse.new instead')
  static PingResponse create() => PingResponse._();
  static $pb.GeneratedMessage $_createMessage() => PingResponse._();
  @$core.override
  PingResponse createEmptyInstance() => PingResponse._();
  @$core.pragma('dart2js:noInline')
  static PingResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PingResponse>(
          PingResponse.$_createMessage);
  static PingResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get version => $_getSZ(0);
  @$pb.TagNumber(1)
  set version($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get sessions => $_getIZ(1);
  @$pb.TagNumber(2)
  set sessions($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessions() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessions() => $_clearField(2);
}

class LoginRequest extends $pb.GeneratedMessage {
  factory LoginRequest({
    $core.String? token,
  }) {
    final result = LoginRequest._();
    if (token != null) result.token = token;
    return result;
  }

  LoginRequest._();

  factory LoginRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginRequest()..mergeFromBuffer(data, registry);
  factory LoginRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: LoginRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest copyWith(void Function(LoginRequest) updates) =>
      super.copyWith((message) => updates(message as LoginRequest))
          as LoginRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LoginRequest() / LoginRequest.new instead')
  static LoginRequest create() => LoginRequest._();
  static $pb.GeneratedMessage $_createMessage() => LoginRequest._();
  @$core.override
  LoginRequest createEmptyInstance() => LoginRequest._();
  @$core.pragma('dart2js:noInline')
  static LoginRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoginRequest>(
          LoginRequest.$_createMessage);
  static LoginRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);
}

class LoginResponse extends $pb.GeneratedMessage {
  factory LoginResponse({
    $core.String? token,
  }) {
    final result = LoginResponse._();
    if (token != null) result.token = token;
    return result;
  }

  LoginResponse._();

  factory LoginResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginResponse()..mergeFromBuffer(data, registry);
  factory LoginResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LoginResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: LoginResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginResponse copyWith(void Function(LoginResponse) updates) =>
      super.copyWith((message) => updates(message as LoginResponse))
          as LoginResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LoginResponse() / LoginResponse.new instead')
  static LoginResponse create() => LoginResponse._();
  static $pb.GeneratedMessage $_createMessage() => LoginResponse._();
  @$core.override
  LoginResponse createEmptyInstance() => LoginResponse._();
  @$core.pragma('dart2js:noInline')
  static LoginResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LoginResponse>(
          LoginResponse.$_createMessage);
  static LoginResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);
}

class CreateSessionRequest extends $pb.GeneratedMessage {
  factory CreateSessionRequest({
    $core.String? repo,
    $core.String? systemPrompt,
    $core.String? message,
    $core.String? thinking,
    $core.int? contextTokens,
  }) {
    final result = CreateSessionRequest._();
    if (repo != null) result.repo = repo;
    if (systemPrompt != null) result.systemPrompt = systemPrompt;
    if (message != null) result.message = message;
    if (thinking != null) result.thinking = thinking;
    if (contextTokens != null) result.contextTokens = contextTokens;
    return result;
  }

  CreateSessionRequest._();

  factory CreateSessionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateSessionRequest()..mergeFromBuffer(data, registry);
  factory CreateSessionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateSessionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateSessionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: CreateSessionRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'repo')
    ..aOS(2, _omitFieldNames ? '' : 'systemPrompt')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..aOS(4, _omitFieldNames ? '' : 'thinking')
    ..aI(5, _omitFieldNames ? '' : 'contextTokens')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateSessionRequest copyWith(void Function(CreateSessionRequest) updates) =>
      super.copyWith((message) => updates(message as CreateSessionRequest))
          as CreateSessionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated(
      'Use CreateSessionRequest() / CreateSessionRequest.new instead')
  static CreateSessionRequest create() => CreateSessionRequest._();
  static $pb.GeneratedMessage $_createMessage() => CreateSessionRequest._();
  @$core.override
  CreateSessionRequest createEmptyInstance() => CreateSessionRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateSessionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateSessionRequest>(
          CreateSessionRequest.$_createMessage);
  static CreateSessionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get repo => $_getSZ(0);
  @$pb.TagNumber(1)
  set repo($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRepo() => $_has(0);
  @$pb.TagNumber(1)
  void clearRepo() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get systemPrompt => $_getSZ(1);
  @$pb.TagNumber(2)
  set systemPrompt($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSystemPrompt() => $_has(1);
  @$pb.TagNumber(2)
  void clearSystemPrompt() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get thinking => $_getSZ(3);
  @$pb.TagNumber(4)
  set thinking($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasThinking() => $_has(3);
  @$pb.TagNumber(4)
  void clearThinking() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get contextTokens => $_getIZ(4);
  @$pb.TagNumber(5)
  set contextTokens($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasContextTokens() => $_has(4);
  @$pb.TagNumber(5)
  void clearContextTokens() => $_clearField(5);
}

class Session extends $pb.GeneratedMessage {
  factory Session({
    $core.String? id,
    $core.String? repo,
    $core.String? systemPrompt,
    $core.String? title,
    $core.String? status,
    $core.String? error,
    $fixnum.Int64? createdAt,
    $fixnum.Int64? updatedAt,
    $core.String? thinking,
    $core.int? contextTokens,
  }) {
    final result = Session._();
    if (id != null) result.id = id;
    if (repo != null) result.repo = repo;
    if (systemPrompt != null) result.systemPrompt = systemPrompt;
    if (title != null) result.title = title;
    if (status != null) result.status = status;
    if (error != null) result.error = error;
    if (createdAt != null) result.createdAt = createdAt;
    if (updatedAt != null) result.updatedAt = updatedAt;
    if (thinking != null) result.thinking = thinking;
    if (contextTokens != null) result.contextTokens = contextTokens;
    return result;
  }

  Session._();

  factory Session.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Session()..mergeFromBuffer(data, registry);
  factory Session.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Session()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Session',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: Session.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'repo')
    ..aOS(3, _omitFieldNames ? '' : 'systemPrompt')
    ..aOS(4, _omitFieldNames ? '' : 'title')
    ..aOS(5, _omitFieldNames ? '' : 'status')
    ..aOS(6, _omitFieldNames ? '' : 'error')
    ..aInt64(7, _omitFieldNames ? '' : 'createdAt')
    ..aInt64(8, _omitFieldNames ? '' : 'updatedAt')
    ..aOS(9, _omitFieldNames ? '' : 'thinking')
    ..aI(10, _omitFieldNames ? '' : 'contextTokens')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Session clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Session copyWith(void Function(Session) updates) =>
      super.copyWith((message) => updates(message as Session)) as Session;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Session() / Session.new instead')
  static Session create() => Session._();
  static $pb.GeneratedMessage $_createMessage() => Session._();
  @$core.override
  Session createEmptyInstance() => Session._();
  @$core.pragma('dart2js:noInline')
  static Session getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Session>(Session.$_createMessage);
  static Session? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get repo => $_getSZ(1);
  @$pb.TagNumber(2)
  set repo($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRepo() => $_has(1);
  @$pb.TagNumber(2)
  void clearRepo() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get systemPrompt => $_getSZ(2);
  @$pb.TagNumber(3)
  set systemPrompt($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSystemPrompt() => $_has(2);
  @$pb.TagNumber(3)
  void clearSystemPrompt() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get title => $_getSZ(3);
  @$pb.TagNumber(4)
  set title($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearTitle() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get status => $_getSZ(4);
  @$pb.TagNumber(5)
  set status($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasStatus() => $_has(4);
  @$pb.TagNumber(5)
  void clearStatus() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get error => $_getSZ(5);
  @$pb.TagNumber(6)
  set error($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasError() => $_has(5);
  @$pb.TagNumber(6)
  void clearError() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get createdAt => $_getI64(6);
  @$pb.TagNumber(7)
  set createdAt($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCreatedAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearCreatedAt() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get updatedAt => $_getI64(7);
  @$pb.TagNumber(8)
  set updatedAt($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasUpdatedAt() => $_has(7);
  @$pb.TagNumber(8)
  void clearUpdatedAt() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get thinking => $_getSZ(8);
  @$pb.TagNumber(9)
  set thinking($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasThinking() => $_has(8);
  @$pb.TagNumber(9)
  void clearThinking() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.int get contextTokens => $_getIZ(9);
  @$pb.TagNumber(10)
  set contextTokens($core.int value) => $_setSignedInt32(9, value);
  @$pb.TagNumber(10)
  $core.bool hasContextTokens() => $_has(9);
  @$pb.TagNumber(10)
  void clearContextTokens() => $_clearField(10);
}

class SessionRef extends $pb.GeneratedMessage {
  factory SessionRef({
    $core.String? id,
  }) {
    final result = SessionRef._();
    if (id != null) result.id = id;
    return result;
  }

  SessionRef._();

  factory SessionRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SessionRef()..mergeFromBuffer(data, registry);
  factory SessionRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SessionRef()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SessionRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: SessionRef.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionRef copyWith(void Function(SessionRef) updates) =>
      super.copyWith((message) => updates(message as SessionRef)) as SessionRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SessionRef() / SessionRef.new instead')
  static SessionRef create() => SessionRef._();
  static $pb.GeneratedMessage $_createMessage() => SessionRef._();
  @$core.override
  SessionRef createEmptyInstance() => SessionRef._();
  @$core.pragma('dart2js:noInline')
  static SessionRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SessionRef>(SessionRef.$_createMessage);
  static SessionRef? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class ListRequest extends $pb.GeneratedMessage {
  factory ListRequest() => ListRequest._();

  ListRequest._();

  factory ListRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRequest()..mergeFromBuffer(data, registry);
  factory ListRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: ListRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListRequest copyWith(void Function(ListRequest) updates) =>
      super.copyWith((message) => updates(message as ListRequest))
          as ListRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListRequest() / ListRequest.new instead')
  static ListRequest create() => ListRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListRequest._();
  @$core.override
  ListRequest createEmptyInstance() => ListRequest._();
  @$core.pragma('dart2js:noInline')
  static ListRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListRequest>(
          ListRequest.$_createMessage);
  static ListRequest? _defaultInstance;
}

class Sessions extends $pb.GeneratedMessage {
  factory Sessions({
    $core.Iterable<Session>? sessions,
  }) {
    final result = Sessions._();
    if (sessions != null) result.sessions.addAll(sessions);
    return result;
  }

  Sessions._();

  factory Sessions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Sessions()..mergeFromBuffer(data, registry);
  factory Sessions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Sessions()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Sessions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: Sessions.$_createMessage)
    ..pPM<Session>(1, _omitFieldNames ? '' : 'sessions',
        subBuilder: Session.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Sessions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Sessions copyWith(void Function(Sessions) updates) =>
      super.copyWith((message) => updates(message as Sessions)) as Sessions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Sessions() / Sessions.new instead')
  static Sessions create() => Sessions._();
  static $pb.GeneratedMessage $_createMessage() => Sessions._();
  @$core.override
  Sessions createEmptyInstance() => Sessions._();
  @$core.pragma('dart2js:noInline')
  static Sessions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Sessions>(Sessions.$_createMessage);
  static Sessions? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Session> get sessions => $_getList(0);
}

class WatchRequest extends $pb.GeneratedMessage {
  factory WatchRequest({
    $core.String? id,
  }) {
    final result = WatchRequest._();
    if (id != null) result.id = id;
    return result;
  }

  WatchRequest._();

  factory WatchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchRequest()..mergeFromBuffer(data, registry);
  factory WatchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: WatchRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchRequest copyWith(void Function(WatchRequest) updates) =>
      super.copyWith((message) => updates(message as WatchRequest))
          as WatchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WatchRequest() / WatchRequest.new instead')
  static WatchRequest create() => WatchRequest._();
  static $pb.GeneratedMessage $_createMessage() => WatchRequest._();
  @$core.override
  WatchRequest createEmptyInstance() => WatchRequest._();
  @$core.pragma('dart2js:noInline')
  static WatchRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WatchRequest>(
          WatchRequest.$_createMessage);
  static WatchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class MessageRequest extends $pb.GeneratedMessage {
  factory MessageRequest({
    $core.String? id,
    $core.String? text,
  }) {
    final result = MessageRequest._();
    if (id != null) result.id = id;
    if (text != null) result.text = text;
    return result;
  }

  MessageRequest._();

  factory MessageRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageRequest()..mergeFromBuffer(data, registry);
  factory MessageRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MessageRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MessageRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: MessageRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MessageRequest copyWith(void Function(MessageRequest) updates) =>
      super.copyWith((message) => updates(message as MessageRequest))
          as MessageRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MessageRequest() / MessageRequest.new instead')
  static MessageRequest create() => MessageRequest._();
  static $pb.GeneratedMessage $_createMessage() => MessageRequest._();
  @$core.override
  MessageRequest createEmptyInstance() => MessageRequest._();
  @$core.pragma('dart2js:noInline')
  static MessageRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MessageRequest>(
          MessageRequest.$_createMessage);
  static MessageRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);
}

class DirsRequest extends $pb.GeneratedMessage {
  factory DirsRequest({
    $core.String? path,
  }) {
    final result = DirsRequest._();
    if (path != null) result.path = path;
    return result;
  }

  DirsRequest._();

  factory DirsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DirsRequest()..mergeFromBuffer(data, registry);
  factory DirsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DirsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DirsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: DirsRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DirsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DirsRequest copyWith(void Function(DirsRequest) updates) =>
      super.copyWith((message) => updates(message as DirsRequest))
          as DirsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DirsRequest() / DirsRequest.new instead')
  static DirsRequest create() => DirsRequest._();
  static $pb.GeneratedMessage $_createMessage() => DirsRequest._();
  @$core.override
  DirsRequest createEmptyInstance() => DirsRequest._();
  @$core.pragma('dart2js:noInline')
  static DirsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DirsRequest>(
          DirsRequest.$_createMessage);
  static DirsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);
}

class Dirs extends $pb.GeneratedMessage {
  factory Dirs({
    $core.String? path,
    $core.Iterable<$core.String>? dirs,
  }) {
    final result = Dirs._();
    if (path != null) result.path = path;
    if (dirs != null) result.dirs.addAll(dirs);
    return result;
  }

  Dirs._();

  factory Dirs.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Dirs()..mergeFromBuffer(data, registry);
  factory Dirs.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Dirs()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Dirs',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: Dirs.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..pPS(2, _omitFieldNames ? '' : 'dirs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Dirs clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Dirs copyWith(void Function(Dirs) updates) =>
      super.copyWith((message) => updates(message as Dirs)) as Dirs;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Dirs() / Dirs.new instead')
  static Dirs create() => Dirs._();
  static $pb.GeneratedMessage $_createMessage() => Dirs._();
  @$core.override
  Dirs createEmptyInstance() => Dirs._();
  @$core.pragma('dart2js:noInline')
  static Dirs getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Dirs>(Dirs.$_createMessage);
  static Dirs? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get dirs => $_getList(1);
}

class CompleteRequest extends $pb.GeneratedMessage {
  factory CompleteRequest({
    $core.String? id,
    $core.String? text,
  }) {
    final result = CompleteRequest._();
    if (id != null) result.id = id;
    if (text != null) result.text = text;
    return result;
  }

  CompleteRequest._();

  factory CompleteRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompleteRequest()..mergeFromBuffer(data, registry);
  factory CompleteRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompleteRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompleteRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: CompleteRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteRequest copyWith(void Function(CompleteRequest) updates) =>
      super.copyWith((message) => updates(message as CompleteRequest))
          as CompleteRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CompleteRequest() / CompleteRequest.new instead')
  static CompleteRequest create() => CompleteRequest._();
  static $pb.GeneratedMessage $_createMessage() => CompleteRequest._();
  @$core.override
  CompleteRequest createEmptyInstance() => CompleteRequest._();
  @$core.pragma('dart2js:noInline')
  static CompleteRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CompleteRequest>(
          CompleteRequest.$_createMessage);
  static CompleteRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => $_clearField(2);
}

class CompleteResponse extends $pb.GeneratedMessage {
  factory CompleteResponse({
    $core.String? text,
  }) {
    final result = CompleteResponse._();
    if (text != null) result.text = text;
    return result;
  }

  CompleteResponse._();

  factory CompleteResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompleteResponse()..mergeFromBuffer(data, registry);
  factory CompleteResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CompleteResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CompleteResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: CompleteResponse.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'text')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CompleteResponse copyWith(void Function(CompleteResponse) updates) =>
      super.copyWith((message) => updates(message as CompleteResponse))
          as CompleteResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CompleteResponse() / CompleteResponse.new instead')
  static CompleteResponse create() => CompleteResponse._();
  static $pb.GeneratedMessage $_createMessage() => CompleteResponse._();
  @$core.override
  CompleteResponse createEmptyInstance() => CompleteResponse._();
  @$core.pragma('dart2js:noInline')
  static CompleteResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CompleteResponse>(
          CompleteResponse.$_createMessage);
  static CompleteResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get text => $_getSZ(0);
  @$pb.TagNumber(1)
  set text($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasText() => $_has(0);
  @$pb.TagNumber(1)
  void clearText() => $_clearField(1);
}

class ActivityMessage extends $pb.GeneratedMessage {
  factory ActivityMessage({
    $core.String? role,
    $core.String? content,
    $core.Iterable<$core.String>? toolCalls,
    $core.String? reasoning,
  }) {
    final result = ActivityMessage._();
    if (role != null) result.role = role;
    if (content != null) result.content = content;
    if (toolCalls != null) result.toolCalls.addAll(toolCalls);
    if (reasoning != null) result.reasoning = reasoning;
    return result;
  }

  ActivityMessage._();

  factory ActivityMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ActivityMessage()..mergeFromBuffer(data, registry);
  factory ActivityMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ActivityMessage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ActivityMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: ActivityMessage.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'role')
    ..aOS(2, _omitFieldNames ? '' : 'content')
    ..pPS(3, _omitFieldNames ? '' : 'toolCalls')
    ..aOS(4, _omitFieldNames ? '' : 'reasoning')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActivityMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ActivityMessage copyWith(void Function(ActivityMessage) updates) =>
      super.copyWith((message) => updates(message as ActivityMessage))
          as ActivityMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ActivityMessage() / ActivityMessage.new instead')
  static ActivityMessage create() => ActivityMessage._();
  static $pb.GeneratedMessage $_createMessage() => ActivityMessage._();
  @$core.override
  ActivityMessage createEmptyInstance() => ActivityMessage._();
  @$core.pragma('dart2js:noInline')
  static ActivityMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ActivityMessage>(
          ActivityMessage.$_createMessage);
  static ActivityMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get role => $_getSZ(0);
  @$pb.TagNumber(1)
  set role($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRole() => $_has(0);
  @$pb.TagNumber(1)
  void clearRole() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get content => $_getSZ(1);
  @$pb.TagNumber(2)
  set content($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasContent() => $_has(1);
  @$pb.TagNumber(2)
  void clearContent() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get toolCalls => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get reasoning => $_getSZ(3);
  @$pb.TagNumber(4)
  set reasoning($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasReasoning() => $_has(3);
  @$pb.TagNumber(4)
  void clearReasoning() => $_clearField(4);
}

class Activity extends $pb.GeneratedMessage {
  factory Activity({
    $core.Iterable<ActivityMessage>? messages,
    $core.bool? more,
  }) {
    final result = Activity._();
    if (messages != null) result.messages.addAll(messages);
    if (more != null) result.more = more;
    return result;
  }

  Activity._();

  factory Activity.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Activity()..mergeFromBuffer(data, registry);
  factory Activity.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Activity()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Activity',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'iq'),
      createEmptyInstance: Activity.$_createMessage)
    ..pPM<ActivityMessage>(1, _omitFieldNames ? '' : 'messages',
        subBuilder: ActivityMessage.$_createMessage)
    ..aOB(2, _omitFieldNames ? '' : 'more')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Activity clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Activity copyWith(void Function(Activity) updates) =>
      super.copyWith((message) => updates(message as Activity)) as Activity;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Activity() / Activity.new instead')
  static Activity create() => Activity._();
  static $pb.GeneratedMessage $_createMessage() => Activity._();
  @$core.override
  Activity createEmptyInstance() => Activity._();
  @$core.pragma('dart2js:noInline')
  static Activity getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Activity>(Activity.$_createMessage);
  static Activity? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ActivityMessage> get messages => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get more => $_getBF(1);
  @$pb.TagNumber(2)
  set more($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMore() => $_has(1);
  @$pb.TagNumber(2)
  void clearMore() => $_clearField(2);
}

class HarnessApi {
  final $pb.RpcClient _client;

  HarnessApi(this._client);

  $async.Future<PingResponse> ping(
          $pb.ClientContext? ctx, PingRequest request) =>
      _client.invoke<PingResponse>(
          ctx, 'Harness', 'Ping', request, PingResponse());
  $async.Future<LoginResponse> login(
          $pb.ClientContext? ctx, LoginRequest request) =>
      _client.invoke<LoginResponse>(
          ctx, 'Harness', 'Login', request, LoginResponse());
  $async.Future<Session> createSession(
          $pb.ClientContext? ctx, CreateSessionRequest request) =>
      _client.invoke<Session>(
          ctx, 'Harness', 'CreateSession', request, Session());
  $async.Future<Session> getSession(
          $pb.ClientContext? ctx, SessionRef request) =>
      _client.invoke<Session>(ctx, 'Harness', 'GetSession', request, Session());
  $async.Future<Sessions> listSessions(
          $pb.ClientContext? ctx, ListRequest request) =>
      _client.invoke<Sessions>(
          ctx, 'Harness', 'ListSessions', request, Sessions());
  $async.Future<Session> watchSession(
          $pb.ClientContext? ctx, WatchRequest request) =>
      _client.invoke<Session>(
          ctx, 'Harness', 'WatchSession', request, Session());
  $async.Future<Session> stopSession(
          $pb.ClientContext? ctx, SessionRef request) =>
      _client.invoke<Session>(
          ctx, 'Harness', 'StopSession', request, Session());
  $async.Future<Session> resumeSession(
          $pb.ClientContext? ctx, SessionRef request) =>
      _client.invoke<Session>(
          ctx, 'Harness', 'ResumeSession', request, Session());
  $async.Future<SessionRef> deleteSession(
          $pb.ClientContext? ctx, SessionRef request) =>
      _client.invoke<SessionRef>(
          ctx, 'Harness', 'DeleteSession', request, SessionRef());
  $async.Future<Session> sendMessage(
          $pb.ClientContext? ctx, MessageRequest request) =>
      _client.invoke<Session>(
          ctx, 'Harness', 'SendMessage', request, Session());
  $async.Future<Activity> getActivity(
          $pb.ClientContext? ctx, SessionRef request) =>
      _client.invoke<Activity>(
          ctx, 'Harness', 'GetActivity', request, Activity());
  $async.Future<Dirs> listDirs($pb.ClientContext? ctx, DirsRequest request) =>
      _client.invoke<Dirs>(ctx, 'Harness', 'ListDirs', request, Dirs());
  $async.Future<CompleteResponse> complete(
          $pb.ClientContext? ctx, CompleteRequest request) =>
      _client.invoke<CompleteResponse>(
          ctx, 'Harness', 'Complete', request, CompleteResponse());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
