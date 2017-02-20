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
import SwiftDate

struct LogLine {
    let namespace: LogLineNamespace
    let time: DateInRegion
    let line: String
    let nanoseconds: Double
    let include: Bool

    private static let utc: Region = {
        let locale = Locale(identifier: Settings.instance.hsTrackerLanguage ?? "enUS")
        return Region(tz: TimeZone(identifier: "UTC") ?? TimeZone.current,
                      cal: CalendarName.gregorian.calendar,
                      loc: locale)
    }()

    init(namespace: LogLineNamespace, line: String, include: Bool = true) {
        self.namespace = namespace
        self.line = line
        (self.time, self.nanoseconds) = LogLine.parseTime(line: line)
        self.include = include
    }
    
    static func parseTime(line: String) -> (DateInRegion, Double) {
        return autoreleasepool { () -> (DateInRegion, Double) in
            guard line.characters.count > 20 else { return (DateInRegion(), 0) }
            
            guard let fromLine = line.substringWithRange(2, location: 16)
                .components(separatedBy: " ").first else { return (DateInRegion(), 0) }
            
            guard !fromLine.isEmpty else { return (DateInRegion(), 0) }
            let components = fromLine.components(separatedBy: ".")
            guard [1, 2].contains(components.count) else { return (DateInRegion(), 0) }
            
            guard let dateTime = try? DateInRegion(string: components[0],
                                                   format: .custom("HH:mm:ss")) else {
                                                    return (DateInRegion(), 0)
            }
            
            var nanoseconds: Double = 0
            if components.count == 2 && components[1].characters.count >= 3 {
                if let milliseconds = Double(components[1]) {
                    nanoseconds = milliseconds
                }
            }
            
            guard let date = try? DateInRegion().atTime(hour: dateTime.hour,
                                                        minute: dateTime.minute,
                                                        second: dateTime.second) else {
                                                            return (dateTime, nanoseconds)
            }
            var dateInRegion = date
            if dateInRegion.isInFuture {
                dateInRegion = dateInRegion - 1.day
            }
            return (dateInRegion, nanoseconds)
        }
    }
}

extension LogLine: CustomStringConvertible {
    var description: String {
        let dateStr = time.string(format: .iso8601(options: [.withFullTime,
                                                             .withFullDate,
                                                             .withSpaceBetweenDateAndTime]))
        return "\(namespace): \(dateStr).\(nanoseconds): \(line)"
    }
}
