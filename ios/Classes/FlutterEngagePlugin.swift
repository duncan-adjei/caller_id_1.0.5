//
//  FlutterEngagePlugin.swift
//  flutter_engage_plugin
//
//  Created by Oleg McNamara on 2/18/24.
//

import Flutter
import UIKit
import EngageKit

// Reading push type from config file
let isPushChallenge: Bool = {
    guard let path = Bundle.main.path(forResource: "engage-config", ofType: "json"),
          let jsonResult = try? (JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))) as! Dictionary<String, AnyObject>),
        let challengeType = jsonResult["engageChallengeType"] as? String else { return false }
    
    return challengeType == "push"
}()

/// `FlutterEngagePlugin` is a Flutter plugin for handling engage-related functionalities.
/// It conforms to `FlutterPlugin` and `FlutterStreamHandler` to handle method calls and stream events from Flutter.
public class FlutterEngagePlugin: NSObject {
    
    /// The Flutter event channel for registration events.
    private var registrationEventChannel: FlutterEventChannel?
    /// The Flutter event channel for unregistration events.
    private var unRegistrationEventChannel: FlutterEventChannel?
    /// The Flutter event channel for number change events.
    private var changeNumberEventChannel: FlutterEventChannel?
    
    /// The event sink for registration events.
    private var registrationEventSink: FlutterEventSink?
    /// The event sink for unregistration events.
    private var unRegistrationEventSink: FlutterEventSink?
    /// The event sink for number change events.
    private var changeNumberEventSink: FlutterEventSink?
    
