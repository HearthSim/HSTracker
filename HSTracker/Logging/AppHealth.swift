//
//  AppHealth.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 21/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

enum HealthLevel: Int {
    case undefined = 0,
    gameinstalled = 1,
    trackerworks = 2,
    gamerunning = 3,
    gameinprogress = 4
}

class AppHealth: NSObject {
    
    private var level: HealthLevel

    static let instance = AppHealth()
    
    private static let badge_icons = ["undefined": NSImage(named: NSImage.Name(rawValue: "badge-icon-undefined"))!,
                               "gameinstalled": NSImage(named: NSImage.Name(rawValue: "badge-icon-gameinstalled"))!,
                               "trackerworks": NSImage(named: NSImage.Name(rawValue: "badge-icon-trackerworks"))!,
                               "gamerunning": NSImage(named: NSImage.Name(rawValue: "badge-icon-gamerunning"))!,
                               "gameinprogress": NSImage(named: NSImage.Name(rawValue: "badge-icon-gameinprogress"))!]

    private var observers: [NSObjectProtocol] = []
    
    override init() {
        level = .undefined
        super.init()
        
        let center = NotificationCenter.default
        let triggers = [Events.hearthstone_active, Events.hearthstone_running]
        
        for event in triggers {
            let observer = center.addObserver(forName: NSNotification.Name(rawValue: event), object: nil, queue: OperationQueue.main) { _ in
                self.setHearthstoneRunning()
            }
            self.observers.append(observer)
        }
    }
    
    deinit {
        for observer in self.observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func setHSInstalled(flag installed: Bool) {
        if installed {
            if level.rawValue < HealthLevel.gameinstalled.rawValue {
                self.setLevel(level: HealthLevel.gameinstalled)
            }
        } else {
            self.setLevel(level: HealthLevel.undefined)
        }

    }
    
    func setLoggerWorks(flag works: Bool) {
        if works {
            if level.rawValue < HealthLevel.trackerworks.rawValue {
                self.setLevel(level: HealthLevel.trackerworks)
            }
        } else {
            self.setLevel(level: HealthLevel.gameinstalled)
        }
    }
    
    func setHearthstoneRunning(flag running: Bool = true) {
        if running {
            if level.rawValue < HealthLevel.gamerunning.rawValue {
                self.setLevel(level: HealthLevel.gamerunning)
            }
        } else {
            self.setLevel(level: HealthLevel.trackerworks)
        }
    }
    
    func setHearthstoneGameRunning(flag running: Bool) {
        if running {
            if level.rawValue < HealthLevel.gameinprogress.rawValue {
                self.setLevel(level: HealthLevel.gameinprogress)
            }
        } else {
            self.setLevel(level: HealthLevel.gamerunning)
        }
    }
    
    func setLevel(level: HealthLevel) {
        self.level = level
        self.updateBadge()
    }
    
    func updateBadge() {
        // update app icon
        // check if feature is enabled in preferences
        if Settings.showAppHealth {
            switch self.level {
            case .undefined:
                NSApp.applicationIconImage = AppHealth.badge_icons["undefined"]
            case .gameinstalled:
                NSApp.applicationIconImage = AppHealth.badge_icons["gameinstalled"]
            case .trackerworks:
                NSApp.applicationIconImage = AppHealth.badge_icons["trackerworks"]
            case .gamerunning:
                NSApp.applicationIconImage = AppHealth.badge_icons["gamerunning"]
            case .gameinprogress:
                NSApp.applicationIconImage = AppHealth.badge_icons["gameinprogress"]
            }
        } else {
            NSApp.applicationIconImage = nil
        }

    }
}
