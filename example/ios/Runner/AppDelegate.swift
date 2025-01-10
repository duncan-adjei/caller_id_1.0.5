import UIKit
import Flutter
import EngageKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private var deviceTokenMethodChannel: FlutterMethodChannel?
    private var pushDataMethodChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Engage.logVerbosity = .verbose
        GeneratedPluginRegistrant.register(with: self)
        // Set up the method channel
        if let controller = window?.rootViewController as? FlutterViewController {
            deviceTokenMethodChannel = FlutterMethodChannel(
                name: "ios_device_token_channel",
                binaryMessenger: controller.binaryMessenger
            )
            pushDataMethodChannel = FlutterMethodChannel(
                name: "push_data_channel",
                binaryMessenger: controller.binaryMessenger
            )
        }
        UIApplication.shared.registerForRemoteNotifications()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        deviceTokenMethodChannel?.invokeMethod("providePushTokenToSDK", arguments: tokenString)
    }

    override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        pushDataMethodChannel?.invokeMethod("handlePushNotification", arguments: userInfo)
    }
    
    override func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any]
    ) {
        pushDataMethodChannel?.invokeMethod("handlePushNotification", arguments: userInfo)
    }
}
