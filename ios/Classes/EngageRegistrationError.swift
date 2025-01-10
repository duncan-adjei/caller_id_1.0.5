//
//  EngageRegistrationError.swift
//  flutter_engage_plugin
//
//  Created by Oleg McNamara on 3/13/24.
//

import Foundation

public enum EngageRegistrationError: String {
    case invalidCode = "INVALID_CODE"
    case invalidNumber = "INVALID_NUMBER"
    case timeout = "TIMEOUT"
    case rateLimited = "RATE_LIMITED"
    case internalError = "INTERNAL_ERROR"
    case restricted = "RESTRICTED"
    case cannotInitChallengeNoPushToken
    case unknown = "UNKNOWN"
}
