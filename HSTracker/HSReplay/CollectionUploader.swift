//
//  CollectionUploader.swift
//  HSTracker
//
//  Created by Richard Lee on 2018/8/5.
//  Copyright © 2018 Benjamin Michotte. All rights reserved.
//

import Foundation
import Wrap

class CollectionUploader {
    static var inProgress = false
    private static var lastUploadedData: Data?

    static func upload(collectionData: UploadCollectionData, completion: @escaping(CollectionUploadResult) -> Void) {
        guard !inProgress else {
            logger.error("Another collection upload in progress")
            completion(.failed(error: "Another collection upload in progress"))
            return
        }

        inProgress = true

        guard let data: Data = try? wrap(collectionData) else {
            logger.error("Can not convert collection to data")
            completion(.failed(error: "Can not convert collection to data"))
            inProgress = false
            return
        }

        guard lastUploadedData != data else {
            logger.error("Skip uploading as data is identical to last uploaded")
            inProgress = false
            return
        }

        HSReplayAPI.claimBattleTag {
            HSReplayAPI.getUploadCollectionToken { token in
                logger.verbose("Got upload collection token \(token)")
                guard !token.isBlank else {
                    logger.error("Failed to obtain collection upload token")
                    completion(.failed(error: "Failed to obtain collection upload token"))
                    inProgress = false
                    return
                }

                let http = Http(url: token)
                http.upload(method: .put,
                    headers: [
                        "Content-Type": "application/json",
                    ],
                    data: data)

                inProgress = false
                lastUploadedData = data

                logger.info("Collection upload done: Success")
                completion(.successful)
            }
        }
    }
}
