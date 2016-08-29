//
//  LogLineZone.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 11/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

class LogLineZone: CustomStringConvertible {
    var namespace: LogLineNamespace
    var logLevel = 1
    var filePrinting = "true"
    var consolePrinting = "false"
    var screenPrinting = "false"
    
    init(namespace: LogLineNamespace) {
        self.namespace = namespace
    }
    
    func isValid() -> Bool {
        return logLevel == 1 && filePrinting == "true"
            && consolePrinting == "false" && screenPrinting == "false"
    }
    
    func toString() -> String {
        return "[\(namespace)]\n" +
            "LogLevel=1\n" +
            "FilePrinting=true\n" +
            "ConsolePrinting=false\n" +
        "ScreenPrinting=false\n"
        //"Verbose=true\n"
    }
    
    var description: String {
        return "[\(namespace): " +
            "LogLevel=\(logLevel), " +
            "FilePrinting=\(filePrinting), " +
            "ConsolePrinting=\(consolePrinting), " +
            "ScreenPrinting=\(screenPrinting)]"
    }
}