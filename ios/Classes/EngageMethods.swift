//
//  EngageMethods.swift
//  flutter_engage_plugin
//
//  Created by Oleg McNamara on 2/18/24.
//

import Foundation

enum EngageMethods: String {
    case configureSDK
    case sendChallenge = "register"
    case completeChallengeWithCode
    case providePushTokenToSDK
    case isEngagePush
    case handleMainAppPushNotification = "handlePushNotification"
    case contactPermissionsUpdated
    case hasContactsPermission
}
