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
    var stopped = true
    var offset: UInt64 = 0
    var startingPoint = 0.0

    var path: String
    lazy var lines: [LogLine] = []
    var collected = false
    let fileManager = NSFileManager()
    let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone(name: "UTC")
        return formatter
    }()
    private var info: LogReaderInfo

    private var queue: dispatch_queue_t?
    private var _lockQueue: dispatch_queue_t?

    init(info: LogReaderInfo) {
        self.info = info

        self.path = Hearthstone.instance.logPath + "/Logs/\(info.name).log"
        Log.info?.message("Init reader for \(info.name) at path \(self.path)")
        if fileManager.fileExistsAtPath(self.path)
            && !Hearthstone.instance.isHearthstoneRunning {
            do {
                try fileManager.removeItemAtPath(self.path)
            } catch let error as NSError {
                Log.error?.message("\(error.description)")
            }
        }
    }

    func findEntryPoint(choice: String) -> Double {
        return findEntryPoint([choice])
    }

    func findEntryPoint(choices: [String]) -> Double {
        guard fileManager.fileExistsAtPath(path) else {
            return NSDate.distantPast().timeIntervalSince1970
        }
        var fileContent: String
        do {
            fileContent = try String(contentsOfFile: path)
        } catch {
            return NSDate.distantPast().timeIntervalSince1970
        }

        // swiftlint:disable line_length
        let lines: [String] = fileContent.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
            .filter({ !String.isNullOrEmpty($0) }).reverse()
        // swiftlint:enable line_length
        for line in lines {
            if choices.any({ line.rangeOfString($0) != nil }) {
                return LogLine.parseTime(line)
            }
        }

        return NSDate.distantPast().timeIntervalSince1970
    }

    /*func parseTime(line: String) -> NSDate {
        guard line.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 18 else { return fileDate() }

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
    }*/

    func start(entryPoint: Double) {
        stopped = false
        startingPoint = entryPoint

        var queueName = "be.michotte.hstracker.readers.\(info.name)"
        if let filter = info.startsWithFilters.first {
            queueName += ".\(filter.lowercaseString)"
        }
        queue = dispatch_queue_create(queueName, nil)
        _lockQueue = dispatch_queue_create("\(queueName).lock", DISPATCH_QUEUE_CONCURRENT)
        if let queue = queue {
            Log.info?.message("Starting to track \(info.name)")
            // swiftlint:disable line_length
            Log.verbose?.message("\(info.name) has queue \(queueName) starting at \(NSDate(timeIntervalSince1970: startingPoint))")
            // swiftlint:enable line_length
            dispatch_async(queue) {
                self.readFile()
            }
        }
    }

    func readFile() {
        Log.verbose?.message("reading \(path)")
        guard let _ = _lockQueue else {return}

        var fileHandle: NSFileHandle?
        if fileManager.fileExistsAtPath(path) {
            fileHandle = NSFileHandle(forReadingAtPath: path)
            offset = findOffset()
            Log.verbose?.message("file exists \(path), offset for \(startingPoint) is \(offset)")
        }

        while !stopped {
            dispatch_barrier_async(_lockQueue!) {
                if self.collected {
                    self.lines.removeAll()
                    self.collected = false
                }

                // swiftlint:disable line_length
                if fileHandle == .None && self.fileManager.fileExistsAtPath(self.path) {
                    fileHandle = NSFileHandle(forReadingAtPath: self.path)
                    self.offset = self.findOffset()
                    Log.verbose?.message("file exists \(self.path) after reset, offset for \(self.startingPoint) is \(self.offset)")
                }

                if let handle = fileHandle {
                    handle.seekToFileOffset(self.offset)

                    let data = handle.readDataToEndOfFile()
                    if let linesStr = String(data: data, encoding: NSUTF8StringEncoding) {

                        let lines = linesStr.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
                            .filter { !$0.isEmpty && $0.startsWith("D ") }
                        if !lines.isEmpty {
                            for line in lines {
                                let cutted = line.substringFromIndex(line.startIndex.advancedBy(19))

                                if !self.info.hasFilters || self.info.startsWithFilters.any({ cutted.startsWith($0) })
                                    || self.info.containsFilters.any({ cutted.containsString($0) }) {

                                    let logLine = LogLine(namespace: self.info.name, line: line)
                                    if logLine.time >= self.startingPoint {
                                        self.lines.append(logLine)
                                    }
                                    self.offset += UInt64((line + "\n").lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
                                }
                            }
                        }
                    }

                    if !self.fileManager.fileExistsAtPath(self.path) || self.offset > self.fileSize() {
                        fileHandle = nil
                    }
                }
                // swiftlint:enable line_length
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
            let attr: NSDictionary? = try fileManager
                .attributesOfItemAtPath(self.path)

            if let _attr = attr {
                fileSize = _attr.fileSize()
            }
        } catch {
            Log.error?.message("\(error)")
        }
        return fileSize
    }

    func fileDate() -> NSDate {
        do {
            if let attr: NSDictionary? = try fileManager.attributesOfItemAtPath(self.path),
                dict = attr {
                return dict[NSFileModificationDate] as? NSDate ?? NSDate.distantPast()
            }
        } catch {
            return NSDate.distantPast()
        }
    }

    func findOffset() -> UInt64 {
        guard fileManager.fileExistsAtPath(path) else { return 0 }

        var offset: UInt64 = 0
        let fileContent: String
        do {
            fileContent = try String(contentsOfFile: self.path)
        } catch {
            return offset
        }

        // swiftlint:disable line_length
        let lines = fileContent.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        // swiftlint:enable line_length
        for line in lines {
            if LogLine.parseTime(line) < startingPoint {
                let length = line.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
                if length > 0 {
                    offset += UInt64(length)
                }
            }
        }

        return offset
    }

    func stop() {
        Log.info?.message("Stopping tracker \(info.name)")
        stopped = true
    }
}
