/*
 * This file is part of the HSTracker package.
 * (c) Benjamin Michotte <bmichotte@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 *
 * Created on 13/02/16.
 */

import Foundation

class LogReader {
    var stopped: Bool = true
    var offset: UInt64 = 0
    var startingPoint: Double = 0

    var name: String
    var startFilters = [String]()
    var containsFilters = [String]()
    var path: String
    var lines = [LogLine]()
    var collected = false

    init(name: String, startFilters: [String]? = nil, containsFilters: [String]? = nil) {
        self.name = name
        if let startFilters = startFilters {
            self.startFilters = startFilters
        }
        if let containsFilters = containsFilters {
            self.containsFilters = containsFilters
        }

        self.path = Hearthstone.instance.logPath + "/\(name).log"
    }

    func findEntryPoint(choice: String) -> Double {
        return findEntryPoint([choice])
    }

    func findEntryPoint(choices: [String]) -> Double {
        if !NSFileManager.defaultManager().fileExistsAtPath(self.path) {
            return NSDate.distantPast().timeIntervalSince1970
        }
        var fileContent: String
        do {
            fileContent = try String(contentsOfFile: self.path)
        } catch {
            return NSDate.distantPast().timeIntervalSince1970
        }

        let lines: [String] = fileContent.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet()).reverse()
        for line in lines {
            for str in choices {
                if line.rangeOfString(str) != nil {
                    return parseTime(line).timeIntervalSince1970
                }
            }
        }

        return NSDate.distantPast().timeIntervalSince1970
    }

    func parseTime(line: String) -> NSDate {
        if line.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) < 18 {
            return fileDate()
        }

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let day = dateFormatter.stringFromDate(NSDate())

        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS"
        let fromLine = line.substringWithRange(2, location: 16)
        var date = dateFormatter.dateFromString("\(day) \(fromLine)")

        if let _date = date {
            if _date.compare(NSDate()) == NSComparisonResult.OrderedDescending {
                date = _date.dateByAddingTimeInterval(-(60 * 60 * 24 * 1))
            }
            return date!
        }
        return NSDate.distantPast()
    }

    func start(entryPoint: Double) {
        DDLogInfo("Starting reader \(self.name), (\(self.path):\(entryPoint)")
        if NSFileManager.defaultManager().fileExistsAtPath(self.path) && !Hearthstone.instance.isHearthstoneRunning {
            /*do {
             try NSFileManager.defaultManager().removeItemAtPath(self.path)
             } catch { }*/
        }

        stopped = false
        startingPoint = entryPoint
        offset = findOffset()
        DDLogVerbose("Starting to track \(self.name) with offset \(offset)")
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            self.readFile()
        }
    }

    func readFile() {
        while !stopped {
            if collected {
                lines.removeAll()
                collected = false
            }
            if NSFileManager.defaultManager().fileExistsAtPath(self.path) {
                let fileHandle = NSFileHandle(forReadingAtPath: self.path)

                if offset > self.fileSize() {
                    offset = findOffset()
                }
                fileHandle!.seekToFileOffset(offset)

                let data = fileHandle!.readDataToEndOfFile()
                let linesStr = String(data: data, encoding: NSUTF8StringEncoding)
                offset += UInt64(linesStr!.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
                fileHandle!.closeFile()

                let lines = linesStr!.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
                    .filter {
                        !$0.isEmpty && $0.startsWith("D ")
                }

                for line in lines {
                    let cutted = line.substringFromIndex(line.startIndex.advancedBy(19))
                    if (startFilters.count == 0 && containsFilters.count == 0)
                    || startFilters.any({ cutted.startsWith($0) })
                    || containsFilters.any({ cutted.containsString($0) }) {
                        let time = parseTime(line)
                        if time.timeIntervalSince1970 < startingPoint {
                            continue
                        }

                        self.lines.append(LogLine(namespace: self.name, time: Int(time.timeIntervalSince1970), line: line))
                    }
                }
            }
            NSThread.sleepForTimeInterval(0.1)
        }
    }

    func collect() -> [LogLine] {
        collected = true
        return lines
    }

    func fileSize() -> UInt64 {
        var fileSize: UInt64 = 0

        do {
            let attr: NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(self.path)

            if let _attr = attr {
                fileSize = _attr.fileSize();
            }
        } catch {
            print("Error: \(error)")
        }
        return fileSize
    }

    func fileDate() -> NSDate {
        do {
            let attr: NSDictionary? = try NSFileManager.defaultManager().attributesOfItemAtPath(self.path)
            if let _attr = attr {
                return _attr[NSFileModificationDate] as! NSDate
            }
        } catch {
            return NSDate.distantPast()
        }
    }

    func findOffset() -> UInt64 {
        if !NSFileManager.defaultManager().fileExistsAtPath(self.path) {
            return 0
        }

        var offset: UInt64 = 0
        let fileContent: String
        do {
            fileContent = try String(contentsOfFile: self.path)
        } catch {
            return offset
        }

        let lines = fileContent.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet()).reverse()
        for line in lines {
            let time = parseTime(line)
            if time.timeIntervalSince1970 < startingPoint {
                offset += UInt64(line.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
            }
        }

        return offset
    }

    func stop() {
        DDLogVerbose("Stopping tracker \(name)")
        stopped = true
    }
}
