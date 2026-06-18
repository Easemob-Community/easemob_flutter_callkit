import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'easemob_flutter_callkit_platform_interface.dart';

class MethodChannelEasemobFlutterCallkit extends EasemobFlutterCallkitPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('easemob_flutter_callkit');

  @visibleForTesting
  final eventChannel = const EventChannel('easemob_flutter_callkit/events');

  Stream<Map<String, dynamic>>? _callEventsStream;

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> initIM(String appKey, {bool autoLogin = false}) async {
    final result = await methodChannel.invokeMethod<bool>('initIM', {
      'appKey': appKey,
      'autoLogin': autoLogin,
    });
    return result ?? false;
  }

  @override
  Future<bool> initCallKit(CallKitConfig config) async {
    final result = await methodChannel.invokeMethod<bool>('initCallKit', {
      'config': config.toMap(),
    });
    return result ?? false;
  }

  @override
  Future<bool> login(String username, String token) async {
    final result = await methodChannel.invokeMethod<bool>('login', {
      'username': username,
      'token': token,
    });
    return result ?? false;
  }

  @override
  Future<bool> loginWithPassword(String username, String password) async {
    final result = await methodChannel.invokeMethod<bool>('loginWithPassword', {
      'username': username,
      'password': password,
    });
    return result ?? false;
  }

  @override
  Future<bool> logout() async {
    final result = await methodChannel.invokeMethod<bool>('logout');
    return result ?? false;
  }

  @override
  Future<bool> startSingleCall(
    String userId, {
    CallType callType = CallType.voice,
    String? ext,
  }) async {
    final result = await methodChannel.invokeMethod<bool>('startSingleCall', {
      'userId': userId,
      'callType': callType.index,
      'ext': ext,
    });
    return result ?? false;
  }

  @override
  Future<bool> startGroupCall(String groupId, {String? ext}) async {
    final result = await methodChannel.invokeMethod<bool>('startGroupCall', {
      'groupId': groupId,
      'ext': ext,
    });
    return result ?? false;
  }

  @override
  Stream<Map<String, dynamic>> get callEvents {
    _callEventsStream ??= eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
    return _callEventsStream!;
  }

}
