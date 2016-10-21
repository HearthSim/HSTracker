//
//  AppHealth.swift
//  HSTracker
//
//  Created by Istvan Fehervari on 21/10/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

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
    
    override init() {
        level = .undefined
        super.init()
        
        let observers = [
            "hearthstone_installed": #selector(AppHealth.setHSInstalled(_:)),
            "logger_works": #selector(AppHealth.setLoggerWorks(_:)),
            "hearthstone_running": #selector(AppHealth.setHearthstoneRunning(_:)),
            "hearthstone_game_running": #selector(AppHealth.setHearthstoneGameRunning(_:))
        ]
        
        let center = NotificationCenter.default
        for (name, selector) in observers {
            center.addObserver(self,
                               selector: selector,
                               name: NSNotification.Name(rawValue: name),
                               object: nil)
        }
        
    }
    
    func setHSInstalled(_ notification: Notification) {
        if let userinfo: Dictionary<String, Bool> =
            notification.userInfo as? Dictionary<String, Bool> {
            if let installed = userinfo["installed"] {
                if installed {
                    if level.rawValue < HealthLevel.gameinstalled.rawValue {
                        self.setLevel(level: HealthLevel.gameinstalled)
                    }
                } else {
                    self.setLevel(level: HealthLevel.undefined)
                }
            }
            
        }
    }
    
    func setLoggerWorks(_ notification: Notification) {
        if let userinfo: Dictionary<String, Bool> =
            notification.userInfo as? Dictionary<String, Bool> {
            if let installed = userinfo["logger_works"] {
                if installed {
                    if level.rawValue < HealthLevel.trackerworks.rawValue {
                        self.setLevel(level: HealthLevel.trackerworks)
                    }
                } else {
                    self.setLevel(level: HealthLevel.gameinstalled)
                }
            }
        }
    }
    
    func setHearthstoneRunning(_ notification: Notification) {
        if let userinfo: Dictionary<String, Bool> =
            notification.userInfo as? Dictionary<String, Bool> {
            if let hsrunning = userinfo["running"] {
                if hsrunning {
                    if level.rawValue < HealthLevel.gamerunning.rawValue {
                        self.setLevel(level: HealthLevel.gamerunning)
                    }
                } else {
                    self.setLevel(level: HealthLevel.trackerworks)
                }
            }
        }
    }
    
    func setHearthstoneGameRunning(_ notification: Notification) {
        if let userinfo: Dictionary<String, Bool> =
            notification.userInfo as? Dictionary<String, Bool> {
            if let hsgamerunning = userinfo["running"] {
                if hsgamerunning {
                    if level.rawValue < HealthLevel.gamerunning.rawValue {
                        self.setLevel(level: HealthLevel.gameinprogress)
                    }
                } else {
                    self.setLevel(level: HealthLevel.gamerunning)
                }
            }
        }
    }
    
    func setLevel(level: HealthLevel) {
        self.level = level
        self.updateBadge()
    }
    
    func updateBadge() {
        // update app icon
        //case undefined = HS crossed
        //gameinstalled : tracker not working
        //trackerworks : grey HS icon (HS not running)
        //gamerunning : normal HS icon
        //gameinprogress : normal HS icon with play triangle
    }
}
