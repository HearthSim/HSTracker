//
//  LogUploader.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import Wrap
import ZipArchive
import Gzip
import RealmSwift
import RegexUtil

class LogUploader {
    private static var inProgress: [UploaderItem] = []
    
    static func upload(filename: String, completion: @escaping (UploadResult) -> Void) {
        if !SSZipArchive.unzipFile(atPath: filename, toDestination: Paths.tmpReplays.path) {
            completion(.failed(error: "Can not unzip \(filename)"))
            return
        }
        
        let output = Paths.tmpReplays.appendingPathComponent("output_log.txt")
        if !FileManager.default.fileExists(atPath: output.path) {
            completion(.failed(error: "Can not find \(output)"))
            return
        }
        do {
            let content = try String(contentsOf: output)
            let lines = content.components(separatedBy: "\n")
            if lines.isEmpty {
                completion(.failed(error: "Log is empty"))
                return
            }
            
            if lines.first?.hasPrefix("[") ?? true {
                completion(.failed(error: "Output log not supported"))
                return
            }
            if lines.first?.contains("PowerTaskList.") ?? true {
                completion(.failed(error: "PowerTaskList is not supported"))
                return
            }
            if !lines.any({ $0.contains("CREATE_GAME") }) {
                completion(.failed(error: "'CREATE_GAME' not found"))
                return
            }
            
            var date: Date?
            do {
                let attr = try FileManager.default.attributesOfItem(atPath: output.path)
                date = attr[.creationDate] as? Date
            } catch {
                logger.error("\(error)")
            }

            guard date != nil else {
                completion(.failed(error: "Cannot find game start date"))
                return
            }
            if let line = lines.first(where: { $0.contains("CREATE_GAME") }) {
                let gameStart = LogLine(namespace: .power, line: line).time
                var dateComponents = LogReaderManager.calendar
                    .dateComponents(in: LogReaderManager.timeZone,
                                    from: date!)
                dateComponents.hour = gameStart.hour
                dateComponents.minute = gameStart.minute
                dateComponents.second = gameStart.second

                date = LogReaderManager.calendar.date(from: dateComponents)
            }

            let logLines = lines.map({
                LogLine.init(namespace: .power, line: $0)
            })
            
            // find build number
            var buildNumber = 0
            let BuildNumberRegex: RegexPattern = "BuildNumber=(\\d+)"
            for logline in logLines {
                if logline.line.match(BuildNumberRegex) {
                    if let buildnumber = Int(logline.line.matches(BuildNumberRegex)[0].value) {
                        buildNumber = buildnumber
                    }
                }
            }
            
            if buildNumber == 0 {
                // build number was not found, bail
                completion(.failed(error: "Build number was not found"))
                return
            }
            
            self.upload(logLines: logLines, buildNumber: buildNumber, gameStart: date, fromFile: true) { (result) in
                do {
                    try FileManager.default.removeItem(at: output)
                } catch {
                    logger.error("Can not remove tmp files")
                }
                completion(result)
            }
        } catch {
            return completion(.failed(error: "Can not read \(output)"))
        }
    }

    static func upload(logLines: [LogLine], buildNumber: Int, metaData: (metaData: UploadMetaData, statId: String )? = nil,
                       gameStart: Date? = nil, fromFile: Bool = false,
                       completion: @escaping (UploadResult) -> Void) {
        let log = logLines.sorted {
            return $0.time < $1.time
            }.map { $0.line }
        upload(logLines: log, buildNumber: buildNumber, metaData: metaData, gameStart: gameStart,
               fromFile: fromFile, completion: completion)
    }

    static func upload(logLines: [String], buildNumber: Int, metaData: (metaData: UploadMetaData, statId: String )? = nil,
                       gameStart: Date? = nil, fromFile: Bool = false,
                       completion: @escaping (UploadResult) -> Void) {
        guard let token = Settings.hsReplayUploadToken else {
            logger.error("HSReplay upload failed: Authorization token not set yet")
            completion(.failed(error: "Authorization token not set yet"))
            return
        }

        let numCreates = logLines.filter({ $0.contains("CREATE_GAME") }).count
        if numCreates != 1 {
            logger.error("HSReplay upload failed: Log contains none or multiple games (\(numCreates))")
            completion(.failed(error: "Log contains none or multiple games"))
            return
        }
        
        let log = logLines.joined(separator: "\n")
        if logLines.isEmpty || log.trim().isEmpty {
            logger.warning("Log file is empty, skipping")
            completion(.failed(error: "Log file is empty"))
            return
        }
        let item = UploaderItem(hash: log.hash)
        if inProgress.contains(item) {
            inProgress.append(item)
            logger.info("\(item.hash) already in progress. Waiting for it to complete...")
            completion(.failed(error:
                "\(item.hash) already in progress. Waiting for it to complete..."))
            return
        }
        
        inProgress.append(item)

        metaData?.metaData.hearthstoneBuild = buildNumber

        guard let wrappedMetaData: [String: Any] = try? wrap(metaData?.metaData) else {
            logger.warning("Can not encode to json game metadata")
            completion(.failed(error: "Can not encode to json game metadata"))
            return
        }
        logger.info("Uploading \(item.hash)")

        let headers = [
            "X-Api-Key": HSReplayAPI.apiKey,
            "Authorization": "Token \(token)"
        ]

        let statId: String? = metaData?.statId

        let http = Http(url: HSReplay.uploadRequestUrl)
        http.json(method: .post,
                  parameters: wrappedMetaData,
                  headers: headers) { jsonData in

                    guard let json = jsonData as? [String: Any],
                        let putUrl = json["put_url"] as? String,
                        let uploadShortId = json["shortid"] as? String,
                        let replayUrl = json["url"] as? String
                    else {
                            logger.error("JSON Error : \(String(describing: jsonData))")
                            let message = "Can not gzip : \(String(describing: jsonData))"
                            completion(.failed(error: message))
                            return
                    }

                    guard let data = log.data(using: .utf8) else {
                        logger.error("Can not convert log to data")
                        completion(.failed(error: "Can not convert log to data"))
                        return
                    }
                    guard let gzip = try? data.gzipped() else {
                        logger.error("Can not gzip log")
                        completion(.failed(error: "Can not gzip log"))
                        return
                    }
                    
                    logger.info("putURL: \(putUrl), replayUrl: \(replayUrl), shortid: \(uploadShortId)")

                    let http = Http(url: putUrl)
                    http.upload(method: .put,
                                headers: [
                                    "Content-Type": "text/plain",
                                    "Content-Encoding": "gzip"
                        ],
                                data: gzip)

                    logger.info("\(item.hash) upload done: Success")
                    inProgress = inProgress.filter({ $0.hash == item.hash })

                    if metaData?.metaData.gameType != BnetGameType.bgt_battlegrounds.rawValue && metaData?.metaData.gameType != BnetGameType.bgt_battlegrounds_friendly.rawValue {
                            guard let statId = statId,
                                let existing = RealmHelper.getGameStat(with: statId)  else {
                                        logger.error("Can not update statistic")
                                        completion(.failed(error: "Can not update statistic"))
                                        return
                            }
                            RealmHelper.update(stat: existing, hsReplayId: uploadShortId)
                    }
            
                    completion(.successful(replayId: uploadShortId))
        }
    }
}

private struct UploaderItem {
    let hash: Int
}

extension UploaderItem: Equatable {
    static func == (lhs: UploaderItem, rhs: UploaderItem) -> Bool {
        return lhs.hash == rhs.hash
    }
}
