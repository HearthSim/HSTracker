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
    let time: Double
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
        self.time = self.dynamicType.parseTime(line)
        self.include = include
    }

    static func parseTime(line: String) -> Double {
        guard line.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 20 else {
            return NSDate().timeIntervalSince1970
        }

        let fromLine = line.substringWithRange(2, location: 16)

        let dateTime = NSDate(fromString: fromLine,
                              inFormat: "HH:mm:ss.SSSS",
                              timeZone: nil)
        let today = NSDate()
        let dateComponents = NSDateComponents()
        dateComponents.year = today.year
        dateComponents.month = today.month
        dateComponents.day = today.day
        dateComponents.hour = dateTime.hour
        dateComponents.minute = dateTime.minute
        dateComponents.second = dateTime.second
        dateComponents.nanosecond = dateTime.nanosecond
        dateComponents.timeZone = NSTimeZone(name: "UTC")

        if let date = NSCalendar.currentCalendar().dateFromComponents(dateComponents) {
            if date > NSDate() {
                date.addDays(-1)
            }
            return date.timeIntervalSince1970
        }
        return NSDate().timeIntervalSince1970
    }

    var description: String {
        return "\(namespace): \(NSDate(timeIntervalSince1970: time)): \(line)"
    }
}
