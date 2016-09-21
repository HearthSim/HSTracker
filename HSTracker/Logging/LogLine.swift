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
    let line: String
    let include: Bool

    static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone(name: "UTC")
        return formatter
    }()

    init(namespace: LogLineNamespace, line: String, include: Bool = true) {
        self.namespace = namespace
        self.line = line
        self.time = self.dynamicType.parseTimeAsDate(line)
        self.include = include
    }
    
    static func parseTimeAsDate(line: String) -> NSDate {
        guard line.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 20 else {
            return NSDate()
        }
        
        guard let fromLine = line.substringWithRange(2, location: 16)
            .componentsSeparatedByString(" ").first else { return NSDate() }
        
        guard !fromLine.isEmpty else { return NSDate() }
        let components = fromLine.componentsSeparatedByString(".")
        guard components.count >= 1 && components.count <= 2 else { return NSDate() }
        
        let dateTime = NSDate(fromString: components[0],
                              inFormat: "HH:mm:ss",
                              timeZone: nil)
        var nanoseconds = 0
        if components.count == 2 && components[1].characters.count >= 3 {
            if let milliseconds = Int(components[1].substringWithRange(0, end: 3)) {
                nanoseconds = milliseconds * 1000000
            }
        }
        
        let today = NSDate()
        if let date = NSDate.NSDateFromYear(year: today.year,
                                            month: today.month,
                                            day: today.day,
                                            hour: dateTime.hour,
                                            minute: dateTime.minute,
                                            second: dateTime.second,
                                            nanosecond: nanoseconds,
                                            timeZone: NSTimeZone(name: "UTC")) {
            if date > NSDate() {
                return date.addDays(-1)!
            }
            return date
        }
        return dateTime
    }
    
    static func parseTime(line: String) -> Double {
        return parseTimeAsDate(line).timeIntervalSince1970
    }

    var description: String {
        return "\(namespace): \(time.millisecondsFormatted): \(line)"
    }
}
