//
//  NotificationManager.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 17/04/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

enum NotificationType {
    case gameStart, turnStart, opponentConcede, hsReplayPush(replayId: String), hsReplayUploadFailed(error: String),
         hsReplayCollectionUploaded, hsReplayMercenariesCollectionUploaded, hsReplayCollectionUploadFailed(error: String), hsReplayMercenariesCollectionUploadFailed(error: String), updateAvailable(version: String), restartRequired
}

class NotificationManager {
    
    static func showNotification(type: NotificationType) {
        switch type {
        case .gameStart:
            guard Settings.notifyGameStart else {
                return
            }
            if CoreManager.isHearthstoneActive() {
                return
            }

            show(title: String.localizedString("Hearthstone", comment: ""),
                message: String.localizedString("Your game begins", comment: ""))

        case .opponentConcede:
            guard Settings.notifyOpponentConcede else {
                return
            }
            if CoreManager.isHearthstoneActive() {
                return
            }

            show(title: String.localizedString("Victory", comment: ""),
                message: String.localizedString("Your opponent have conceded", comment: ""))

        case .turnStart:
            guard Settings.notifyTurnStart else {
                return
            }
            if CoreManager.isHearthstoneActive() {
                return
            }

            show(title: String.localizedString("Hearthstone", comment: ""),
                message: String.localizedString("It's your turn to play", comment: ""))

        case .hsReplayPush(let replayId):
            guard Settings.showHSReplayPushNotification else {
                return
            }

            show(title: String.localizedString("HSReplay", comment: ""),
                message: String.localizedString("Your replay has been uploaded to HSReplay.net",
                    comment: "")) {
                HSReplayManager.showReplay(replayId: replayId)
            }

        case .hsReplayUploadFailed(let error):
            show(title: String.localizedString("HSReplay", comment: ""),
                 message: String(format: String.localizedString("Failed to upload replay: %@", comment: ""), "\(error)"))

        case .hsReplayCollectionUploaded:
            show(title: String.localizedString("HSReplay", comment: ""),
                message: String.localizedString("Your collection has been uploaded to HSReplay.net",
                    comment: ""))

        case .hsReplayCollectionUploadFailed(let error):
            show(title: String.localizedString("HSReplay", comment: ""),
                 message: String(format: String.localizedString("Failed to upload collection: %@", comment: ""), "\(error)"), duration: 10, fontSize: 8)
            
        case .hsReplayMercenariesCollectionUploaded:
            show(title: String.localizedString("HSReplay", comment: ""),
                message: String.localizedString("Your Mercenaries collection has been uploaded to HSReplay.net",
                    comment: ""))

        case .hsReplayMercenariesCollectionUploadFailed(let error):
            show(title: String.localizedString("HSReplay", comment: ""),
                 message: String(format: String.localizedString("Failed to upload Mercenaries collection: %@", comment: ""), "\(error)"), duration: 10, fontSize: 8)
            
        case .updateAvailable(let version):
            show(title: String.localizedString("A new update is available", comment: ""),
                 message: String(format: String.localizedString("Version %@ is now available", comment: ""), version), duration: 30, action: {
                AppDelegate.instance().sparkleUpdater.checkForUpdates(nil)
            })
        case .restartRequired:
            show(title: String.localizedString("Hearthstone restart required!", comment: ""),
                 message: String.localizedString("Please restart Hearthstone", comment: ""), duration: 10)

        }
    }

    private static var notificationDelegate = NotificationDelegate()
    private static func show(title: String, message: String, duration: Double? = 3, fontSize: Int? = 14,
                             action: (() -> Void)? = nil) {
        if Settings.useToastNotification {
            Toast.show(title: title, message: message, duration: duration, fontSize: fontSize, action: action)
        } else {
            let notification = NSUserNotification()
            notification.title = title
            notification.subtitle = ""
            notification.informativeText = message

            if action != nil {
                notification.actionButtonTitle = String.localizedString("Show", comment: "")
                notification.hasActionButton = true
                notificationDelegate.action = action
                NSUserNotificationCenter.default.delegate = notificationDelegate
            }
            
            notification.deliveryDate = Date()
            NSUserNotificationCenter.default.scheduleNotification(notification)
        }
    }

    private class NotificationDelegate: NSObject, NSUserNotificationCenterDelegate {
        var action: (() -> Void)?

        func userNotificationCenter(_ center: NSUserNotificationCenter,
                                    didActivate notification: NSUserNotification) {
            self.action?()
        }
    }
    
}
