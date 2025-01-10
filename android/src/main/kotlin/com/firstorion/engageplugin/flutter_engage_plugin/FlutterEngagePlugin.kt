package com.firstorion.engageplugin.flutter_engage_plugin

import android.content.Context
import android.util.Log
import com.firstorion.engage.core.EngageApp
import com.firstorion.engage.core.challenge.EngageRegistrationError
import com.firstorion.engage.core.challenge.EngageRegistrationHandler
import com.firstorion.engage.core.challenge.EngageSmsRegistration
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterEngagePlugin */
class FlutterEngagePlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var methodChannel: MethodChannel

    private lateinit var registrationEventChannel: EventChannel

    private var registerEventSink: EventChannel.EventSink? = null

    private val methodChannelName = "flutter_engage_plugin"

    private val registrationEventChannelName = "engage_registration_events"

    private var context: Context? = null



    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, methodChannelName)
        methodChannel.setMethodCallHandler(this)

        context = flutterPluginBinding.applicationContext

        registrationEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, registrationEventChannelName)
        registrationEventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    registerEventSink = events
                    println("Android Event Channel Activate")
                }

                override fun onCancel(arguments: Any?) {
                    registerEventSink = null;
                }

            }
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        registrationEventChannel.setStreamHandler(null)
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val method = call.method
        Log.i("FlutterEngagePlugin", "Android Engage SDK received method call: $method")
        when (method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
//            "configureSDK" -> {
//                context?.apply {
//                    Log.i("FlutterEngagePlugin", "Initializing Engage SDK...")
//                    EngageApp.initializeEngage(this)
//                    EngageApp.initializeEngageForFlutterFirebase(this)
//                } ?: Log.e("FlutterEngagePlugin", "Unable to initialize Engage SDK. Context is null.")
//                result.success(null)
//            }
            "register" -> {
                register(call)
                result.success(null)
            }

            "completeChallengeWithCode" ->{
                EngageSmsRegistration.completeWithCode(call.argument<String>("userInput")!!)
                result.success(null)
            }

            "isEngagePush" ->{
                val remoteMessageData = call.argument<HashMap<String, String >>("pushData")
                result.success(EngageApp.isEngageMessage(remoteMessageData))
            }
            "handlePushNotification" ->{
                val remoteMessageData = call.argument<Map<String, String >>("pushData")
                if (remoteMessageData != null) {
                    EngageApp.getInstance().handlePushMessage(remoteMessageData)
                    result.success(null)
                }else{
                    Log.e("FlutterEngagePlugin", "Android Engage SDK cannot handle push. pushData is null.")
                    result.success(null)
                }
            }
            "contactPermissionsUpdated" -> {
                EngageApp.getInstance().onPermissionChanged()
                result.success(null)
            }
            "providePushTokenToSDK" -> {
                val token = call.argument<String>("token") ?: ""
                EngageApp.getInstance().onCustomTokenRefreshed(token)
            }
            else -> {
                result.notImplemented()
            }

        }
    }

    private fun register(call: MethodCall)  {

        val registrationHandler = object : EngageRegistrationHandler{

            override fun onInitializationSuccess(userNumber: String?) {
                registerEventSink?.success(
                    mapOf(
                        "eventName" to "onInitializationSuccess",
                        "userNumber" to userNumber
                    )
                )
                println("Android onInitializationSuccess $userNumber")
            }

            override fun onRegistrationFailure(
                phoneNumber: String?,
                error: EngageRegistrationError
            ) {
                registerEventSink?.success(
                    mapOf(
                        "eventName" to "onRegistrationFailure",
                        "phoneNumber" to phoneNumber,
                        "error" to error.name
                    )
                )
            }

            override fun onRegistrationSuccess(userNumber: String) {
                registerEventSink?.success(
                    mapOf(
                        "eventName" to "onRegistrationSuccess",
                        "userNumber" to userNumber,
                    )
                )
                println("Android onRegistrationSuccess $userNumber")
            }
        }

        val phonenumber = call.argument<String>("phoneNumber")!!
        println("Android register $phonenumber")
        try {
            EngageApp.getInstance().register(phonenumber, registrationHandler)
        } catch (e: NullPointerException){
            Log.e("FlutterEngagePlugin",
                "$e is thrown. Unable to register. Engage instance has not yet been initialized.")
            registrationHandler.onRegistrationFailure(phonenumber, EngageRegistrationError.RESTRICTED)
        } catch (e: Exception){
            Log.e("FlutterEngagePlugin", "$e is thrown. Unable to register.")
            registrationHandler.onRegistrationFailure(phonenumber, EngageRegistrationError.RESTRICTED)
        }

    }

}
