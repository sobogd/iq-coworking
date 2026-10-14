// This is a generated file - do not edit.
//
// Generated from task.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use pingRequestDescriptor instead')
const PingRequest$json = {
  '1': 'PingRequest',
};

/// Descriptor for `PingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pingRequestDescriptor =
    $convert.base64Decode('CgtQaW5nUmVxdWVzdA==');

@$core.Deprecated('Use pingResponseDescriptor instead')
const PingResponse$json = {
  '1': 'PingResponse',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 9, '10': 'version'},
    {'1': 'sessions', '3': 2, '4': 1, '5': 5, '10': 'sessions'},
  ],
};

/// Descriptor for `PingResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pingResponseDescriptor = $convert.base64Decode(
    'CgxQaW5nUmVzcG9uc2USGAoHdmVyc2lvbhgBIAEoCVIHdmVyc2lvbhIaCghzZXNzaW9ucxgCIA'
    'EoBVIIc2Vzc2lvbnM=');

@$core.Deprecated('Use loginRequestDescriptor instead')
const LoginRequest$json = {
  '1': 'LoginRequest',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `LoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginRequestDescriptor =
    $convert.base64Decode('CgxMb2dpblJlcXVlc3QSFAoFdG9rZW4YASABKAlSBXRva2Vu');

@$core.Deprecated('Use loginResponseDescriptor instead')
const LoginResponse$json = {
  '1': 'LoginResponse',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `LoginResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginResponseDescriptor = $convert
    .base64Decode('Cg1Mb2dpblJlc3BvbnNlEhQKBXRva2VuGAEgASgJUgV0b2tlbg==');

@$core.Deprecated('Use createSessionRequestDescriptor instead')
const CreateSessionRequest$json = {
  '1': 'CreateSessionRequest',
  '2': [
    {'1': 'repo', '3': 1, '4': 1, '5': 9, '10': 'repo'},
    {'1': 'system_prompt', '3': 2, '4': 1, '5': 9, '10': 'systemPrompt'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
    {'1': 'thinking', '3': 4, '4': 1, '5': 9, '10': 'thinking'},
    {'1': 'context_tokens', '3': 5, '4': 1, '5': 5, '10': 'contextTokens'},
  ],
};

/// Descriptor for `CreateSessionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createSessionRequestDescriptor = $convert.base64Decode(
    'ChRDcmVhdGVTZXNzaW9uUmVxdWVzdBISCgRyZXBvGAEgASgJUgRyZXBvEiMKDXN5c3RlbV9wcm'
    '9tcHQYAiABKAlSDHN5c3RlbVByb21wdBIYCgdtZXNzYWdlGAMgASgJUgdtZXNzYWdlEhoKCHRo'
    'aW5raW5nGAQgASgJUgh0aGlua2luZxIlCg5jb250ZXh0X3Rva2VucxgFIAEoBVINY29udGV4dF'
    'Rva2Vucw==');

@$core.Deprecated('Use sessionDescriptor instead')
const Session$json = {
  '1': 'Session',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'repo', '3': 2, '4': 1, '5': 9, '10': 'repo'},
    {'1': 'system_prompt', '3': 3, '4': 1, '5': 9, '10': 'systemPrompt'},
    {'1': 'title', '3': 4, '4': 1, '5': 9, '10': 'title'},
    {'1': 'status', '3': 5, '4': 1, '5': 9, '10': 'status'},
    {'1': 'error', '3': 6, '4': 1, '5': 9, '10': 'error'},
    {'1': 'created_at', '3': 7, '4': 1, '5': 3, '10': 'createdAt'},
    {'1': 'updated_at', '3': 8, '4': 1, '5': 3, '10': 'updatedAt'},
    {'1': 'thinking', '3': 9, '4': 1, '5': 9, '10': 'thinking'},
    {'1': 'context_tokens', '3': 10, '4': 1, '5': 5, '10': 'contextTokens'},
  ],
};

/// Descriptor for `Session`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionDescriptor = $convert.base64Decode(
    'CgdTZXNzaW9uEg4KAmlkGAEgASgJUgJpZBISCgRyZXBvGAIgASgJUgRyZXBvEiMKDXN5c3RlbV'
    '9wcm9tcHQYAyABKAlSDHN5c3RlbVByb21wdBIUCgV0aXRsZRgEIAEoCVIFdGl0bGUSFgoGc3Rh'
    'dHVzGAUgASgJUgZzdGF0dXMSFAoFZXJyb3IYBiABKAlSBWVycm9yEh0KCmNyZWF0ZWRfYXQYBy'
    'ABKANSCWNyZWF0ZWRBdBIdCgp1cGRhdGVkX2F0GAggASgDUgl1cGRhdGVkQXQSGgoIdGhpbmtp'
    'bmcYCSABKAlSCHRoaW5raW5nEiUKDmNvbnRleHRfdG9rZW5zGAogASgFUg1jb250ZXh0VG9rZW'
    '5z');

