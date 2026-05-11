package com.famedly.fcm_shared_isolate

import androidx.annotation.NonNull
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FcmSharedIsolatePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    private var fcmInitError: Exception? = null
    private val fcm = try {
        FirebaseMessaging.getInstance()
    } catch (e: Exception) {
        fcmInitError = e
        null
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "fcm_shared_isolate")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (fcm == null) {
            val initError = fcmInitError
            result.error(
                "fcm_unavailable",
                initError?.localizedMessage ?: "FirebaseMessaging is not available",
                initError?.let {
                    mapOf(
                        "exceptionType" to it.javaClass.name,
                        "message" to (it.localizedMessage ?: it.message),
                        "cause" to it.cause?.toString(),
                    )
                }
            )
            return
        }

        if (call.method == "getToken") {
            val getToken = fcm.getToken()
            getToken.addOnSuccessListener { result.success(it) }
            getToken.addOnFailureListener { error ->
                result.error(
                    "fcm_get_token_failed",
                    error.localizedMessage ?: "Failed to fetch Firebase token",
                    mapOf(
                        "exceptionType" to error.javaClass.name,
                        "message" to (error.localizedMessage ?: error.message),
                        "cause" to error.cause?.toString(),
                    )
                )
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    fun message(@NonNull data: Map<String, String>) {
        channel.invokeMethod("message", data)
    }

    fun token(@NonNull str: String) {
        channel.invokeMethod("token", str)
    }
}
