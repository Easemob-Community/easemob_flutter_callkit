import Flutter
import UIKit
import EaseCallUIKit
import HyphenateChat
import AgoraRtcKit

public class EasemobFlutterCallkitPlugin: NSObject, FlutterPlugin {
    private var eventSink: FlutterEventSink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "easemob_flutter_callkit", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "easemob_flutter_callkit/events", binaryMessenger: registrar.messenger())

        let instance = EasemobFlutterCallkitPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initIM":
            guard let args = call.arguments as? [String: Any],
                  let appKey = args["appKey"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "appKey is required", details: nil))
                return
            }
            let autoLogin = args["autoLogin"] as? Bool ?? false
            let options = EMOptions(appkey: appKey)
            options.isAutoLogin = autoLogin
            EMClient.shared().initializeSDK(with: options)
            result(true)

        case "initCallKit":
            let config = EaseCallUIKit.CallKitConfig()
            config.enableVOIP = true
            config.enablePIPOn1V1VideoScene = true
            if let args = call.arguments as? [String: Any],
               let configMap = args["config"] as? [String: Any] {
                if let timeout = configMap["callTimeout"] as? Int {
                    // CallKitConfig doesn't expose direct timeout setter in public API, keep for Dart layer
                }
            }
            CallKitManager.shared.setup(config)
            CallKitManager.shared.profileProvider = self
            setupListeners()
            result(true)

        case "login":
            guard let args = call.arguments as? [String: Any],
                  let username = args["username"] as? String,
                  let token = args["token"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "username and token are required", details: nil))
                return
            }
            EMClient.shared().login(withUsername: username, token: token) { username, error in
                if let error = error {
                    result(FlutterError(code: "LOGIN_ERROR", message: error.errorDescription, details: error.code))
                } else {
                    result(true)
                }
            }

        case "loginWithPassword":
            guard let args = call.arguments as? [String: Any],
                  let username = args["username"] as? String,
                  let password = args["password"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "username and password are required", details: nil))
                return
            }
            EMClient.shared().login(withUsername: username, password: password) { username, error in
                if let error = error {
                    result(FlutterError(code: "LOGIN_ERROR", message: error.errorDescription, details: error.code))
                } else {
                    result(true)
                }
            }

        case "logout":
            EMClient.shared().logout(true) { error in
                if let error = error {
                    result(FlutterError(code: "LOGOUT_ERROR", message: error.errorDescription, details: error.code))
                } else {
                    result(true)
                }
            }

        case "startSingleCall":
            guard let args = call.arguments as? [String: Any],
                  let callTypeInt = args["callType"] as? Int,
                  let userId = args["userId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "callType and userId are required", details: nil))
                return
            }
            let type: CallType = (callTypeInt == 0) ? .singleAudio : .singleVideo
            CallKitManager.shared.call(with: userId, type: type)
            result(true)

        case "startGroupCall":
            guard let args = call.arguments as? [String: Any],
                  let groupId = args["groupId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "groupId is required", details: nil))
                return
            }
            CallKitManager.shared.groupCall(groupId: groupId)
            result(true)

        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setupListeners() {
        CallKitManager.shared.addListener(self)
    }

    private func sendEvent(_ event: [String: Any?]) {
        eventSink?(event)
    }

    private func callInfoToDict(_ info: CallInfo?) -> [String: Any?]? {
        guard let info = info else { return nil }
        return [
            "callId": info.callId,
            "callerId": info.callerId,
            "calleeId": info.calleeId,
            "channelName": info.channelName,
            "type": info.type.rawValue,
            "duration": info.duration,
            "groupId": info.groupId,
            "extensionInfo": info.extensionInfo,
        ]
    }
}

extension EasemobFlutterCallkitPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

extension EasemobFlutterCallkitPlugin: CallServiceListener {
    public func onReceivedCall(callType: CallType, userId: String, extensionInfo: [String : Any]?) {
        sendEvent([
            "event": "onReceivedCall",
            "callType": callType.rawValue,
            "userId": userId,
            "ext": extensionInfo
        ])
    }
    public func didOccurError(error: CallError) {
        sendEvent([
            "event": "onCallError",
            "code": error.error.errorCode,
            "description": error.errorMessage
        ])
    }

    public func didUpdateCallEndReason(reason: CallEndReason, info: CallInfo) {
        sendEvent([
            "event": "onEndCallWithReason",
            "reason": reason.rawValue,
            "info": callInfoToDict(info)
        ])
    }

    public func remoteUserDidJoined(userId: String, channelName: String, type: CallType) {
        sendEvent([
            "event": "onRemoteUserJoined",
            "userId": userId,
            "channelName": channelName,
            "callType": type.rawValue
        ])
    }

    public func remoteUserDidLeft(userId: String, channelName: String, type: CallType) {
        sendEvent([
            "event": "onRemoteUserLeft",
            "userId": userId,
            "channelName": channelName,
            "callType": type.rawValue
        ])
    }

    public func onRtcEngineCreated(engine: AgoraRtcEngineKit) {
        // Allow users to configure engine through Dart layer if needed
    }
}

extension EasemobFlutterCallkitPlugin: CallUserProfileProvider {
    public func fetchUserProfiles(profileIds: [String]) async -> [any CallProfileProtocol] {
        var resultProfiles: [any CallProfileProtocol] = []
        var unknownIds: [String] = []
        for profileId in profileIds {
            if let profile = CallKitManager.shared.usersCache[profileId] {
                resultProfiles.append(profile)
            } else {
                unknownIds.append(profileId)
            }
        }
        guard !unknownIds.isEmpty else {
            return resultProfiles
        }
        let userInfos = await withCheckedContinuation { (continuation: CheckedContinuation<[String: EMUserInfo]?, Never>) in
            EMClient.shared().userInfoManager?.fetchUserInfo(byId: unknownIds) { infos, _ in
                continuation.resume(returning: infos)
            }
        }
        if let infoMap = userInfos {
            for (userId, info) in infoMap {
                let profile = CallUserProfile()
                profile.id = userId
                profile.nickname = info.nickname ?? ""
                profile.avatarURL = info.avatarUrl ?? ""
                resultProfiles.append(profile)
            }
        }
        return resultProfiles
    }

    public func fetchGroupProfiles(profileIds: [String]) async -> [any CallProfileProtocol] {
        var resultProfiles: [any CallProfileProtocol] = []
        let groups = EMClient.shared().groupManager?.getJoinedGroups() ?? []
        for groupId in profileIds {
            if let group = groups.first(where: { $0.groupId == groupId }) {
                let profile = CallUserProfile()
                profile.id = groupId
                profile.nickname = group.groupName
                profile.avatarURL = group.groupAvatar ?? ""
                resultProfiles.append(profile)
            }
        }
        return resultProfiles
    }
}
