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

struct LogLine: CustomStringConvertible {
    let namespace: LogLineNamespace
    let time: NSDate
    let nanoseconds: Double
    let line: String
    let include: Bool

    static let nano: Double = 1_000_000_000

    static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone(name: "UTC")
        return formatter
    }()

    init(namespace: LogLineNamespace, line: String, include: Bool = true) {
        self.namespace = namespace
        self.line = line
        (self.time, self.nanoseconds) = LogLine.parseTime(line)
        self.include = include
    }

    static func parseTime(line: String) -> (NSDate, Double) {
        guard line.characters.count > 20 else { return (NSDate(), 0) }
        
        guard let fromLine = line.substringWithRange(2, location: 16)
            .componentsSeparatedByString(" ").first else { return (NSDate(), 0) }
        
        guard !fromLine.isEmpty else { return (NSDate(), 0) }
        let components = fromLine.componentsSeparatedByString(".")
        guard components.count >= 1 && components.count <= 2 else { return (NSDate(), 0) }
        
        let dateTime = NSDate(fromString: components[0],
                              inFormat: "HH:mm:ss",
                              timeZone: nil)
        var nanoseconds: Double = 0
        if components.count == 2 && components[1].characters.count >= 3 {
            if let milliseconds = Double(components[1]) {
                nanoseconds = milliseconds
            }
        }

        let today = NSDate()
        if let date = NSDate.NSDateFromYear(year: today.year,
                                            month: today.month,
                                            day: today.day,
                                            hour: dateTime.hour,
                                            minute: dateTime.minute,
                                            second: dateTime.second,
                                            nanosecond: 0,
                                            timeZone: NSTimeZone(name: "UTC")) {
            if date > NSDate() {
                return (date.addDays(-1)!, nanoseconds)
            }
            return (date, nanoseconds)
        }
        return (dateTime, nanoseconds)
    }

    var description: String {
        return "\(namespace): \(time.millisecondsFormatted): \(line)"
    }
}
