library engage;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_engage_plugin/Handler/engage_registration_handler.dart';
import 'package:flutter_engage_plugin/utils/const.dart';
import 'package:flutter_engage_plugin/utils/helper_methods.dart';

// Include parts of the library
part 'engage_phone_registration.dart';

class Engage {
  // Make Engage a Singleton
  static final Engage _instance = Engage._internal();
  static Engage get instance => _instance;
  Engage._internal() {
    iosDeviceTokenChannel.setMethodCallHandler(_handleDeviceToken);
    pushDataChannel.setMethodCallHandler(_handlePushData);
  }

  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_engage_plugin');
  final iosDeviceTokenChannel = const MethodChannel('ios_device_token_channel');
  final pushDataChannel = const MethodChannel('push_data_channel');

  final engagePhoneRegister = _EngagePhoneRegistration();

  // set up iosDeviceTokenChannel to receive device token
  static Future<void> _handleDeviceToken(MethodCall call) async {
    if (call.method == 'providePushTokenToSDK') {
      String token = call.arguments;
      Engage.instance.providePushTokenToSDK(token);
    }
  }

  // set up pushDataChannel to receive PushNotifications
  static Future<void> _handlePushData(MethodCall call) async {
    if (call.method == 'handlePushNotification') {
      dynamic pushData = call.arguments;
      Engage.instance.handlePushNotification(pushData);
    }
  }

  /// Initialize and configure the Engage SDK.
  Future<void> configureEngageForIOS(EngageEnvironment? environment, String? appGroup) {
    return methodChannel.invokeMethod("configureSDK", {
      'environment': environment?.rawValue ?? EngageEnvironment.debug.rawValue,
      'appGroup': appGroup
    });
  }

  /// Provides the APNs token to Engage SDK
  Future<void> providePushTokenToSDK(String token) {
    return methodChannel
        .invokeMethod("providePushTokenToSDK", {'token': token});
  }

  /// Registers the phone number with the Engage service.
  ///
  /// This method registers the provided [phoneNumber] with the Engage service
  /// and handles the registration process using the provided
  /// [engageRegistrationHandler].
  ///
  /// The [phoneNumber] parameter is the phone number to be registered.
  /// The [engageRegistrationHandler] parameter is an instance of [EngageRegistrationHandler]
  /// which handles the success and failure callbacks of the registration process.
  /// Sends the challenge to the specified number **(must be in E164 format)**, through the channel specified in the configuration passed to the SDK.
  void register({
    required String phoneNumber,
    required EngageRegistrationHandler engageRegistrationHandler,
  }) {
    engagePhoneRegister.register(phoneNumber, engageRegistrationHandler);
  }

  

  /// Attempts to complete the challenge using the provided `userInput`.
  void completeChallengeWithCode(
      String userInput, Function(String?)? onChallengeSuccess) {
    engagePhoneRegister.onChallengeSuccessCallback((userNumber) {
      onChallengeSuccess?.call(userNumber);
    }).completeChallengeWithCode(userInput);
  }

  /// Informs Engage SDK that the user has set contact permissions.
  // void onPermissionChanged() {
  //   methodChannel.invokeMethod("onPermissionChanged");
  // }

  /// Determine if push message is an Engage push. This method should be called on every push message received by the main hosting application, not the Notification Service Extension.
  /// - parameter pushData: The push payload
  /// - Returns: True if deemed an EngagePush
  Future<bool> isEngagePush(Map<dynamic, dynamic> pushData) async {
    return await methodChannel
            .invokeMethod("isEngagePush", {'pushData': pushData}) ??
        false;
  }

  /// Handles the push notification received by the host app. Should be used only with Engage Push
  /// use 'isEngagePush' to determine if push is an Engage push.
  Future<void> handlePushNotification(Map<dynamic, dynamic> pushData) async {
    return methodChannel
        .invokeMethod("handlePushNotification", {'pushData': pushData});
  }

  /// Informs Engage SDK that the user has set contact permissions.
  /// This method should be called after the user has completed the contact permission prompt.
  Future<void> contactPermissionsUpdated() async {
    return await methodChannel.invokeMethod("contactPermissionsUpdated");
  }
}