@$core.Deprecated('Use sessionRefDescriptor instead')
const SessionRef$json = {
  '1': 'SessionRef',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `SessionRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionRefDescriptor =
    $convert.base64Decode('CgpTZXNzaW9uUmVmEg4KAmlkGAEgASgJUgJpZA==');

@$core.Deprecated('Use listRequestDescriptor instead')
const ListRequest$json = {
  '1': 'ListRequest',
};

/// Descriptor for `ListRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listRequestDescriptor =
    $convert.base64Decode('CgtMaXN0UmVxdWVzdA==');

@$core.Deprecated('Use sessionsDescriptor instead')
const Sessions$json = {
  '1': 'Sessions',
  '2': [
    {
      '1': 'sessions',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.iq.Session',
      '10': 'sessions'
    },
  ],
};

/// Descriptor for `Sessions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionsDescriptor = $convert.base64Decode(
    'CghTZXNzaW9ucxInCghzZXNzaW9ucxgBIAMoCzILLmlxLlNlc3Npb25SCHNlc3Npb25z');

@$core.Deprecated('Use watchRequestDescriptor instead')
const WatchRequest$json = {
  '1': 'WatchRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `WatchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchRequestDescriptor =
    $convert.base64Decode('CgxXYXRjaFJlcXVlc3QSDgoCaWQYASABKAlSAmlk');

@$core.Deprecated('Use messageRequestDescriptor instead')
const MessageRequest$json = {
  '1': 'MessageRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `MessageRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageRequestDescriptor = $convert.base64Decode(
    'Cg5NZXNzYWdlUmVxdWVzdBIOCgJpZBgBIAEoCVICaWQSEgoEdGV4dBgCIAEoCVIEdGV4dA==');

@$core.Deprecated('Use dirsRequestDescriptor instead')
const DirsRequest$json = {
  '1': 'DirsRequest',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
  ],
};

/// Descriptor for `DirsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dirsRequestDescriptor =
    $convert.base64Decode('CgtEaXJzUmVxdWVzdBISCgRwYXRoGAEgASgJUgRwYXRo');

@$core.Deprecated('Use dirsDescriptor instead')
const Dirs$json = {
  '1': 'Dirs',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'dirs', '3': 2, '4': 3, '5': 9, '10': 'dirs'},
  ],
};

/// Descriptor for `Dirs`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dirsDescriptor = $convert.base64Decode(
    'CgREaXJzEhIKBHBhdGgYASABKAlSBHBhdGgSEgoEZGlycxgCIAMoCVIEZGlycw==');

@$core.Deprecated('Use completeRequestDescriptor instead')
const CompleteRequest$json = {
  '1': 'CompleteRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `CompleteRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List completeRequestDescriptor = $convert.base64Decode(
    'Cg9Db21wbGV0ZVJlcXVlc3QSDgoCaWQYASABKAlSAmlkEhIKBHRleHQYAiABKAlSBHRleHQ=');

@$core.Deprecated('Use completeResponseDescriptor instead')
const CompleteResponse$json = {
  '1': 'CompleteResponse',
  '2': [
    {'1': 'text', '3': 1, '4': 1, '5': 9, '10': 'text'},
  ],
};

/// Descriptor for `CompleteResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List completeResponseDescriptor = $convert
    .base64Decode('ChBDb21wbGV0ZVJlc3BvbnNlEhIKBHRleHQYASABKAlSBHRleHQ=');

@$core.Deprecated('Use activityMessageDescriptor instead')
const ActivityMessage$json = {
  '1': 'ActivityMessage',
  '2': [
    {'1': 'role', '3': 1, '4': 1, '5': 9, '10': 'role'},
    {'1': 'content', '3': 2, '4': 1, '5': 9, '10': 'content'},
    {'1': 'tool_calls', '3': 3, '4': 3, '5': 9, '10': 'toolCalls'},
    {'1': 'reasoning', '3': 4, '4': 1, '5': 9, '10': 'reasoning'},
  ],
};

/// Descriptor for `ActivityMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activityMessageDescriptor = $convert.base64Decode(
    'Cg9BY3Rpdml0eU1lc3NhZ2USEgoEcm9sZRgBIAEoCVIEcm9sZRIYCgdjb250ZW50GAIgASgJUg'
    'djb250ZW50Eh0KCnRvb2xfY2FsbHMYAyADKAlSCXRvb2xDYWxscxIcCglyZWFzb25pbmcYBCAB'
    'KAlSCXJlYXNvbmluZw==');

@$core.Deprecated('Use activityDescriptor instead')
const Activity$json = {
  '1': 'Activity',
  '2': [
    {
      '1': 'messages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.iq.ActivityMessage',
      '10': 'messages'
    },
    {'1': 'more', '3': 2, '4': 1, '5': 8, '10': 'more'},
  ],
};

/// Descriptor for `Activity`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List activityDescriptor = $convert.base64Decode(
    'CghBY3Rpdml0eRIvCghtZXNzYWdlcxgBIAMoCzITLmlxLkFjdGl2aXR5TWVzc2FnZVIIbWVzc2'
    'FnZXMSEgoEbW9yZRgCIAEoCFIEbW9yZQ==');