    /// Handles method calls from Flutter.
    /// - Parameters:
    ///   - call: The method call from Flutter.
    ///   - result: The result callback to send data or error back to Flutter.
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case EngageMethods.configureSDK.rawValue:
            guard
                let arguments = call.arguments as? [String : Any],
                let environment = arguments["environment"] as? String,
                let flutterEngageEnvironment = FlutterEngageEnvironment.init(rawValue: environment) else {
                result(false)
                return
            }
            let group = arguments["appGroup"] as? String ?? ""
            configure(flutterEngageEnvironment, group, result)
        case EngageMethods.providePushTokenToSDK.rawValue:
            guard
                let arguments = call.arguments as? [String : Any],
                let tokenString = arguments["token"] as? String else {
                result(false)
                return
            }
            // Convert the hex string back to Data
            var data = Data()
            var hex = tokenString
            while hex.count > 0 {
                let subIndex = hex.index(hex.startIndex, offsetBy: 2)
                let c = String(hex[..<subIndex])
                hex = String(hex[subIndex...])
                if var hexValue = UInt8(c, radix: 16) {
                    data.append(&hexValue, count: 1)
                } else {
                    result(FlutterError(code: "INVALID_TOKEN", message: "Invalid token string", details: nil))
                    return
                }
            }
            provideAPNsPushTokenToSDK(data, result)
        case EngageMethods.sendChallenge.rawValue:
            guard
                let arguments = call.arguments as? [String : Any],
                let phoneNumber = arguments["phoneNumber"] as? String else {
                result(false)
                return
            }
            sendChallenge(phoneNumber) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    let engageRegistrationError = mapEngageError(error: error)
                    let eventInfo = [
                        "userNumber": phoneNumber,
                        "error": engageRegistrationError.rawValue
                    ]
                    let eventData = FlutterEventData(
                        eventType: .onRegistrationFailure,
                        eventInfo: eventInfo
                    )
                    self.sendEvent(event: self.registrationEventSink, eventData: eventData)
                    result(false)
                } else {
                    let eventData = FlutterEventData(
                        eventType: .onInitializationSuccess,
                        eventInfo: ["userNumber": phoneNumber]
                    )
                    self.sendEvent(event: self.registrationEventSink, eventData: eventData)
                    // For push challenges need to execute onRegistrationSuccess event
                    if isPushChallenge {
                        let eventData = FlutterEventData(
                            eventType: .onRegistrationSuccess,
                            eventInfo: ["userNumber": phoneNumber]
                        )
                        self.sendEvent(event: self.registrationEventSink, eventData: eventData)
                    }
                    result(true)
                }
            }
        case EngageMethods.completeChallengeWithCode.rawValue:
            guard
                let arguments = call.arguments as? [String : Any],
                let userInput = arguments["userInput"] as? String else {
                result(false)
                return
            }
            completeChallenge(userInput) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    let engageRegistrationError = mapEngageError(error: error)
                    let eventInfo = [
                        "userNumber": "",
                        "error": engageRegistrationError.rawValue
                    ]
                    let eventData = FlutterEventData(
                        eventType: .onRegistrationFailure,
                        eventInfo: eventInfo
                    )
                    self.sendEvent(event: self.registrationEventSink, eventData: eventData)
                    result(false)
                } else {
                    let eventData = FlutterEventData(
                        eventType: .onRegistrationSuccess,
                        eventInfo: ["userNumber": ""]
                    )
                    self.sendEvent(event: self.registrationEventSink, eventData: eventData)
                    result(true)
                }
            }
        case EngageMethods.isEngagePush.rawValue:
            guard
                let arguments = call.arguments as? [String : Any],
                let pushData = arguments["pushData"] as? [String: Any] else {
                result(false)
                return
            }
            let isEngagePush = isEngagePush(pushData)
            result(isEngagePush)
        case EngageMethods.handleMainAppPushNotification.rawValue:
            guard
                let arguments = call.arguments as? [String : Any],
                let pushData = arguments["pushData"] as? [String: Any] else {
                result(false)
                return
            }
            let isEngagePush = isEngagePush(pushData)
            
            guard isEngagePush else { result(false); return }
            handleEngagePayload(pushData) { result(true) }
        case EngageMethods.contactPermissionsUpdated.rawValue:
            contactPermissionsUpdated()
        case EngageMethods.hasContactsPermission.rawValue:
            result(hasContactsPermission())
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func sendEvent(event: FlutterEventSink?, eventData: FlutterEventData) {
        event?(eventData.toDictionary())
    }
    
    /// Initialize and configure the Engage SDK.
    /// - Parameter environment: The specified ``FlutterEngageEnvironment``.
    /// - Parameter appGroup: The id associated with app group.
    public func configure(
        _ environment: FlutterEngageEnvironment,
        _ group: String,
        _ result: @escaping FlutterResult) {
            
            DispatchQueue.global(qos: .userInitiated).async {
                Engage.shared.configureSDK(for: environment.toEngageEnvironment(), with: group)
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    result(true)
                }
            }
    }
    
    /// Provides the APNs push token to the Engage SDK.
    /// - Parameters:
    ///   - token: The push token received from APNs. This is a `Data` object that uniquely identifies the device to APNs.
    ///   - result: A closure to be executed once the token has been successfully provided to the SDK. It returns `true` upon successful execution.
    public func provideAPNsPushTokenToSDK(_ token: Data, _ result: @escaping FlutterResult) {
        Engage.shared.provideAPNsPushTokenToSDK(token)
        result(true)
    }
    
    /// Sends the challenge to the specified number **(must be in E164 format)**, through the channel specified in the configuration passed to the SDK.
    /// - parameter phoneNumber: The phone number for the challenge to be sent to in E164 format.
    /// - parameter completion: A completion handler for capturing the completion result.
    public func sendChallenge(
        _ phoneNumber: String,
        completion: @escaping (_ error: EngageError?) -> Void) {
            
            Engage.shared.sendChallenge(phoneNumber, completion: completion)
    }
    
    /// Attempts to complete the challenge using the provided `userInput`.
    /// - Parameters:
    ///   - userInput: The SMS verification code entered by the user.
    ///   - completion: A completion handler for capturing the EngageError.
    ///
    /// Should only be used for SMS challenges, not push challenges.
    public func completeChallenge(
        _ userInput: String,
        completion: @escaping (_ error: EngageError?) -> Void) {
            
            Engage.shared.completeChallenge(userInput: userInput, completion: completion)
    }
    
    /// Determine if push message is an Engage push. This method should be called on every push message received by the main hosting application, not the Notification Service Extension.
    /// - parameter payload: The push payload, received as the userInfo in the delegate method.
    /// - Returns: True if deemed an EngagePayload
    ///
    /// This should be called from the AppDelegate method.
    /// - func application( _ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    public func isEngagePush(_ payload: [AnyHashable: Any]?) -> Bool {
        Engage.shared.isEngagePayload(payload)
    }
    
    /// Handles the push notification received by the host app. Should be used only with Engage Push
    public func handleEngagePayload(
        _ payload: [AnyHashable : Any]?,
        _ completionHandler: @escaping () -> Void) {
            Engage.shared.handleEngagePayload(payload, completionHandler)
    }
    
    /// Informs Engage SDK that the user has set contact permissions.
    /// This method should be called after the user has completed the contact permission prompt.
    public func contactPermissionsUpdated() {
        Engage.shared.contactPermissionsUpdated()
    }
    
    /// Whether or not the user has granted contacts permission for this application.
    public func hasContactsPermission() -> Bool {
        Engage.shared.hasContactsPermission
    }
    
}

/// Extension of FlutterEngagePlugin to conform to FlutterPlugin protocol.
/// This extension handles the registration of the plugin with Flutter's plugin system.
extension FlutterEngagePlugin: FlutterPlugin {
    
