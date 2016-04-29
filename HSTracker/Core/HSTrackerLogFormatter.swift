//
//  HSTrackerLogFormatter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 30/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

struct HSTrackerColorTable: CleanroomLogger.ColorTable {
    static let VerboseColor  = Color(r: 0xA6, g: 0xA6, b: 0xA6)
    static let DebugColor    = Color(r: 0xA6, g: 0xA6, b: 0xA6)
    static let InfoColor     = Color(r: 0xDB, g: 0xDF, b: 0xFF)
    static let WarningColor  = Color(r: 0xF3, g: 0xA2, b: 0x5F)
    static let ErrorColor    = Color(r: 0xCC, g: 0x31, b: 0x7C)

    func foregroundColorForSeverity(severity: LogSeverity) -> Color? {
        switch severity {
        case .Verbose: return self.dynamicType.VerboseColor
        case .Debug: return self.dynamicType.DebugColor
        case .Info: return self.dynamicType.InfoColor
        case .Warning: return self.dynamicType.WarningColor
        case .Error: return self.dynamicType.ErrorColor
        }
    }
}

class HSTrackerLogFormatter: XcodeLogFormatter, LogFormatter {

    let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        //formatter.timeZone = NSTimeZone(name: "UTC")
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    override func formatLogEntry(entry: LogEntry) -> String? {
        let severity: String
        switch entry.severity {
        case .Verbose: severity = "V"
        case .Debug: severity = "D"
        case .Info: severity = "I"
        case .Warning: severity = "W"
        case .Error: severity = "E"
        }

        let message: String
        switch entry.payload {
        case .Trace: message = entry.callingStackFrame
        case .Message(let msg): message = msg
        case .Value(let value): message = "\(value)"
        }

        return "|\(severity)|\(dateFormatter.stringFromDate(entry.timestamp))| \(message)"
    }
}
