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
        guard line.characters.count > 20 else { return (Date(), 0) }

        guard let fromLine = line.substringWithRange(2, location: 16)
            .components(separatedBy: " ").first else { return (Date(), 0) }
        
        guard !fromLine.isEmpty else { return (Date(), 0) }
        let components = fromLine.components(separatedBy: ".")
        guard [1, 2].contains(components.count) else { return (Date(), 0) }

        guard let dateTime = Date(fromString: components[0], inFormat: "HH:mm:ss") else {
            return (Date(), 0)
        }
        var nanoseconds: Double = 0
        if components.count == 2 && components[1].characters.count >= 3 {
            if let milliseconds = Double(components[1]) {
                nanoseconds = milliseconds
            }
        }
        
        let today = Date()
        guard let date = Date(year: today.year,
                              month: today.month,
                              day: today.day,
                              hour: dateTime.hour,
                              minute: dateTime.minute,
                              second: dateTime.second,
                              nanosecond: 0,
                              timeZone: TimeZone(identifier: "UTC")) else {
                                return (dateTime, nanoseconds)
        }
        if date > Date() {
            return (date.addDays(-1)!, nanoseconds)
        }
        return (date, nanoseconds)
    }
}

extension LogLine: CustomStringConvertible {
    var description: String {
        return "\(namespace): \(time.millisecondsFormatted): \(line)"
    }
}