    /// Registers the plugin with the Flutter PluginRegistrar. This method is invoked
    /// when the plugin is initially loaded by the Flutter framework.
    /// - Parameter registrar: The Flutter plugin registrar that is used for registering
    ///   channels and initializing the plugin.
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_engage_plugin",
            binaryMessenger: registrar.messenger())
        let instance = FlutterEngagePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        // Setup event channels
        instance.setupEventChannels(with: registrar)
    }
    
    /// Sets up various event channels for the plugin. This method initializes
    /// different event channels that the plugin will use for communication.
    /// - Parameter registrar: The Flutter plugin registrar for setting up the channels.
    private func setupEventChannels(with registrar: FlutterPluginRegistrar) {
        // Registration Event Channel
        registrationEventChannel = FlutterEventChannel(name: "engage_registration_events", binaryMessenger: registrar.messenger())
        registrationEventChannel?.setStreamHandler(self)

        // Unregistration Event Channel
        unRegistrationEventChannel = FlutterEventChannel(name: "engage_unregistration_events", binaryMessenger: registrar.messenger())
        unRegistrationEventChannel?.setStreamHandler(self)

        // Change Number Event Channel
        changeNumberEventChannel = FlutterEventChannel(name: "engage_change_number_events", binaryMessenger: registrar.messenger())
        changeNumberEventChannel?.setStreamHandler(self)
    }
}

/// Extension of FlutterEngagePlugin to conform to FlutterStreamHandler protocol.
/// This extension manages the handling of event stream connections and disconnections.
extension FlutterEngagePlugin: FlutterStreamHandler {
    
    /// Handles the establishment of a stream connection from Flutter. This method
    /// is called when Flutter starts listening to a stream.
    /// - Parameters:
    ///   - arguments: Additional arguments sent from Flutter. Used to determine
    ///                which event sink to attach.
    ///   - events: The event sink through which events will be sent back to Flutter.
    /// - Returns: A FlutterError object if an error occurs, otherwise nil.
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if let args = arguments as? String {
            switch args {
            case "registration":
                log("Registration eventSink Attached")
                registrationEventSink = events
            case "unregistration":
                log("Unregistration eventSink Attached")
                unRegistrationEventSink = events
            case "changeNumber":
                log("ChangeNumber eventSink Attached")
                changeNumberEventSink = events
            default:
                break
            }
        }
        return nil
    }

    /// Handles the cancellation of a stream connection from Flutter. This method
    /// is called when Flutter stops listening to a stream.
    /// - Parameter arguments: Additional arguments sent from Flutter. Used to determine
    ///                        which event sink to detach.
    /// - Returns: A FlutterError object if an error occurs, otherwise nil.
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let args = arguments as? String {
            switch args {
            case "registration":
                log("Registration eventSink Detached")
                registrationEventSink = nil
            case "unregistration":
                log("Unregistration eventSink Detached")
                unRegistrationEventSink = nil
            case "changeNumber":
                log("ChangeNumber eventSink Detached")
                changeNumberEventSink = nil
            default:
                break
            }
        }
        return nil
    }
}

// Error Mapping
extension FlutterEngagePlugin {
    func mapEngageError(error: EngageError) -> EngageRegistrationError {
        switch error {
        case .SDKNotConfigured(_):
            return .restricted
        case .challengeNotInitiated(_):
            // since iOS EngageSDK does not use challengeNotInitiated case, will return unknown
            return .unknown
        case .serviceFailure(let errorString):
            return mapEngageError(error: errorString)
        case .payloadNotCorrectPushType(let errorString):
            return mapEngageError(error: errorString)
        case .verificationNotCompleted(let errorString):
            return mapEngageError(error: errorString)
        case .InvalidChallengeResponse:
            return .invalidCode
        case .CannotInitChallengeNoPushToken:
            return .cannotInitChallengeNoPushToken
        default:
            return EngageRegistrationError.unknown
        }
    }
    
    func mapEngageError(error: String) -> EngageRegistrationError {
        if error.lowercased().contains("invalid") && error.contains("code") {
            return .invalidCode
        } else if error.lowercased().contains("invalid") && error.contains("phonenumber") {
            return .invalidNumber
        } else if error.lowercased().contains("sending push challenge failed") {
            return .invalidNumber
        } else if error.lowercased().contains("rate limited") {
            return .rateLimited
        } else if error.lowercased().contains("missing") || error.lowercased().contains("500") {
            return .internalError
        } else if error.lowercased().contains("timeout") {
            return .timeout
        } else {
            return EngageRegistrationError.unknown
        }
    }
}
