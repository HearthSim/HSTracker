//
//  LogLineZone.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class LogLineZone {
    var namespace: LogLineNamespace
    var logLevel = 1
    var filePrinting = "true"
    var consolePrinting = "false"
    var screenPrinting = "false"
    var verbose = false
    var requireVerbose = false
    
    init(namespace: LogLineNamespace) {
        self.namespace = namespace
    }
    
    func isValid() -> Bool {
        return logLevel == 1 && filePrinting == "true"
            && consolePrinting == "false" && screenPrinting == "false"
            && requireVerbose == verbose
    }
    
    func toString() -> String {
        var content = [
            "[\(namespace.rawValue)]",
            "LogLevel=1",
            "FilePrinting=true",
            "ConsolePrinting=false",
            "ScreenPrinting=false"
        ]
        if requireVerbose {
            content.append("Verbose=true")
        }
        return content.joined(separator: "\n") + "\n"
    }
}

extension LogLineZone: CustomStringConvertible {
    var description: String {
        return "[\(namespace.rawValue): " +
            "LogLevel=\(logLevel), " +
            "FilePrinting=\(filePrinting), " +
            "ConsolePrinting=\(consolePrinting), " +
            "ScreenPrinting=\(screenPrinting), " +
            "Verbose=\(verbose), " +
            "RequireVerbose=\(requireVerbose)]"
    }
}
