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

// swiftlint:disable line_length
final class LogReader {
    var stopped = true
    var offset: UInt64 = 0
    var startingPoint = 0.0
    var fileHandle: NSFileHandle?

    var path: String
    let fileManager = NSFileManager()
    let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone(name: "UTC")
        return formatter
    }()
    private var info: LogReaderInfo
    private var logReaderManager: LogReaderManager?

    private var queue: dispatch_queue_t?

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

        let lines: [String] = fileContent
            .componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
            .filter({ !String.isNullOrEmpty($0) }).reverse()
        for line in lines {
            if choices.any({ line.rangeOfString($0) != nil }) {
                return LogLine.parseTime(line)
            }
        }

        return NSDate.distantPast().timeIntervalSince1970
    }

    func start(logReaderManager: LogReaderManager, entryPoint: Double) {
        stopped = false
        self.logReaderManager = logReaderManager
        startingPoint = entryPoint

        var queueName = "be.michotte.hstracker.readers.\(info.name)"
        if let filter = info.startsWithFilters.first {
            queueName += ".\(filter.lowercaseString)"
        }
        queue = dispatch_queue_create(queueName, nil)
        if let queue = queue {
            Log.info?.message("Starting to track \(info.name)")
            Log.verbose?.message("\(info.name) has queue \(queueName) " +
                "starting at \(NSDate(timeIntervalSince1970: startingPoint))")
            dispatch_async(queue) {
                self.readFile()
            }
        }
    }

    func readFile() {
        Log.verbose?.message("reading \(path)")

        if fileManager.fileExistsAtPath(path) {
            fileHandle = NSFileHandle(forReadingAtPath: path)
            offset = findOffset()
            Log.verbose?.message("file exists \(path), " +
                "offset for \(NSDate(timeIntervalSince1970: startingPoint)) " +
                "is \(offset)")
        }

        while !stopped {
            if fileHandle == .None && fileManager.fileExistsAtPath(path) {
                fileHandle = NSFileHandle(forReadingAtPath: path)
                offset = findOffset()
            }

            if let data = fileHandle?.readDataToEndOfFile() {
                if let linesStr = String(data: data, encoding: NSUTF8StringEncoding) {

                    let lines = linesStr
                        .componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
                        .filter { !$0.isEmpty && $0.startsWith("D ") && $0.length > 20 }

                    if !lines.isEmpty {
                        for line in lines {
                            offset += UInt64((line + "\n").lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
                            let cutted = line.substringFromIndex(line.startIndex.advancedBy(19))

                            if !info.hasFilters || info.startsWithFilters.any({ cutted.startsWith($0) })
                                || info.containsFilters.any({ cutted.containsString($0) }) {

                                let logLine = LogLine(namespace: info.name, line: line)
                                if logLine.time >= startingPoint {
                                    logReaderManager?.processLine(logLine)
                                    //Log.verbose?.message("Appending \(logLine)")
                                }
                            }
                        }
                    }
                }

                if !fileManager.fileExistsAtPath(path) {
                    Log.verbose?.message("setting \(path) handle to nil \(offset)/\(fileSize())")
                    fileHandle = nil
                }
            }

            NSThread.sleepForTimeInterval(0.1)
        }
    }

    func fileSize() -> UInt64 {
        do {
            let attr: NSDictionary? = try fileManager
                .attributesOfItemAtPath(self.path)

            if let _attr = attr {
                return _attr.fileSize()
            }
        } catch {
            Log.error?.message("\(error)")
        }
        return 0
    }

    func findOffset() -> UInt64 {
        guard fileManager.fileExistsAtPath(path) else { return 0 }

        let fileContent: String
        do {
            fileContent = try String(contentsOfFile: self.path)
        } catch {
            return 0
        }

        var offset: UInt64 = 0
        let lines = fileContent
            .componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())

        for line in lines {
            if LogLine.parseTime(line) < startingPoint {
                let length = (line + "\n").lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
                if length > 0 {
                    offset += UInt64(length)
                }
            }
        }

        return offset
    }

    func stop() {
        Log.info?.message("Stopping tracker \(info.name)")
        fileHandle?.closeFile()
        fileHandle = nil

        // try to truncate log file when stopping
        if fileManager.fileExistsAtPath(path)
            && !Hearthstone.instance.isHearthstoneRunning {
            let file = NSFileHandle(forWritingAtPath: path)
            file?.truncateFileAtOffset(UInt64(0))
            file?.closeFile()
            offset = 0
        }
        stopped = true
    }
}
