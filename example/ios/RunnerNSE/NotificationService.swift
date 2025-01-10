//
//  NotificationService.swift
//  RunnerNSE
//
//  Created by Oleg McNamara on 2/27/24.
//

import UserNotifications
import EngageKit

class NotificationService: UNNotificationServiceExtension {

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        Engage.shared.handleNSEPush(
            request,
            using: "",
            includeThumbnail: false,
            withContentHandler: contentHandler)
    }
    
    override func serviceExtensionTimeWillExpire() {
        Engage.shared.nseTimeExpiring()
    }
}
