import 'easemob_flutter_callkit_platform_interface.dart';
export 'easemob_flutter_callkit_platform_interface.dart'
    show CallKitConfig, CallType;

class EasemobFlutterCallkit {
  /// Initialize the Easemob IM SDK.
  ///
  /// [appKey] is required. Set [autoLogin] to true to enable automatic login.
  static Future<bool> initIM(String appKey, {bool autoLogin = false}) {
    return EasemobFlutterCallkitPlatform.instance.initIM(appKey, autoLogin: autoLogin);
  }

  /// Initialize the CallKit module.
  ///
  /// Must be called after [initIM].
  static Future<bool> initCallKit(CallKitConfig config) {
    return EasemobFlutterCallkitPlatform.instance.initCallKit(config);
  }

  /// Login with username and token.
  static Future<bool> login(String username, String token) {
    return EasemobFlutterCallkitPlatform.instance.login(username, token);
  }

  /// Login with username and password.
  static Future<bool> loginWithPassword(String username, String password) {
    return EasemobFlutterCallkitPlatform.instance.loginWithPassword(username, password);
  }

  /// Logout the current user.
  static Future<bool> logout() {
    return EasemobFlutterCallkitPlatform.instance.logout();
  }

  /// Start a 1v1 call.
  ///
  /// [callType] defaults to [CallType.voice].
  static Future<bool> startSingleCall(
    String userId, {
    CallType callType = CallType.voice,
    String? ext,
  }) {
    return EasemobFlutterCallkitPlatform.instance
        .startSingleCall(userId, callType: callType, ext: ext);
  }

  /// Start a group call.
  static Future<bool> startGroupCall(String groupId, {String? ext}) {
    return EasemobFlutterCallkitPlatform.instance.startGroupCall(groupId, ext: ext);
  }

  /// Stream of call events from the native side.
  ///
  /// Events include:
  /// - `onReceivedCall`
  /// - `onEndCallWithReason`
  /// - `onCallError`
  /// - `onRemoteUserJoined`
  /// - `onRemoteUserLeft`
  static Stream<Map<String, dynamic>> get callEvents {
    return EasemobFlutterCallkitPlatform.instance.callEvents;
  }

  /// Get the platform version (for debugging).
  static Future<String?> getPlatformVersion() {
    return EasemobFlutterCallkitPlatform.instance.getPlatformVersion();
  }

}
