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
    private static var inProgress = false
    private static var lastUploadedData: [String: Any] = [:]

    static func upload(collectionData: UploadCollectionData, completion: @escaping(UploadResult) -> Void) {
        guard let data: Data = try? wrap(collectionData) else {
            logger.error("Can not convert collection to data")
            completion(.failed(error: "Can not convert collection to data"))
            return
        }

        HSReplayAPI.getUploadCollectionToken { token in
            logger.verbose("Got token \(token)")
            guard !token.isBlank else {
                logger.error("Failed to obtain collection upload token")
                completion(.failed(error: "Failed to obtain collection upload token"))
                return
            }

            let http = Http(url: token)
            http.upload(method: .put,
                headers: [
                    "Content-Type": "application/json",
                ],
                data: data)

            logger.info("Collection upload done: Success")
        }
    }
}
