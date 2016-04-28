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
import CleanroomLogger

final class LogReader {
    var stopped: Bool = true
    var offset: UInt64 = 0
    var startingPoint: Double = 0

    private let _lock = String()
    var name: LogLineNamespace
    var startFilters = [String]()
    var containsFilters = [String]()
    var path: String
    lazy var lines = [LogLine]()
    var collected = false
    
    private var queue:dispatch_queue_t?
    private var _lockQueue:dispatch_queue_t?

    init(name: LogLineNamespace, startFilters: [String]? = nil, containsFilters: [String]? = nil) {
        self.name = name
        if let startFilters = startFilters {
            self.startFilters = startFilters
        }
        if let containsFilters = containsFilters {
            self.containsFilters = containsFilters
        }
        
        self.path = Hearthstone.instance.logPath + "/Logs/\(name).log"
        Log.info?.message("Init reader for \(name) at path \(self.path)")
        if NSFileManager.defaultManager().fileExistsAtPath(self.path) && !Hearthstone.instance.isHearthstoneRunning {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(self.path)
            } catch { }
        }
    }

    func findEntryPoint(choice: String) -> Double {
        return findEntryPoint([choice])
    }

    func findEntryPoint(choices: [String]) -> Double {
        guard NSFileManager.defaultManager().fileExistsAtPath(self.path) else {
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
        guard line.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 18 else { return fileDate() }

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
        stopped = false
        startingPoint = entryPoint

        var queueName = "be.michotte.hstracker.readers.\(name)"
        if let filter = startFilters.first {
            queueName += ".\(filter.lowercaseString)"
        }
        queue = dispatch_queue_create(queueName, nil)
        _lockQueue = dispatch_queue_create("\(queueName).lock", DISPATCH_QUEUE_CONCURRENT)
        if let queue = queue {
            Log.info?.message("Starting to track \(name)")
            Log.verbose?.message("\(name) has queue \(queueName) starting at \(NSDate(timeIntervalSince1970: startingPoint))")
            dispatch_async(queue) {
                self.readFile()
            }
        }
    }

    func readFile() {
        guard let _ = _lockQueue else {return}
        
        var fileHandle: NSFileHandle?
        if NSFileManager.defaultManager().fileExistsAtPath(self.path) {
            fileHandle = NSFileHandle(forReadingAtPath: self.path)
            offset = findOffset()
        }
        
        while !stopped {
            dispatch_barrier_async(_lockQueue!) {
                if self.collected {
                    self.lines.removeAll()
                    self.collected = false
                }
                
                if fileHandle == .None && NSFileManager.defaultManager().fileExistsAtPath(self.path) {
                    fileHandle = NSFileHandle(forReadingAtPath: self.path)
                    self.offset = self.findOffset()
                }
                
                if let handle = fileHandle {
                    handle.seekToFileOffset(self.offset)
                    
                    let data = handle.readDataToEndOfFile()
                    if let linesStr = String(data: data, encoding: NSUTF8StringEncoding) {
                        self.offset += UInt64(linesStr.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
                        
                        let lines = linesStr.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
                            .filter { !$0.isEmpty && $0.startsWith("D ") }
                        if !lines.isEmpty {
                            for line in lines {
                                let cutted = line.substringFromIndex(line.startIndex.advancedBy(19))
                                if (self.startFilters.count == 0 && self.containsFilters.count == 0)
                                    || self.startFilters.any({ cutted.startsWith($0) })
                                    || self.containsFilters.any({ cutted.containsString($0) }) {
                                    let time = self.parseTime(line)
                                    if time.timeIntervalSince1970 < self.startingPoint {
                                        continue
                                    }
                                    
                                    self.lines.append(LogLine(namespace: self.name, time: Int(time.timeIntervalSince1970), line: line))
                                }
                            }
                        }
                    }
                    
                    if !NSFileManager.defaultManager().fileExistsAtPath(self.path) || self.offset > self.fileSize() {
                        fileHandle = nil
                    }
                }
            }
            NSThread.sleepForTimeInterval(0.1)
        }
    }

    func collect() -> [LogLine] {
        guard let _ = _lockQueue else {return []}
        dispatch_sync(_lockQueue!) {
            self.collected = true
        }
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
            Log.error?.message("\(error)")
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
        guard NSFileManager.defaultManager().fileExistsAtPath(self.path) else { return 0 }

        var offset: UInt64 = 0
        let fileContent: String
        do {
            fileContent = try String(contentsOfFile: self.path)
        } catch {
            return offset
        }

        let lines = fileContent.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        for line in lines {
            let time = parseTime(line)
            if time.timeIntervalSince1970 < startingPoint {
                let length = line.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
                if length > 0 {
                    offset += UInt64(length)
                }
            }
        }

        return offset
    }

    func stop() {
        Log.info?.message("Stopping tracker \(name)")
        stopped = true
    }
}
