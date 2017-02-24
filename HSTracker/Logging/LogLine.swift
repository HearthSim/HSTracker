/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

import CleanroomLogger

struct LogLine {
    let namespace: LogLineNamespace
    let time: Date
    let line: String
    let nanoseconds: Double
    let include: Bool

    init(namespace: LogLineNamespace, line: String, include: Bool = true) {
        self.namespace = namespace
        self.line = line
        (self.time, self.nanoseconds) = LogLine.parseTime(line: line)
        self.include = include
    }
    
    static func parseTime(line: String) -> (Date, Double) {
        
        if line.characters.count <= 20 { return (Date(), 0) }
        
        guard let fromLine = line.substringWithRange(2, location: 16)
            .components(separatedBy: " ").first else { return (Date(), 0) }
        
        if fromLine.isEmpty { return (Date(), 0) }
        
        let components = fromLine.components(separatedBy: ".")
        if components.count > 2 { return (Date(), 0) }
        
        guard let dateTime = LogReaderManager.dateStringFormatter.date(from: components[0])
            else { return (Date(), 0) }
        
        // check if nanoseconds are available
        var nanoseconds: Double = 0
        if components.count == 2 && components[1].characters.count >= 3 {
            if let ns = Double(components[1]) {
                nanoseconds = ns
            }
        }
        
        // construct full date from the partial one
        let today = Date()
        var dayComponents = LogReaderManager.calendar.dateComponents(in: LogReaderManager.timeZone, from: today)
        let logComponents = LogReaderManager.calendar.dateComponents(in: LogReaderManager.timeZone, from: dateTime)
        
        dayComponents.hour = logComponents.hour
        dayComponents.minute = logComponents.minute
        dayComponents.second = logComponents.second
        
        if let logDate = LogReaderManager.calendar.date(from: dayComponents) {
            if logDate > today {
                return (LogReaderManager.calendar.date(byAdding: .day, value: -1, to: logDate) ?? Date(), nanoseconds)
            } else {
                return (logDate, nanoseconds)
            }
        }
        
        return (Date(), 0)
        
    }
}

extension LogLine: CustomStringConvertible {
    var description: String {
        let dateStr = LogReaderManager.fullDateStringFormatter.string(from: time)
        return "\(namespace): \(dateStr).\(nanoseconds): \(line)"
    }
}
