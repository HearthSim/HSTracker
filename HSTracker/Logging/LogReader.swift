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

protocol LogLineReader {
    func processNewLine(logLine: LogLine)
}

class LogReader {
    var stopped: Bool = true
    var offset: UInt64 = 0
    var startingPoint: Double = 0

    var name: String
    var delegate: LogLineReader?
    var startFilters: [String]?
    var containsFilters: [String]?
    var path: String

    init(name: String, startFilters: [String]? = nil, containsFilters: [String]? = nil) {
        self.name = name
        self.startFilters = startFilters
        self.containsFilters = containsFilters

        self.path = Hearthstone.instance.logPath + "\(name).log"
    }

    func setDelegate(delegate: LogLineReader) {
        self.delegate = delegate
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
            //TODO NSFileManager.defaultManager.removeItemAtPath(self.path, error:nil)
        }

        stopped = false
        startingPoint = entryPoint
        offset = findOffset()
        readFile()
    }

    func readFile() {
        while !stopped {
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

                let lines = linesStr!.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet()).filter {
                    $0.isEmpty
                }

                for line in lines {
                    let time = parseTime(line)
                    if time.timeIntervalSince1970 < startingPoint {
                        continue
                    }

                    var parse = false
                    if self.startFilters == nil || self.containsFilters == nil {
                        parse = true
                    } else if let filters = self.startFilters {
                        for filter in filters {
                            let reg = "^\(filter)"
                            let index: String.Index = line.startIndex.advancedBy(19)
                            if line.substringFromIndex(index).isMatch(NSRegularExpression.rx(reg)) {
                                parse = true
                                break
                            }
                        }
                    }

                    if !parse && self.containsFilters != nil {
                        if let filters = self.containsFilters {
                            for filter in filters {
                                let index: String.Index = line.startIndex.advancedBy(19)
                                if line.substringFromIndex(index).isMatch(NSRegularExpression.rx(filter)) {
                                    parse = true
                                    break
                                }
                            }
                        }
                    }

                    if parse {
                        if let delegate = self.delegate {
                            let logLine = LogLine(namespace: self.name, time: Int(time.timeIntervalSince1970), line: line)
                            delegate.processNewLine(logLine)
                        }
                    }
                }
            }
            NSThread.sleepForTimeInterval(0.5)
        }
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
        stopped = true
    }
}
