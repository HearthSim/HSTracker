//
//  LogUploader.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 12/08/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation
import CleanroomLogger
import Wrap
import ZipArchive
import Gzip
import RealmSwift

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
            
            var date: Date? = nil
            do {
                let attr = try FileManager.default.attributesOfItem(atPath: output.path)
                date = attr[.creationDate] as? Date
            } catch {
                print("\(error)")
            }

            guard date != nil else {
                completion(.failed(error: "Cannot find game start date"))
                return
            }
            if let line = lines.first({ $0.contains("CREATE_GAME") }) {
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
            
            self.upload(logLines: logLines, gameStart: date, fromFile: true) { (result) in
                do {
                    try FileManager.default.removeItem(at: output)
                } catch {
                    Log.error?.message("Can not remove tmp files")
                }
                completion(result)
            }
        } catch {
            return completion(.failed(error: "Can not read \(output)"))
        }
    }

    static func upload(logLines: [LogLine], statistic: InternalGameStats? = nil,
                       gameStart: Date? = nil, fromFile: Bool = false,
                       completion: @escaping (UploadResult) -> Void) {
        let log = logLines.sorted {
            return $0.time < $1.time
            }.map { $0.line }
        upload(logLines: log, statistic: statistic, gameStart: gameStart,
               fromFile: fromFile, completion: completion)
    }

    static func upload(logLines: [String], statistic: InternalGameStats? = nil,
                       gameStart: Date? = nil, fromFile: Bool = false,
                       completion: @escaping (UploadResult) -> Void) {
        guard let token = Settings.hsReplayUploadToken else {
            Log.error?.message("HSReplay upload failed: Authorization token not set yet")
            completion(.failed(error: "Authorization token not set yet"))
            return
        }

        let numCreates = logLines.filter({ $0.contains("CREATE_GAME") }).count
        if numCreates != 1 {
            Log.error?.message("HSReplay upload failed: Log contains none or multiple games (\(numCreates))")
            completion(.failed(error: "Log contains none or multiple games"))
            return
        }
        
        let log = logLines.joined(separator: "\n")
        if logLines.isEmpty || log.trim().isEmpty {
            Log.warning?.message("Log file is empty, skipping")
            completion(.failed(error: "Log file is empty"))
            return
        }
        let item = UploaderItem(hash: log.hash)
        if inProgress.contains(item) {
            inProgress.append(item)
            Log.info?.message("\(item.hash) already in progress. Waiting for it to complete...")
            completion(.failed(error:
                "\(item.hash) already in progress. Waiting for it to complete..."))
            return
        }
        
        inProgress.append(item)

        let uploadMetaData = UploadMetaData.generate(game: statistic)
        if let date = uploadMetaData.dateStart, fromFile {
            uploadMetaData.hearthstoneBuild = BuildDates.get(byDate: date)?.build
        } else if let build = BuildDates.getByProductDb() {
            uploadMetaData.hearthstoneBuild = build.build
        } else {
            uploadMetaData.hearthstoneBuild = BuildDates.get(byDate: Date())?.build
        }

        guard let metaData: [String : Any] = try? wrap(uploadMetaData) else {
            Log.warning?.message("Can not encode to json game metadata")
            completion(.failed(error: "Can not encode to json game metadata"))
            return
        }
        Log.info?.message("Uploading \(item.hash) -> \(metaData)")

        let headers = [
            "X-Api-Key": HSReplayAPI.apiKey,
            "Authorization": "Token \(token)"
        ]

        var statId: String?
        if let stat = statistic {
            statId = stat.statId
        }

        let http = Http(url: HSReplay.uploadRequestUrl)
        http.json(method: .post,
                  parameters: metaData,
                  headers: headers) { jsonData in

                    guard let json = jsonData as? [String: Any],
                        let putUrl = json["put_url"] as? String,
                        let uploadShortId = json["shortid"] as? String else {
                            Log.error?.message("JSON Error : \(String(describing: jsonData))")
                            let message = "Can not gzip : \(String(describing: jsonData))"
                            completion(.failed(error: message))
                            return
                    }

                    guard let data = log.data(using: .utf8) else {
                        Log.error?.message("Can not convert log to data")
                        completion(.failed(error: "Can not convert log to data"))
                        return
                    }
                    guard let gzip = try? data.gzipped() else {
                        Log.error?.message("Can not gzip log")
                        completion(.failed(error: "Can not gzip log"))
                        return
                    }

                    let http = Http(url: putUrl)
                    http.upload(method: .put,
                                headers: [
                                    "Content-Type": "text/plain",
                                    "Content-Encoding": "gzip"
                        ],
                                data: gzip)

                    guard let statId = statId,
                        let existing = RealmHelper.getGameStat(with: statId)  else {
                                Log.error?.message("Can not update statistic")
                                completion(.failed(error: "Can not update statistic"))
                                return
                    }
                    RealmHelper.update(stat: existing, hsReplayId: uploadShortId)

                    Log.info?.message("\(item.hash) upload done: Success")
                    inProgress = inProgress.filter({ $0.hash == item.hash })

                    completion(.successful(replayId: uploadShortId))
        }
    }
}

fileprivate struct UploaderItem {
    let hash: Int
}

extension UploaderItem: Equatable {
    static func == (lhs: UploaderItem, rhs: UploaderItem) -> Bool {
        return lhs.hash == rhs.hash
    }
}
