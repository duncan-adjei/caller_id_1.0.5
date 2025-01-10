//
//  FlutterEngageEnvironment.swift
//  flutter_engage_plugin
//
//  Created by Oleg McNamara on 2/18/24.
//

import Foundation
import EngageKit

public enum FlutterEngageEnvironment: String {
    case debug = "debug"
    case test = "test"
    case production = "production"
    
    func toEngageEnvironment() -> EngageEnvironment {
        switch self {
        case .debug:
            return .debug
        case .test:
            return .test
        case .production:
            return .production
        }
    }
}
