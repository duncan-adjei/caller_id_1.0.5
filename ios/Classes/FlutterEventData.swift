//
//  FlutterEventData.swift
//  flutter_engage_plugin
//
//  Created by Oleg McNamara on 3/13/24.
//

import Foundation
enum FlutterEventType: String {
    case onInitializationSuccess
    case onRegistrationSuccess
    case onRegistrationFailure
}
class FlutterEventData {
    let eventType: FlutterEventType
    let eventInfo: [String: Any]
    
    init(eventType: FlutterEventType, eventInfo: [String: Any]) {
        self.eventType = eventType
        self.eventInfo = eventInfo
    }
    
    func toDictionary() -> [String: Any] {
        var event: [String: Any] = ["eventName": eventType.rawValue]
        for (key, value) in eventInfo {
            if key == "eventName" { continue }
            event[key] = value
        }
        return event
    }
}
