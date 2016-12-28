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

            guard let _ = date else {
                completion(.failed(error: "Cannot find game start date"))
                return
            }
            if let line = lines.first({ $0.contains("CREATE_GAME") }) {
                let (gameStart, _) = LogLine.parseTime(line: line)
                date = Date.NSDateFromYear(year: date!.year,
                                             month: date!.month,
                                             day: date!.day,
                                             hour: gameStart.hour,
                                             minute: gameStart.minute,
                                             second: gameStart.second)
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

    static func upload(logLines: [LogLine], game: Game? = nil, statistic: Statistic? = nil,
                       gameStart: Date? = nil, fromFile: Bool = false,
                       completion: @escaping (UploadResult) -> Void) {
        let log = logLines.sorted {
            if $0.time == $1.time {
                return $0.nanoseconds < $1.nanoseconds
            }
            return $0.time < $1.time
            }.map { $0.line }
        upload(logLines: log, game: game, statistic: statistic, gameStart: gameStart,
               fromFile: fromFile, completion: completion)
    }

    static func upload(logLines: [String], game: Game? = nil, statistic: Statistic? = nil,
                       gameStart: Date? = nil, fromFile: Bool = false,
                       completion: @escaping (UploadResult) -> Void) {
        guard let token = Settings.instance.hsReplayUploadToken else {
            Log.error?.message("Authorization token not set yet")
            completion(.failed(error: "Authorization token not set yet"))
            return
        }

        if logLines.filter({ $0.contains("CREATE_GAME") }).count != 1 {
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

        do {
            let uploadMetaData = UploadMetaData(log: logLines,
                                                game: game,
                                                statistic: statistic,
                                                gameStart: gameStart)
            if let date = uploadMetaData.dateStart, fromFile {
                uploadMetaData.hearthstoneBuild = BuildDates.get(byDate: date)?.build
            } else if let build = BuildDates.getByProductDb() {
                uploadMetaData.hearthstoneBuild = build.build
            } else {
                uploadMetaData.hearthstoneBuild = BuildDates.get(byDate: Date())?.build
            }
            let metaData: [String : Any] = try wrap(uploadMetaData)
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
                      headers: headers) { json in
                        if let json = json as? [String: Any],
                            let putUrl = json["put_url"] as? String,
                            let uploadShortId = json["shortid"] as? String {

                            if let data = log.data(using: .utf8) {
                                do {
                                    let gzip = try data.gzipped()

                                    let http = Http(url: putUrl)
                                    http.upload(method: .put,
                                                headers: [
                                                    "Content-Type": "text/plain",
                                                    "Content-Encoding": "gzip"
                                        ],
                                                data: gzip)
                                } catch {
                                    Log.error?.message("can not gzip")
                                }
                            }

                            if let statId = statId {
                                do {
                                    let realm = try Realm()
                                    if let existing = realm.objects(Statistic.self)
                                        .filter("statId = '\(statId)'").first {
                                        try realm.write {
                                            existing.hsReplayId = uploadShortId
                                        }
                                    }
                                } catch {
                                    Log.error?.message("Can not update statistic : \(error)")
                                }
                            }

                            let result = UploadResult.successful(replayId: uploadShortId)

                            Log.info?.message("\(item.hash) upload done: Success")
                            inProgress = inProgress.filter({ $0.hash == item.hash })

                            completion(result)
                            return
                        }
            }
        } catch {
            Log.error?.message("\(error)")
            completion(.failed(error: "\(error)"))
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
