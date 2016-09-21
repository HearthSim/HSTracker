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
        case .verbose: return self.dynamicType.VerboseColor
        case .debug: return self.dynamicType.DebugColor
        case .info: return self.dynamicType.InfoColor
        case .warning: return self.dynamicType.WarningColor
        case .error: return self.dynamicType.ErrorColor
        }
    }
}

class HSTrackerLogFormatter: XcodeLogFormatter {

    let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        //formatter.timeZone = NSTimeZone(name: "UTC")
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    override func formatLogEntry(entry: LogEntry) -> String? {
        let severity: String
        switch entry.severity {
        case .verbose: severity = "V"
        case .debug: severity = "D"
        case .info: severity = "I"
        case .warning: severity = "W"
        case .error: severity = "E"
        }

        let message: String
        switch entry.payload {
        case .trace: message = entry.callingStackFrame
        case .message(let msg): message = msg
        case .value(let value): message = "\(value)"
        }

        return "|\(severity)|\(dateFormatter.stringFromDate(entry.timestamp))| \(message)"
    }
}
