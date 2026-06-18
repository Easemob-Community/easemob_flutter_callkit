import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'easemob_flutter_callkit_method_channel.dart';

abstract class EasemobFlutterCallkitPlatform extends PlatformInterface {
  EasemobFlutterCallkitPlatform() : super(token: _token);

  static final Object _token = Object();

  static EasemobFlutterCallkitPlatform _instance =
      MethodChannelEasemobFlutterCallkit();

  static EasemobFlutterCallkitPlatform get instance => _instance;

  static set instance(EasemobFlutterCallkitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<bool> initIM(String appKey, {bool autoLogin = false}) {
    throw UnimplementedError('initIM() has not been implemented.');
  }

  Future<bool> initCallKit(CallKitConfig config) {
    throw UnimplementedError('initCallKit() has not been implemented.');
  }

  Future<bool> login(String username, String token) {
    throw UnimplementedError('login() has not been implemented.');
  }

  Future<bool> loginWithPassword(String username, String password) {
    throw UnimplementedError('loginWithPassword() has not been implemented.');
  }

  Future<bool> logout() {
    throw UnimplementedError('logout() has not been implemented.');
  }

  Future<bool> startSingleCall(String userId,
      {CallType callType = CallType.voice, String? ext}) {
    throw UnimplementedError('startSingleCall() has not been implemented.');
  }

  Future<bool> startGroupCall(String groupId, {String? ext}) {
    throw UnimplementedError('startGroupCall() has not been implemented.');
  }

  Stream<Map<String, dynamic>> get callEvents {
    throw UnimplementedError('callEvents has not been implemented.');
  }
}

enum CallType {
  voice,
  video,
}

class CallKitConfig {
  final int? callTimeout;
  final String? incomingRingFile;
  final String? outgoingRingFile;
  final String? dingRingFile;

  CallKitConfig({
    this.callTimeout,
    this.incomingRingFile,
    this.outgoingRingFile,
    this.dingRingFile,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (callTimeout != null) 'callTimeout': callTimeout,
      if (incomingRingFile != null) 'incomingRingFile': incomingRingFile,
      if (outgoingRingFile != null) 'outgoingRingFile': outgoingRingFile,
      if (dingRingFile != null) 'dingRingFile': dingRingFile,
    };
  }
}
