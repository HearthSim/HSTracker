//
//  HSTrackerLogFormatter.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 30/03/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger

class HSTrackerLogFormatter: LogFormatter {

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    func format(_ entry: LogEntry) -> String? {
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
        case .value(let value): message = "\(String(describing: value))"
        }

        return "|\(severity)|\(dateFormatter.string(from: entry.timestamp))| \(message)"
    }
}
