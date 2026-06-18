package com.easemob.flutter_callkit

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.hyphenate.EMCallBack
import com.hyphenate.chat.EMClient
import com.hyphenate.chat.EMOptions
import com.hyphenate.callkit.CallKitClient
import com.hyphenate.callkit.CallKitConfig
import com.hyphenate.callkit.bean.CallEndReason
import com.hyphenate.callkit.bean.CallInfo
import com.hyphenate.callkit.bean.CallKitGroupInfo
import com.hyphenate.callkit.bean.CallKitUserInfo
import com.hyphenate.callkit.bean.CallType
import com.hyphenate.callkit.interfaces.CallInfoProvider
import com.hyphenate.callkit.interfaces.CallKitListener
import com.hyphenate.chat.EMUserInfo
import com.hyphenate.EMValueCallBack
import org.json.JSONObject
import org.json.JSONException

/** EasemobFlutterCallkitPlugin */
class EasemobFlutterCallkitPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "easemob_flutter_callkit")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "easemob_flutter_callkit/events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initIM" -> {
                val appKey = call.argument<String>("appKey")
                val autoLogin = call.argument<Boolean>("autoLogin") ?: false
                if (appKey == null) {
                    result.error("INVALID_ARGUMENT", "appKey is required", null)
                    return
                }
                val options = EMOptions().apply {
                    setAppKey(appKey)
                    setAutoLogin(autoLogin)
                }
                context?.let { ctx ->
                    EMClient.getInstance().init(ctx, options)
                    result.success(true)
                } ?: result.error("NO_CONTEXT", "Context is null", null)
            }
            "initCallKit" -> {
                try {
                    EMClient.getInstance().chatManager()
                } catch (e: Exception) {
                    result.error("IM_NOT_INITIALIZED", "Please call initIM() before initCallKit()", null)
                    return
                }
                val configMap = call.argument<Map<String, Any?>>("config")
                val config = CallKitConfig().apply {
                    configMap?.get("callTimeout")?.let {
                        callTimeout = (it as Number).toInt()
                    }
                    configMap?.get("incomingRingFile")?.let {
                        incomingRingFile = it as String
                    }
                    configMap?.get("outgoingRingFile")?.let {
                        outgoingRingFile = it as String
                    }
                    configMap?.get("dingRingFile")?.let {
                        dingRingFile = it as String
                    }
                }
                context?.let { ctx ->
                    try {
                        CallKitClient.init(ctx, config)
                        CallKitClient.callInfoProvider = DefaultCallInfoProvider()
                        setupCallKitListener()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INIT_CALLKIT_ERROR", e.message, null)
                    }
                } ?: result.error("NO_CONTEXT", "Context is null", null)
            }
            "login" -> {
                val username = call.argument<String>("username")
                val token = call.argument<String>("token")
                if (username == null || token == null) {
                    result.error("INVALID_ARGUMENT", "username and token are required", null)
                    return
                }
                EMClient.getInstance().loginWithToken(username, token, object : EMCallBack {
                    override fun onSuccess() {
                        result.success(true)
                    }
                    override fun onError(code: Int, error: String?) {
                        result.error("LOGIN_ERROR", error ?: "Unknown error", code)
                    }
                })
            }
            "loginWithPassword" -> {
                val username = call.argument<String>("username")
                val password = call.argument<String>("password")
                if (username == null || password == null) {
                    result.error("INVALID_ARGUMENT", "username and password are required", null)
                    return
                }
                EMClient.getInstance().login(username, password, object : EMCallBack {
                    override fun onSuccess() {
                        result.success(true)
                    }
                    override fun onError(code: Int, error: String?) {
                        result.error("LOGIN_ERROR", error ?: "Unknown error", code)
                    }
                })
            }
            "logout" -> {
                EMClient.getInstance().logout(true, object : EMCallBack {
                    override fun onSuccess() {
                        result.success(true)
                    }
                    override fun onError(code: Int, error: String?) {
                        result.error("LOGOUT_ERROR", error ?: "Unknown error", code)
                    }
                })
            }
            "startSingleCall" -> {
                val callType = call.argument<Int>("callType") ?: 0
                val userId = call.argument<String>("userId")
                val ext = call.argument<String>("ext")
                if (userId == null) {
                    result.error("INVALID_ARGUMENT", "userId is required", null)
                    return
                }
                val type = if (callType == 0) CallType.SINGLE_VOICE_CALL else CallType.SINGLE_VIDEO_CALL
                val extObj = ext?.let { parseExtToJSONObject(it) }
                CallKitClient.startSingleCall(type, userId, extObj)
                result.success(true)
            }
            "startGroupCall" -> {
                val groupId = call.argument<String>("groupId")
                val ext = call.argument<String>("ext")
                if (groupId == null) {
                    result.error("INVALID_ARGUMENT", "groupId is required", null)
                    return
                }
                val extObj = ext?.let { parseExtToJSONObject(it) }
                CallKitClient.startGroupCall(groupId, extObj)
                result.success(true)
            }
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun parseExtToMap(ext: String): Map<String, Any>? {
        return try {
            val json = JSONObject(ext)
            val map = mutableMapOf<String, Any>()
            val keys = json.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                map[key] = json.get(key)
            }
            map
        } catch (e: JSONException) {
            null
        }
    }

    private fun parseExtToJSONObject(ext: String): JSONObject? {
        return try {
            JSONObject(ext)
        } catch (e: JSONException) {
            null
        }
    }

    private fun setupCallKitListener() {
        CallKitClient.callKitListener = object : CallKitListener {
            override fun onReceivedCall(userId: String, callType: CallType, ext: JSONObject?) {
                val event = mapOf(
                    "event" to "onReceivedCall",
                    "callType" to callType.code,
                    "userId" to userId,
                    "ext" to ext?.toString()
                )
                sendEvent(event)
            }

            override fun onEndCallWithReason(reason: CallEndReason, callInfo: CallInfo?) {
                val event = mapOf(
                    "event" to "onEndCallWithReason",
                    "callType" to (callInfo?.callKitType?.code ?: -1),
                    "channelName" to (callInfo?.channelName ?: ""),
                    "reason" to reason.code,
                    "time" to (callInfo?.callTime ?: 0L)
                )
                sendEvent(event)
            }

            override fun onCallError(errorType: CallKitClient.CallErrorType, errorCode: Int, description: String?) {
                val event = mapOf(
                    "event" to "onCallError",
                    "code" to errorCode,
                    "description" to description
                )
                sendEvent(event)
            }

            override fun onRemoteUserJoined(userId: String, callType: CallType, channelName: String) {
                val event = mapOf(
                    "event" to "onRemoteUserJoined",
                    "channelName" to channelName,
                    "userId" to userId
                )
                sendEvent(event)
            }

            override fun onRemoteUserLeft(userId: String, callType: CallType, channelName: String) {
                val event = mapOf(
                    "event" to "onRemoteUserLeft",
                    "channelName" to channelName,
                    "userId" to userId
                )
                sendEvent(event)
            }

            override fun onRtcEngineCreated(engine: io.agora.rtc2.RtcEngine) {
                // Not forwarded to Dart by default
            }
        }
    }

    private fun sendEvent(event: Map<String, Any?>) {
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            eventSink?.success(event)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}

