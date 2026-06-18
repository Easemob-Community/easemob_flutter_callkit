import 'package:flutter_test/flutter_test.dart';
import 'package:easemob_flutter_callkit/easemob_flutter_callkit.dart';
import 'package:easemob_flutter_callkit/easemob_flutter_callkit_platform_interface.dart';
import 'package:easemob_flutter_callkit/easemob_flutter_callkit_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEasemobFlutterCallkitPlatform
    with MockPlatformInterfaceMixin
    implements EasemobFlutterCallkitPlatform {
  @override
  Future<String?> getPlatformVersion() async => '1.0.0';

  @override
  Future<bool> initIM(String appKey, {bool autoLogin = false}) async => true;

  @override
  Future<bool> initCallKit(CallKitConfig config) async => true;

  @override
  Future<bool> login(String username, String token) async => true;

  @override
  Future<bool> logout() async => true;

  @override
  Future<bool> startSingleCall(String userId,
      {CallType callType = CallType.voice, String? ext}) async => true;

  @override
  Future<bool> startGroupCall(String groupId, {String? ext}) async => true;

  @override
  Stream<Map<String, dynamic>> get callEvents =>
      Stream<Map<String, dynamic>>.empty();
}

void main() {
  final EasemobFlutterCallkitPlatform initialPlatform =
      EasemobFlutterCallkitPlatform.instance;

  test('$MethodChannelEasemobFlutterCallkit is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEasemobFlutterCallkit>());
  });

  test('getPlatformVersion', () async {
    MockEasemobFlutterCallkitPlatform fakePlatform =
        MockEasemobFlutterCallkitPlatform();
    EasemobFlutterCallkitPlatform.instance = fakePlatform;

    expect(await EasemobFlutterCallkit.getPlatformVersion(), '1.0.0');
  });

  test('initIM', () async {
    MockEasemobFlutterCallkitPlatform fakePlatform =
        MockEasemobFlutterCallkitPlatform();
    EasemobFlutterCallkitPlatform.instance = fakePlatform;

    expect(await EasemobFlutterCallkit.initIM('test-app-key'), true);
  });

  test('startSingleCall', () async {
    MockEasemobFlutterCallkitPlatform fakePlatform =
        MockEasemobFlutterCallkitPlatform();
    EasemobFlutterCallkitPlatform.instance = fakePlatform;

    expect(
        await EasemobFlutterCallkit.startSingleCall('user1',
            callType: CallType.video),
        true);
  });
}
