//
//  AppDelegate.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 19/02/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Cocoa
import CocoaLumberjack
import MagicalRecord

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // init core data stuff
        MagicalRecord.setupAutoMigratingCoreDataStack()

        // init logger
#if DEBUG
        DDTTYLogger.sharedInstance().colorsEnabled = true
        DDLog.addLogger(DDTTYLogger.sharedInstance())
#else
        var fileLogger: DDFileLogger = DDFileLogger()
        fileLogger.rollingFrequency = 60 * 60 * 24
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.addLogger(fileLogger)
#endif

        //windowNibName: "Splashscreen"
    }

    func applicationWillTerminate(aNotification: NSNotification) {

    }

}