const $core.Map<$core.String, $core.dynamic> HarnessServiceBase$json = {
  '1': 'Harness',
  '2': [
    {'1': 'Ping', '2': '.iq.PingRequest', '3': '.iq.PingResponse'},
    {'1': 'Login', '2': '.iq.LoginRequest', '3': '.iq.LoginResponse'},
    {'1': 'CreateSession', '2': '.iq.CreateSessionRequest', '3': '.iq.Session'},
    {'1': 'GetSession', '2': '.iq.SessionRef', '3': '.iq.Session'},
    {'1': 'ListSessions', '2': '.iq.ListRequest', '3': '.iq.Sessions'},
    {
      '1': 'WatchSession',
      '2': '.iq.WatchRequest',
      '3': '.iq.Session',
      '6': true
    },
    {'1': 'StopSession', '2': '.iq.SessionRef', '3': '.iq.Session'},
    {'1': 'ResumeSession', '2': '.iq.SessionRef', '3': '.iq.Session'},
    {'1': 'DeleteSession', '2': '.iq.SessionRef', '3': '.iq.SessionRef'},
    {'1': 'SendMessage', '2': '.iq.MessageRequest', '3': '.iq.Session'},
    {'1': 'GetActivity', '2': '.iq.SessionRef', '3': '.iq.Activity'},
    {'1': 'ListDirs', '2': '.iq.DirsRequest', '3': '.iq.Dirs'},
    {'1': 'Complete', '2': '.iq.CompleteRequest', '3': '.iq.CompleteResponse'},
  ],
};

@$core.Deprecated('Use harnessServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    HarnessServiceBase$messageJson = {
  '.iq.PingRequest': PingRequest$json,
  '.iq.PingResponse': PingResponse$json,
  '.iq.LoginRequest': LoginRequest$json,
  '.iq.LoginResponse': LoginResponse$json,
  '.iq.CreateSessionRequest': CreateSessionRequest$json,
  '.iq.Session': Session$json,
  '.iq.SessionRef': SessionRef$json,
  '.iq.ListRequest': ListRequest$json,
  '.iq.Sessions': Sessions$json,
  '.iq.WatchRequest': WatchRequest$json,
  '.iq.MessageRequest': MessageRequest$json,
  '.iq.Activity': Activity$json,
  '.iq.ActivityMessage': ActivityMessage$json,
  '.iq.DirsRequest': DirsRequest$json,
  '.iq.Dirs': Dirs$json,
  '.iq.CompleteRequest': CompleteRequest$json,
  '.iq.CompleteResponse': CompleteResponse$json,
};

/// Descriptor for `Harness`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List harnessServiceDescriptor = $convert.base64Decode(
    'CgdIYXJuZXNzEikKBFBpbmcSDy5pcS5QaW5nUmVxdWVzdBoQLmlxLlBpbmdSZXNwb25zZRIsCg'
    'VMb2dpbhIQLmlxLkxvZ2luUmVxdWVzdBoRLmlxLkxvZ2luUmVzcG9uc2USNgoNQ3JlYXRlU2Vz'
    'c2lvbhIYLmlxLkNyZWF0ZVNlc3Npb25SZXF1ZXN0GgsuaXEuU2Vzc2lvbhIpCgpHZXRTZXNzaW'
    '9uEg4uaXEuU2Vzc2lvblJlZhoLLmlxLlNlc3Npb24SLQoMTGlzdFNlc3Npb25zEg8uaXEuTGlz'
    'dFJlcXVlc3QaDC5pcS5TZXNzaW9ucxIvCgxXYXRjaFNlc3Npb24SEC5pcS5XYXRjaFJlcXVlc3'
    'QaCy5pcS5TZXNzaW9uMAESKgoLU3RvcFNlc3Npb24SDi5pcS5TZXNzaW9uUmVmGgsuaXEuU2Vz'
    'c2lvbhIsCg1SZXN1bWVTZXNzaW9uEg4uaXEuU2Vzc2lvblJlZhoLLmlxLlNlc3Npb24SLwoNRG'
    'VsZXRlU2Vzc2lvbhIOLmlxLlNlc3Npb25SZWYaDi5pcS5TZXNzaW9uUmVmEi4KC1NlbmRNZXNz'
    'YWdlEhIuaXEuTWVzc2FnZVJlcXVlc3QaCy5pcS5TZXNzaW9uEisKC0dldEFjdGl2aXR5Eg4uaX'
    'EuU2Vzc2lvblJlZhoMLmlxLkFjdGl2aXR5EiUKCExpc3REaXJzEg8uaXEuRGlyc1JlcXVlc3Qa'
    'CC5pcS5EaXJzEjUKCENvbXBsZXRlEhMuaXEuQ29tcGxldGVSZXF1ZXN0GhQuaXEuQ29tcGxldG'
    'VSZXNwb25zZQ==');