class DefaultCallInfoProvider : CallInfoProvider {
    override fun asyncFetchUsers(
        userIds: List<String>,
        onValueSuccess: com.hyphenate.callkit.interfaces.OnValueSuccess<List<CallKitUserInfo>>
    ) {
        EMClient.getInstance().userInfoManager().fetchUserInfoByAttribute(
            userIds.toTypedArray(),
            arrayOf(EMUserInfo.EMUserInfoType.NICKNAME, EMUserInfo.EMUserInfoType.AVATAR_URL),
            object : EMValueCallBack<Map<String, EMUserInfo>> {
                override fun onSuccess(value: Map<String, EMUserInfo>?) {
                    val userInfos = mutableListOf<CallKitUserInfo>()
                    value?.forEach { (userId, info) ->
                        userInfos.add(CallKitUserInfo(
                            userId = userId,
                            nickName = info.nickname,
                            avatar = info.avatarUrl
                        ))
                    }
                    onValueSuccess(userInfos)
                }

                override fun onError(error: Int, errorMsg: String?) {
                    onValueSuccess(emptyList())
                }
            }
        )
    }

    override fun asyncFetchGroupInfo(
        groupId: String,
        onValueSuccess: com.hyphenate.callkit.interfaces.OnValueSuccess<CallKitGroupInfo>
    ) {
        val groups = EMClient.getInstance().groupManager().allGroups
        val group = groups?.find { it.groupId == groupId }
        val groupInfo = CallKitGroupInfo(
            groupID = groupId,
            groupName = group?.groupName,
            groupAvatar = group?.getGroupAvatar()
        )
        onValueSuccess(groupInfo)
    }
}
